///
//  EndpointControllerTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 11/7/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

class EndpointControllerTests: XCTestCase {

    // Test for bug -- setting a bear token auth token was getting overwritten by an empty
    // basic authentication username / password
    func testAuthToken() {
        let authToken = UUID().uuidString
        let controller = EndpointController<EndpointDefaultServerError>()
        let endpoint = CodableEndpoint<User>(serverUrl: URL(string: "http://foo.com")!, pathPrefix: "")
        
        controller.addAuthBearer(authToken: authToken)
        let req = controller.urlRequest(forEndpoint: endpoint, page: 1)
        
        let authHeader = req?.allHTTPHeaderFields?["Authorization"]
        XCTAssertNotNil(authHeader)
        XCTAssertEqual(authHeader, "Bearer \(authToken)")
    }
    
}
