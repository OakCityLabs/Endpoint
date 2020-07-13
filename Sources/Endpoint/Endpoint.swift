//
//  Endpoint.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

open class Endpoint<Payload> {
    public let serverUrl: URL?
    public let pathPrefix: String
    public let pathSuffix: String?
    public let objId: String?
    public let method: EndpointHttpMethod
    public let queryParams: [String: String]
    public let formParams: [String: String]
    public let jsonParams: [String: Any]
    public let mimeTypes: [String]
    public let contentType: String?
    public let statusCodes: [Int]
    public let username: String?
    public let password: String?
    public let body: Data?
    public let dateFormatter: DateFormatter
    
    /// Encode the `jsonParams` attribute to a JSON `Data` block for use as the HTTP body of a request
    open var jsonBody: Data? {
        guard !jsonParams.isEmpty else {
            return nil
        }
        guard method == .post || method == .patch else {
            return nil
        }
        
        let options: JSONSerialization.WritingOptions = [.sortedKeys]
        
        return try? JSONSerialization.data(withJSONObject: jsonParams, options: options)
    }
    
    /// Encode the `formParams` attribute to a url encoded form data block for use as the HTTP body of a request
    open var formBody: Data? {
        guard !formParams.isEmpty else {
            return nil
        }
        guard method == .post || method == .patch else {
            return nil
        }
        
        let parameterArray = formParams.map { (arg) -> String in
            let (key, value) = arg
            return "\(key)=\(value.percentEscaped)"
        }
        let body = parameterArray.joined(separator: "&").data(using: .utf8)
        return body
    }
    
    // Determin if the Payload type supports paging
    open var paging: Bool {
        return Payload.self is EndpointPageable.Type
    }
    
    /// Initialize an Endpoint instance
    ///
    /// Parameter descriptions are in reference to this example URL
    ///
    /// `http://foo.com/api/v1.0/users/277/followers?expand=1`
    ///
    /// - Parameters:
    ///   - serverUrl: Shared prefix for the URLs - `http://foo.com/api/v1.0`
    ///   - pathPrefix: Path portion after `serverUrl` and before the object ID - `users`
    ///   - method: HTTP method, one of .get, .post, .patch, .delete
    ///   - objId:  Identifier for the object - `277`
    ///   - pathSuffix: Path portion after the object ID - `followers`
    ///   - queryParams: Dictionary of query parameters appended to the URL - `expand=1`
    ///   - formParams: Form parameter dictionary sent in the body of the request (application/x-www-form-urlencoded)
    ///   - jsonParams: Parameters dictionary sent in the body of the request encoded as JSON (application/json)
    ///   - mimeTypes: Array of valid mime types for the data returned from the server
    ///   - contentType: Content type for the HTTP request sent to the server
    ///   - statusCodes: Array of valid status codes in the HTTP response from the server
    ///   - username: Username for Basic HTTP Authorization header (`Authorization: Basic XXXXXXXXXXXXXXXX`)
    ///   - password: Password for Basic HTTP Authorization header (`Authorization: Basic XXXXXXXXXXXXXXXX`)
    ///   - body: Data to be used verbatim as the HTTP body
    ///   - dateFormatter: DateFormatter object to be used during parsing to decode Date/Time objects
    public init(serverUrl: URL? = nil,
                pathPrefix: String,
                method: EndpointHttpMethod = .get,
                objId: String? = nil,
                pathSuffix: String? = nil,
                queryParams: [String: String] = [:],
                formParams: [String: String] = [:],
                jsonParams: [String: Any] = [:],
                mimeTypes: [String] = ["application/json"],
                contentType: String? = nil,
                statusCodes: [Int] = Array(200..<300),
                username: String? = nil,
                password: String? = nil,
                body: Data? = nil,
                dateFormatter: DateFormatter? = nil) {
        self.serverUrl = serverUrl
        self.pathPrefix = pathPrefix
        self.objId = objId
        self.pathSuffix = pathSuffix
        self.method = method
        self.queryParams = queryParams
        self.formParams = formParams
        self.jsonParams = jsonParams
        self.mimeTypes = mimeTypes
        self.contentType = contentType
        self.statusCodes = statusCodes
        self.username = username
        self.password = password
        self.body = body
        self.dateFormatter = dateFormatter ?? .iso8601Full
    }
    
    /// The `parse` method of the `Endpoint` takes the data retrieved from the server (often JSON encoded)
    /// and returns an instance of the `Payload`.
    /// - Parameters:
    ///   - data: Raw `Data` object, usually the network response from the server
    ///   - page: For paginated data, the page retrieved.  This might be used by `parse` implementations to determine
    ///     if the results should overwrite an existing result or appended to it.
    open func parse(data: Data, page: Int = 1) throws -> Payload {
        throw EndpointError.noParser
    }
    
