//
//  EndpointTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

// Non-paging payload
private struct DummyPayload {
    let name: String
}
private typealias DummyEndpoint = Endpoint<DummyPayload>

// Paging payload with default attrs
private struct DummyPagingPayload {
    let name: String
}
private typealias DummyPagingEndpoint = Endpoint<DummyPagingPayload>
extension DummyPagingPayload: EndpointPageable {}

// Paging payload with customized pageable attrs
private struct OtherPagingPayload {
    let name: String
}
private typealias OtherPagingEndpoint = Endpoint<OtherPagingPayload>
extension OtherPagingPayload: EndpointPageable {
    static var perPage: Int {
        return 5309
    }
    static var perPageLabel: String {
        return "how_many"
    }
    static var pageLabel: String {
        return "sheet"
    }
}


final class EndpointTests: XCTestCase {
    func testEqualitySimple() {
        
        let urlA = URL(string: "http://oakcity.io/A/api")!
        let urlB = URL(string: "http://oakcity.io/B/api")!
        
        let endpointA = DummyEndpoint(serverUrl: urlA, pathPrefix: "hello")
        let endpointA2 = DummyEndpoint(serverUrl: urlA, pathPrefix: "hello")
        let endpointB = DummyEndpoint(serverUrl: urlB, pathPrefix: "hello")

        XCTAssertEqual(endpointA, endpointA2)
        XCTAssertNotEqual(endpointA, endpointB)
    }

    func testEquality() {
        
        let urlA = URL(string: "http://oakcity.io/A")!
        let prefix = "api/v1"
        let objId = "837"
        let suffix = "followers"
        let qParams = ["level": "7", "rank": "full"]
        let jsonParams: [String: Any] = ["bob": "bob", "larry": true, "daryl": 47]
        let mimeTypes = ["text/text"]
        let contentType = "json"
        let statusCodes = Array(189...197)
        let username = "spock"
        let password = "hotgreenblooded"
        let dateFormatter: DateFormatter = {
            let dFormatter = DateFormatter()
            dFormatter.timeStyle = .long
            dFormatter.dateStyle = .none
            return dFormatter
        }()

        let endpointA = DummyEndpoint(serverUrl: urlA,
                                      pathPrefix: prefix,
                                      method: .patch,
                                      objId: objId,
                                      pathSuffix: suffix,
                                      queryParams: qParams,
                                      jsonParams: jsonParams,
                                      mimeTypes: mimeTypes,
                                      contentType: contentType,
                                      statusCodes: statusCodes,
                                      username: username,
                                      password: password,
                                      dateFormatter: dateFormatter)
        let endpointA2 = DummyEndpoint(serverUrl: urlA,
                                       pathPrefix: prefix,
                                       method: .patch,
                                       objId: objId,
                                       pathSuffix: suffix,
                                       queryParams: qParams,
                                       jsonParams: jsonParams,
                                       mimeTypes: mimeTypes,
                                       contentType: contentType,
                                       statusCodes: statusCodes,
                                       username: username,
                                       password: password,
                                       dateFormatter: dateFormatter)
        
        let otherSuffix = "favorites"
        let endpointB = DummyEndpoint(serverUrl: urlA,
                                      pathPrefix: prefix,
                                      method: .patch,
                                      objId: objId,
                                      pathSuffix: otherSuffix,
                                      queryParams: qParams,
                                      jsonParams: jsonParams,
                                      mimeTypes: mimeTypes,
                                      contentType: contentType,
                                      statusCodes: statusCodes,
                                      username: username,
                                      password: password,
                                      dateFormatter: dateFormatter)
        
        XCTAssertEqual(endpointA, endpointA2)
        XCTAssertNotEqual(endpointA, endpointB)
    }
    
    func testDefaults() {
        let endpoint = DummyEndpoint(serverUrl: URL(string: "http://oakcity.io")!, pathPrefix: "")
        
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNil(endpoint.objId)
        XCTAssertNil(endpoint.pathSuffix)
        XCTAssertTrue(endpoint.queryParams.isEmpty)
        XCTAssertTrue(endpoint.formParams.isEmpty)
        XCTAssertTrue(endpoint.jsonParams.isEmpty)
        XCTAssertEqual(endpoint.mimeTypes, ["application/json"])
        XCTAssertNil(endpoint.contentType)
        XCTAssertEqual(endpoint.statusCodes, Array(200..<300))
        XCTAssertNil(endpoint.username)
        XCTAssertNil(endpoint.password)
        XCTAssertNil(endpoint.body)
        XCTAssertEqual(endpoint.dateFormatter, DateFormatter.iso8601Full)
    }
    
    func testPathAttributes() {
        let url = URL(string: "http://oakcity.io")!
        let prefix = "api/v1.0"
        let objId = "4322"
        let suffix = "followers"
        
        let expectedUrl = URL(string: "\(url)/\(prefix)/\(objId)/\(suffix)")
        
        let endpoint = DummyEndpoint(serverUrl: url, pathPrefix: prefix, objId: objId, pathSuffix: suffix)
        let req = endpoint.urlRequest()
        
        XCTAssertEqual(endpoint.url?.absoluteString, expectedUrl?.absoluteString)
        XCTAssertEqual(req?.url?.absoluteString, expectedUrl?.absoluteString)
    }

