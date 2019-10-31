//
//  EndpointTests+Equality.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

private typealias DummyEndpoint = Endpoint<String>

extension EndpointTests {
    func testEqualitySimple() {
        
        let urlA = URL(string: "http://oakcity.io/A/api")!
        let urlB = URL(string: "http://oakcity.io/B/api")!
        
        let endpointA = DummyEndpoint(serverUrl: urlA, pathPrefix: "hello")
        let endpointA2 = DummyEndpoint(serverUrl: urlA, pathPrefix: "hello")
        let endpointB = DummyEndpoint(serverUrl: urlB, pathPrefix: "hello")

        XCTAssertEqual(endpointA, endpointA2)
        XCTAssertNotEqual(endpointA, endpointB)
    }

    // swiftlint:disable:next function_body_length
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
}