    /// Generate the URL portion of the URLRequest without the query parameters
    open func url(defaultServerUrl: URL? = nil) -> URL? {
        guard let serverUrl = (serverUrl ?? defaultServerUrl) else {
            return nil
        }
        var url = serverUrl
        if !pathPrefix.isEmpty {
            url.appendPathComponent(pathPrefix)
        }
        
        if let objId = objId {
            url.appendPathComponent("\(objId)")
        }
        if let pathSuffix = pathSuffix {
            url.appendPathComponent(pathSuffix)
        }
        
        return url
    }
    
    /// Assemble the query parameters dictionary for the URLRequest by combining `queryParams` with paging attributes
    open func requestQueryParams(page: Int = 1) -> [String: String]? {
        let pageParams: [String: String]
        if let pageableClass = Payload.self as? EndpointPageable.Type {
            pageParams = [
                pageableClass.perPageLabel: "\(pageableClass.perPage)",
                pageableClass.pageLabel: "\(page + pageableClass.pageOffset)"
            ]
        } else {
            pageParams = [:]
        }

        let qParams = pageParams.merging(queryParams) { (_, new) in new }
        
        // Don't return an empty dict, return nil instead
        if qParams.isEmpty {
            return nil
        } else {
            return qParams
        }
    }
    
    /// Encode the query parameter dictionary to a URLQueryItem array by percent escaping the strings
    open func requestEncodedQueryParams(forQueryParams qParams: [String: String]?) -> [URLQueryItem]? {
        guard let qParams = qParams else {
            return nil
        }
        let percentEncodedQueryItems: [URLQueryItem] = qParams.map { arg in
            let (key, value) = arg
            return URLQueryItem(name: key, value: "\(value)".percentEscaped)
        }

        return percentEncodedQueryItems
    }
    
    /// Build an auth header for the URLRequest.  The base class does this by using the username and password, if
    /// defined to create an HTTP Basic Authorization value.
    open var authorizationHeader: String? {
        // Basic auth
        if let username = username,
            let loginData = "\(username):\(password ?? "")".data(using: .utf8) {
            let base64LoginData = loginData.base64EncodedString()
            return "Basic \(base64LoginData)"
        }
        return nil
    }
    
    /// Return a URLRequest associated with this endpoint configuration
    /// - Parameters:
    ///   - page: For paginated endpoints, which page to retrieve. This is a 1 based index.
    ///   - extraHeaders: Dictionary of extra headers to be added to the request
    ///   - defaultServerUrl: A fallback serverUrl to use if the endpoint's serverUrl is `nil`
    open func urlRequest(page: Int = 1,
                         extraHeaders: [String: String] = [:],
                         defaultServerUrl: URL? = nil) -> URLRequest? {
        
        guard let url = url(defaultServerUrl: defaultServerUrl),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
        }
        
        let qParams = requestQueryParams(page: page)
        components.percentEncodedQueryItems = requestEncodedQueryParams(forQueryParams: qParams)
        
        guard let cUrl = components.url else {
            assertionFailure("Failed to get URL from components.")
            return nil
        }
        
        var headers = extraHeaders
        headers ["Accept-Encoding"] = "gzip"
        
        if (method == .post || method == .patch) && contentType == nil {
            headers["Content-Type"] = formBody != nil ? "application/x-www-form-urlencoded" : "application/json"
        }
        if let contentType = contentType {
            headers["Content-Type"] = contentType
        }
        
        if let authorizationHeader = authorizationHeader {
            headers["Authorization"] = authorizationHeader
        }
        
        var req = URLRequest(url: cUrl)
        req.httpMethod = method.rawValue
        req.allHTTPHeaderFields = headers
        
        if let body = body {
            req.httpBody = body
        } else if let formBody = formBody {
            req.httpBody = formBody
        } else {
            req.httpBody = jsonBody
        }
        
        return req
    }
    
    // This is a hack to provide a hook for comparing subclasses since the compiler
    // doesn't seem to like overriding === in a concrete subclass of a generic
    open func compareEquality(rhs: Endpoint<Payload>) -> Bool {
        return true
    }
}

extension Endpoint: Equatable {
    public static func ==<Payload>(lhs: Endpoint<Payload>, rhs: Endpoint<Payload>) -> Bool {
        return (lhs.serverUrl == rhs.serverUrl)
            && (lhs.pathPrefix == rhs.pathPrefix)
            && (lhs.pathSuffix == rhs.pathSuffix)
            && (lhs.objId == rhs.objId)
            && (lhs.method == rhs.method)
            && (lhs.queryParams == rhs.queryParams)
            && (lhs.formParams == rhs.formParams)
            && (lhs.jsonBody == rhs.jsonBody)
            && (lhs.mimeTypes == rhs.mimeTypes)
            && (lhs.contentType == rhs.contentType)
            && (lhs.statusCodes == rhs.statusCodes)
            && (lhs.username == rhs.username)
            && (lhs.password == rhs.password)
            && (lhs.body == rhs.body)
            && (lhs.dateFormatter == rhs.dateFormatter)
            && lhs.compareEquality(rhs: rhs)
    }
}