    func testQueryParamsAttributes() {
        let qParams = [
            "foo": "bar",
            "baz": "1"
        ]
        
        do {
            let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                         pathPrefix: "",
                                         queryParams: qParams)

            let qParamSubSeq = (endpoint.urlRequest()?.url?.absoluteString.split(separator: "?").last)!
            let qParamString = String(qParamSubSeq)
            XCTAssertNotNil(qParamString)
            XCTAssertEqual(qParamString.count, "foo=bar&baz=1".count)
            XCTAssertTrue(qParamString.contains("foo=bar"))
            XCTAssertTrue(qParamString.contains("baz=1"))
        }
        
        do {
            let endpoint = DummyPagingEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                               pathPrefix: "",
                                               queryParams: qParams)

            let qParamSubSeq = (endpoint.urlRequest(page: 2)?.url?.absoluteString.split(separator: "?").last)!
            let qParamString = String(qParamSubSeq)
            XCTAssertNotNil(qParamString)
            XCTAssertEqual(qParamString.count, "foo=bar&baz=1&page=2&per_page=30".count)
            XCTAssertTrue(qParamString.contains("foo=bar"))
            XCTAssertTrue(qParamString.contains("baz=1"))
            XCTAssertTrue(qParamString.contains("page=2"))
            XCTAssertTrue(qParamString.contains("per_page=30"))
        }
        
        do {
            let endpoint = OtherPagingEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                               pathPrefix: "",
                                               queryParams: qParams)

            let qParamSubSeq = (endpoint.urlRequest(page: 2)?.url?.absoluteString.split(separator: "?").last)!
            let qParamString = String(qParamSubSeq)
            XCTAssertNotNil(qParamString)
            XCTAssertEqual(qParamString.count, "foo=bar&baz=1&sheet=2&how_many=5309".count)
            XCTAssertTrue(qParamString.contains("foo=bar"))
            XCTAssertTrue(qParamString.contains("baz=1"))
            XCTAssertTrue(qParamString.contains("sheet=2"))
            XCTAssertTrue(qParamString.contains("how_many=5309"))
        }
        
    }
    
    func testMethod() {
        let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                     pathPrefix: "",
                                     method: .delete)
        
        XCTAssertEqual(endpoint.urlRequest()?.httpMethod, EndpointHttpMethod.delete.rawValue)
    }

    func testJsonParams() {
        let jsonParams: [String: Any] = [
            "baz": "foo",
            "bar": 421,
            "force": true
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: jsonParams, options: [.sortedKeys])
        XCTAssertNotNil(jsonData)
        
        let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                     pathPrefix: "",
                                     method: .patch,
                                     jsonParams: jsonParams)
        
        XCTAssertEqual(endpoint.urlRequest()?.httpBody, jsonData)
    }
    
    func testFormParams() {
        let fParams = [
            "foo": "bar",
            "baz": "1",
            "xxx": "true"
        ]
        
        let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                     pathPrefix: "",
                                     method: .post,
                                     formParams: fParams)
        
        let body = endpoint.urlRequest()?.httpBody
        XCTAssertNotNil(body)
        let bodyString = String(data: body!, encoding: .utf8)!
        
        XCTAssertEqual(bodyString.count, "foo=bar&baz=1&xxx=true".count)
        XCTAssertTrue(bodyString.contains("foo=bar"))
        XCTAssertTrue(bodyString.contains("baz=1"))
        XCTAssertTrue(bodyString.contains("xxx=true"))
    }
    
    func testContentType() {
        // form data
        do {
            let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                         pathPrefix: "",
                                         method: .post,
                                         formParams: ["larry": "bar"])
            let contentHeader = endpoint.urlRequest()?.allHTTPHeaderFields?["Content-Type"]
            XCTAssertNotNil(contentHeader)
            XCTAssertEqual(contentHeader, "application/x-www-form-urlencoded")
        }
        // json data
        do {
            let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                         pathPrefix: "",
                                         method: .post,
                                         jsonParams: ["larry": "bar"])
            let contentHeader = endpoint.urlRequest()?.allHTTPHeaderFields?["Content-Type"]
            XCTAssertNotNil(contentHeader)
            XCTAssertEqual(contentHeader, "application/json")
        }
        // explicit content type
        do {
            let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                         pathPrefix: "",
                                         contentType: "chemical/x-pdb")
            let contentHeader = endpoint.urlRequest()?.allHTTPHeaderFields?["Content-Type"]
            XCTAssertNotNil(contentHeader)
            XCTAssertEqual(contentHeader, "chemical/x-pdb")
        }

    }
    
    func testUsernamePassword() {
        let username = "rhodey"
        let password = "WARMACHINEROX"
        let loginData = "\(username):\(password)".data(using: .utf8)!
        let encodedData = loginData.base64EncodedString()
        let expectedHeader = "Basic \(encodedData)"
        
        let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                     pathPrefix: "",
                                     username: username,
                                     password: password)
        
        let headers = endpoint.urlRequest()?.allHTTPHeaderFields
        let authHeader = headers?["Authorization"]
        XCTAssertNotNil(authHeader)
        XCTAssertEqual(authHeader, expectedHeader)
    }

    func testBody() {
        let randomString = UUID().uuidString
        let bodyData = randomString.data(using: .utf8)
        
        let endpoint = DummyEndpoint(serverUrl: URL(string:"http://oakcity.io")!,
                                     pathPrefix: "",
                                     body: bodyData)
        
        XCTAssertEqual(endpoint.urlRequest()?.httpBody, bodyData)
    }

    static var allTests = [
        ("testEqualitySimple", testEqualitySimple),
        ("testEquality", testEquality),
        ("testDefaults", testDefaults),
        ("testPathAttributes", testPathAttributes),
        ("testQueryParamsAttributes", testQueryParamsAttributes),
    ("testMethod", testMethod),
    ]
}
