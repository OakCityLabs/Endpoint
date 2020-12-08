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
        return URLSession(configuration: .ephemeral).dataTask(with: request)
    }
}

class FakeReachability: ReachabilityTester {
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
        let data = User.sampleJsonData!
        let serverUrl = URL(string: "https://oakcity.io/foo/bar/baz/1")!
        
        // random mime type should fail
        let endpoint = CodableEndpoint<User>(serverUrl: serverUrl, pathPrefix: "", mimeTypes: ["foo/bar"])
        
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
                                                           reachability: FakeReachability())
        
        controller.load(endpoint) {result in
            switch result {
            case .success:
                XCTFail("Should fail to load endpoint")
            case .failure(let error):
                XCTAssertEqual(error as! ValidationError<EndpointDefaultServerError>,
                               .invalidMimeType("application/json"))
            }
        }
    }
    
    func testStatusCodes() {
        let data = User.sampleJsonData!
        let serverUrl = URL(string: "https://oakcity.io/foo/bar/baz/1")!
        
        // expects status code in the 200s (default) -- should faile on 777
        let endpoint200 = CodableEndpoint<User>(serverUrl: serverUrl, pathPrefix: "")
        // expects status code 777
        let endpoint777 = CodableEndpoint<User>(serverUrl: serverUrl, pathPrefix: "", statusCodes: [777])

        let httpHeaders = [
            "Content-Type": "application/json"
        ]
        let urlResponse = HTTPURLResponse(url: serverUrl,
                                          statusCode: 777,
                                          httpVersion: "1.1",
                                          headerFields: httpHeaders)
        let fakeUrlSession = FakeUrlSession(data: data, urlResponse: urlResponse, error: nil)
        let controller =
            EndpointController<EndpointDefaultServerError>(session: fakeUrlSession,
                                                           reachability: FakeReachability())
        
        // endpoint777 should work
        controller.load(endpoint777) {result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user.objId, 949)
                XCTAssertEqual(user.firstName, "Larry")
                XCTAssertEqual(user.lastName, "Bird")
            case .failure(let error):
                XCTFail("Failed to load endpoint with error: \(error)")
            }
        }
        
        // endpoint200 should fail
        controller.load(endpoint200) {result in
            switch result {
            case .success:
                XCTFail("Should fail to load endpoint")
            case .failure(let error):
                XCTAssertEqual(error as! ValidationError<EndpointDefaultServerError>,
                               .unknown(777))
            }
        }

    }
    
    func testDateFormatter() {
        let data = Token.sampleJsonData!
        let serverUrl = URL(string: "https://oakcity.io/foo/bar/baz/1")!
        
        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }()
        let endpoint = CodableEndpoint<Token>(serverUrl: serverUrl, pathPrefix: "", dateFormatter: formatter)
        
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
                                                           reachability: FakeReachability())
        
        let expectedDate: Date = {
            let calendar = Calendar.current
            let dateComponents = DateComponents(calendar: calendar,
                                                timeZone: TimeZone(secondsFromGMT: 0),
                                                year: 2_020,
                                                month: 12,
                                                day: 31)
            return calendar.date(from: dateComponents)!
        }()
        
        controller.load(endpoint) {result in
            switch result {
            case .success(let token):
                XCTAssertEqual(token.value, "e8944fdd-0680-44a1-8cee-f8badb82f6e7")
                XCTAssertEqual(token.expiration, expectedDate)
            case .failure(let error):
                XCTFail("Failed to load endpoint with error: \(error)")
            }
        }
    }
    
    static var allTests = [
        ("testParse", testParse)
    ]
    
    func testNetworkError() {
        FakeLogHandler.install()
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
    
        let networkErr = NSError(domain: "idksure.bud", code: NSURLErrorCannotFindHost, userInfo: nil)
        let fakeUrlSession = FakeUrlSession(data: data, urlResponse: urlResponse, error: networkErr)
        let controller =
            EndpointController<EndpointDefaultServerError>(session: fakeUrlSession,
                                                           reachability: FakeReachability())
        
        XCTAssertFalse(endpoint.failSilently)
        controller.load(endpoint) { result in
            switch result {
            case .success:
                XCTFail("Should have network error")
            case .failure(let error):
                let nsErr = error as? EndpointError
                XCTAssertEqual(nsErr, EndpointError.connectionError)
            }
        }
        
        let msg = "Network connection error: \(networkErr)"
        FakeLogStorage.shared.assertMessageContains(level: .warning, message: msg,
                                                    file: "EndpointController.swift",
                                                    function: "process(networkError:failSilently:)")
    }
    
    func testNetworkErrorFailsSilently() {
        FakeLogStorage.shared.clear()
        let data = User.sampleJsonData!
        let serverUrl = URL(string: "https://oakcity.io/foo/bar/baz/1")!
        
        let endpoint = CodableEndpoint<User>(serverUrl: serverUrl, pathPrefix: "", failSilently: true)
        
        let httpHeaders = [
            "Content-Type": "application/json"
        ]
        let urlResponse = HTTPURLResponse(url: serverUrl,
                                          statusCode: 200,
                                          httpVersion: "1.1",
                                          headerFields: httpHeaders)
    
        let networkErr = NSError(domain: "idksure.bud", code: NSURLErrorCannotFindHost, userInfo: nil)
        let fakeUrlSession = FakeUrlSession(data: data, urlResponse: urlResponse, error: networkErr)
        let controller =
            EndpointController<EndpointDefaultServerError>(session: fakeUrlSession,
                                                           reachability: FakeReachability())
        
        XCTAssertTrue(endpoint.failSilently)
        controller.load(endpoint) { result in
            switch result {
            case .success:
                XCTFail("Should have network error")
            case .failure(let error):
                let nsErr = error as? EndpointError
                XCTAssertEqual(nsErr, EndpointError.connectionError)
            }
        }
        
        let msg = "Network connection error: \(networkErr)"
        FakeLogStorage.shared.assertMessageDoesNotContain(level: .warning,
                                                          message: msg,
                                                          file: "EndpointController.swift",
                                                          function: "process(networkError:failSilently:)")
    }
}
