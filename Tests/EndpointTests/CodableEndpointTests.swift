//
//  CodableEndpointTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

class FakeUrlSession: URLSession {
    
    let data: Data?
    let urlResponse: URLResponse?
    let error: Error?
    
    init(data: Data?, urlResponse: URLResponse?, error: Error?) {
        self.data = data
        self.urlResponse = urlResponse
        self.error = error
        super.init()
    }
    
    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        completionHandler(data, urlResponse, error)
        return URLSessionDataTask()
    }
    
}

class FakeReachability: Reachability {
    override func isConnectedToNetwork() -> Bool {
        return true
    }
}

class CodableEndpointTests: XCTestCase {
    
    func testParse() {
        let data = User.sampleJsonData!
        let serverUrl = URL(string: "https://oakcity.io/foo/bar/baz/1")!
        
        let endpoint = CodableEndpoint<User>(serverUrl: serverUrl, pathPrefix: "")
        
        let httpHeaders = [
            "Content-Type": "application/json"
        ]
        let urlResponse = HTTPURLResponse(url: serverUrl,
                                          statusCode: 200,
                                          httpVersion: "1.1",
                                          headerFields: httpHeaders)
    
        let fakeUrlSession = FakeUrlSession(data: data, urlResponse: urlResponse, error: nil)
        let controller =
            EndpointController<EndpointDefaultServerError>(session: fakeUrlSession,
                                                           serverErrorType: EndpointDefaultServerError.self,
                                                           reachability: FakeReachability())

        controller.load(endpoint) {result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user.objId, 949)
                XCTAssertEqual(user.firstName, "Larry")
                XCTAssertEqual(user.lastName, "Bird")
            case .failure(let error):
                XCTFail("Failed to load endpoint with error: \(error)")
            }
        }
    }
    
    func testMimeTypes() {
        XCTFail("test mimetypes")
    }
    
    func testStatusCodes() {
        XCTFail("test status codes")
    }
    
    func testDateFormatter() {
        XCTFail("test date formatter")        
    }
    
    static var allTests = [
        ("testParse", testParse)
    ]
}
