# Endpoint

Endpoint objects describe a network (REST) endpoint and can parse its data.

## TL;DR

An Endpoint object describes a network API endpoint.  
It contains all the information needed to request data from an endpoint and can parse the data returned by the API server.  
Organizing endpoints this way makes the code more testable and more organized.
An EndpointController manages downloading the data for and Endpoint and handling errors that may occur.


## Table of Contents

- [Motivation](#motivation)
- [Usage](#usage)
  - [Endpoint Base Class](#endpoint-base-class)
  - [Key Mapping](#key-mapping)
  - [Ignored Attributes](#ignored-attributes)
  - [Raw JSON Substrings](#raw-json-substrings)
  - [REST Envelopes](#rest-envelopes)
  - [Example](#example)
- [SwiftPM](#swiftpm)
- [Changelog](#changelog)
- [License](#license)
- [About](#about)

## Motivation

We built the Endpoint library after watching the "Tiny Networking Library" episodes of the wonderful video series [SwiftTalk](https://talk.objc.io) from the folks at [objc.io](https://www.objc.io).

The main goal of the library is to provide an abstraction to represent a remote API endpoint.  
The Endpoint object contains everything you need to know to make a request to an API endpoint and how to parse the results.  

Separating out the endpoint definition and parsing functionality makes unit testing much easier.  You can define paramters for an endpoint and check the generated URL agains known values.  Likewise, you can use known test data to excercise the parsing routine and validate the output.  Unit testing network code can be tricky, but by moving the parsing code into a separate object, we remove the networking aspect and drastically simplify the unit testing.

Breaking endpoints out into separate objects is also great for the organization of our projects.  The tendency is to put endpoint handling into a massive and ever-increasing network controller, where you add a method for each new endpoint.  Even with a simple project, you quickly wind up with a giant monolithic controller that hard to read and maintain.  Moving to the endpoint model, everything becomes simple.  The network controller only has to be concerned with retreiving data from the network and handling communication (HTTP) errors.  The endpoint objects can be organized naturally, making factory methods in an extenion to their associated object type, for example.

We also include an EndpointController object that handles making network requests with Endpoints.  EndpointController uses URLSession to retrieve Endpoint data and perform error checking.

## Usage

### Endpoint Base Class

The `Endpoint` class wraps all the data to define an network API endpoint, usually a REST endpoint.  It is generic over a `Payload`, the type of object returned by the endpoint.  For example, if you have an endpoint that retrieves information about a restaurant, the `Payload` type would be a `Restaurant`, eg `Resource<Restaurant>`.  

The base `Endpoint` class is really meant to be an abstract class.  It defines a common interface and some default behaviour, but it is intended to be subclassed for a particular type of `PayLoad` object.  Two subclasses are included in the library -- [CodableEndpoint](#codableendpoint) and [FileDownloadEndpoint](#filedownloadendpoint).

#### Initialization

To create an Endpoint, you need at least the `serverUrl` and the `pathPrefix`.  The `serverUrl` is the root URL for the service.  This is usually a prefix shared among all your REST endpoints.  The `pathPrefix` is the next part of the URL's path.  If we have a URL like

`http://foo.com/api/v1.0/bar`

Then we can create an Endpoint to represent the URL.

```swift
    let endpoint = Endpoint<Bar>(serverUrl: URL(string: "http://foo.com/api/v1.0")!,
                                 pathPrefix: "bar")
```

Like many REST services, when we build servers, they use a particular pattern for accessing objects.

`http://foo.com/<base_path>/<object_type>/<object_id>/<detail_path>?<query_params>

If you want all the followers for user 867 the URL would be

`http://foo.com/api/v1.0/users/867/followers?expand=1

The Endpoint initializer is set up to work with this sort of template.  The mapping here is:

  * `serverUrl` - `http://foo.com/api/v1.0`
  * `pathPrefix` - `users`
  * `objId` - `867`
  * `pathSuffix` - `followers`
  * `queryParams - `["expand": "1"]`

So in code:

```swift
    let endpoint = Endpoint<Bar>(serverUrl: URL(string: "http://foo.com/api/v1.0")!,
                                 pathPrefix: "users",
                                 objId: "867",
                                 pathSuffix: "followers",
                                 queryParams: ["expand": "1"])
```

If your server doesn't follow this path template, you can always just use the base URL as `serverUrl` and the rest of the path as `pathPrefix`.

#### EndpointHttpMethod

The default HTTP method when creating an endpoing is `GET`, but the `method` paramter of `init` allows you specify user the `EndpointHttpMethod` enumerations, choosing from `.get`, `.post`, `.patch` or `.delete`.

#### HTTP Body Data

Endpoint supports several mehtods for building the body of an HTTP request, including JSON, form parameters or custom data.  Any endpoint that includes data for the body of the HTTP request should be using the `.post` HTTP method.

To create an JSON request, specifiy the dictionary of values when creating the Endpoint with the `jsonParams` parameter to the `init` method.  This dicationary will be JSON encoded to a data block used as the body of URLRequest.

Supplying the `formData` paramter will create a body for the URLRequest with the supplied dictionary url-encoded as form data.

If neither of those is appropriate, like with multi-part form data, you can supply your own data with the `body` attribute of `init`.

#### DateFormatter

The `dateFormatter` parameter holds a `DateFormatter` object.  The base class doesn't do anything with this, but it's useful for subclasses that needs a `DateFormatter` for parsing data, such as the [`CodableEndpoint`](#codableendpoint).

#### URL Request

This method returns a URLRequest generated from the attributes of the Endpoint object.  The request is suitable for passing directly to URLSession.  For pageable endpoints, you can specify the page requested (with '1' based indexin).  You can also pass any extra header information to be included in the request.

```swift
open func urlRequest(page: Int = 1, extraHeaders: [String: String] = [:]) -> URLRequest?
```

#### Paging

Endpoints that return lots of data are often paged.  An `Endpoint` supports paging if the `Payload` class conforms to the `EndpointPageable` protocol.  There is a default implementation of the protocol, so a class can just declare conformance to enable pageing.

```swift
    extension MyPayloadClass: EndpoingPageable {}
```

This is the default implementation that provides the names of paramters sent to the server for paging.  

```swift
public extension EndpointPageable {
    static var perPage: Int {
        return 30
    }
    
    static var perPageLabel: String {
        return "per_page"
    }
    
    static var pageLabel: String {
        return "page"
    }
    
    static var pageOffset: Int {
        return 0
    }
}
```

The `page` and `perPageLabel` are the names of the query parameters sent to the server indicating the page requested and the number of items per page, respectively.
The `perPage` attribute is the numerical value sent with the `perPageLabel` to specify the number of items per page of data.
Finally `pageOffset` is a modifier on the page number before it's sent to the server.  The `Endpoint` class uses 1-based indexing for the pages.  If your server uses 0-based indexing, you can set `pageOffset` to -1 to make it work. 

### EndpointController

The Endpoint package contains an EndpointController class that handles the loading of data from the Endpoints.  An app usually only needs one EndpointController instance.  This controller can be used over and over to load data for various Endpoints, so the controller is a long lived object.  Endpoints, on the other hand, are typically created, loaded and then released.

The EndpointController is built on URLSession and has two main functions, sending data to the server and receiving data from the server.  The controller uses an Endpoint to create a URLRequest and makes the network request to the server.  When the data is returned, the controller parses the data with the Endpoint's `parse` method or handles any error that occured in the exchange.

Unless explicitly flagged otherwise with the `synchronous` paramter, the controller's `load()` method is asynchronous.  The `load()` call itself will return once the network request has been queued.  The completion block will be called on the main thread once the request completes.  The completion block is called with a `Result` object that has an associated `Payload` object if successful or an `Error` if there's a failure.

```swift
 endpointController.load(endpoint) { (result) in
    switch result {
    case .success(let payload):
        print("Success!  Received \(payload)")
    case .failure(let error):
        print("Failure! Error: \(error)")
    }
}
```

#### Initialization

The tricky thing about the EndpointController is that it needs to interperet errors from the server.  REST servers often return their errors in JSON format, but it seems every server uses a different set of keys for the error response JSON.  In order for you, the consumer of the EndpointController class, to define the format of the error messages, the controller class is generic over an EndpointServerError protocol.  

```swift
public protocol EndpointServerError: Codable, Equatable {
    var error: String? { get }      // Error name -- AuthorizationFailed
    var reason: String? { get }     // Reson for error -- Username not found
    var detail: String? { get }     // Further details -- http://www.server.com/error/username.html
}
```

The protocol is relatively simple.  A conforming object needs to be `Codable`, `Equatable` and have a few getters in place.  All three getters can return `nil`, which is totally valid, but that means the errors passed back from the EndpointController won't carry any useful information.

The package includes an example error struct called `EndpointDefaultServerError`.

```swift
public struct EndpointDefaultServerError: EndpointServerError {
    public let error: String?
    public let reason: String?
    public let detail: String?
    
    public init(error: String?, reason: String?, detail: String?) {
        self.error = error
        self.reason = reason
        self.detail = detail
    }

    public init(reason: String?) {
        self.reason = reason
        error = nil
        detail = nil
    }
}
```

You can instantiate an EndpointController with this error struct like this:

```swift
let endpointController = EndpointController<EndpointDefaultServerError>() 

```

#### Notifications



### CodableEndpoint

`CodableEndpoint` is an `Endpoint` subclass where `Payload` must conform to `Codable`.  The `parse()` method of `CodableEndpoint` uses a `JSONDecoder` to convert the raw data into a `Payload` object.

Here's an example using a `CodableEndpoint` to retrieve an OAuth token.

```swift

struct Token: Codable {    
    let type: String
    let duration: Int
    let value: String
}

let formParms = [
    "grant_type": "client_credentials",
    "client_id": clientId,
    "client_secret": clientSecret
]
let tokenEndpoint = CodableEndpoint<Token>(serverUrl: URL(string: "http://www.foo.com/")!,
                                           pathPrefix: "oauth2/token",
                                           method: .post,
                                           formParams: formParms)

let endpointController = EndpointController<EndpointDefaultServerError>() 

endpointController.load(tokenEndpoint) { (result) in
    switch result {
    case .success(let token):
        print("Success! Received token: \(token)")
    case .failure(let error):
        print("Failure! Error: \(error)")
    }
}
```

### FileDownloadEndpoint

`FileDownloadEndpoint` is an `Endpoint` subclass that abuses the idea a little bit.  Instead of the `parse()` method converting data to an object, it writes the data to a local file and returns the URL to that file.  Initialization is just like the base Endpoint class, with the addition of a `destination` parameter that indicates where the data should be written to.  The `parse()` method will attempt to create any parent directories in the URL that don't exist.  After the `parse()` method is comlete and the file is written to local disk, the `destination` URL is returned through the completation block.  Because parsing returns the `Payload` which is a `URL`, the `FileDownloadEndpoint` is subclassed from `Endpoint<URL>`.

Here's an example using a `FileDownloadEndpoint` to download a file.  The CSV file at URL `http://www.foo.com/data/foo.csv` is downloaded to `/tmp/foo.csv`.

```swift
let destinationURL = URL(fileURLWithPath: "/tmp/foo.csv")
let csvEndpoint = CodableEndpoint<Token>(destination: destinationURL,
                                           serverUrl: URL(string: "http://www.foo.com/")!,
                                           pathPrefix: "data/foo.csv")

let endpointController = EndpointController<EndpointDefaultServerError>() 

endpointController.load(csvEndpoint) { (result) in
    switch result {
    case .success(let url):
        print("Success! File written to: \(url)")
    case .failure(let error):
        print("Failure! Error: \(error)")
    }
}
```

## Logging



## SwiftPM

Endpoint is available via the Swift Package Manager.  You can include Endpoint in your project by adding this line to your `Package.swift` `dependencies` section:

```swift
    .package(url: "https://github.com/OakCityLabs/Endpoint.git", from: "1.0.5"),

```

Be sure to add it to your `targets` list as well:

```swift
    .target(name: "MyApp", dependencies: ["Endpoint"]),

```

## Changelog

See the [changelog.](CHANGELOG.md)

## License

[MIT licensed.](LICENSE.md)

## About

Endpoint is a product of [Oak City Labs](https://oakcity.io).
