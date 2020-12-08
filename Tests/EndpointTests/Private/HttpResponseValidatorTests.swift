//
//  HttpResponseValidatorTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 11/4/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

@testable import Endpoint
import Logging
import XCTest

private typealias ServerValidationError = ValidationError<EndpointDefaultServerError>

class HttpResponseValidatorTests: XCTestCase {
    
    func testStatusCodes() {
        func test(code: Int,
                  error referenceError: ServerValidationError,
                  serverError: EndpointDefaultServerError) -> Bool {
            let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self)
            let headers = ["Content-Type": "application/json"]
            let url = URL(string: "http://www.oakcity.io")!
            let response = HTTPURLResponse(url: url, statusCode: code, httpVersion: "v1.1", headerFields: headers)
            
            let data = try! JSONEncoder().encode(serverError)
            let req = URLRequest(url: url)
            
            let validationResult = validator.validate(data: data, response: response, request: req)
            
            if case ValidationResult.failure(let error) = validationResult {
                return error as! ValidationError == referenceError
            }
            return false
        }
        
        // We don't really use dummyError for testing these http codes, but the data
        // payload needs to be there.
        let dummyError = EndpointDefaultServerError(error: "SomeError", reason: "Something happen", detail: "For realz")
        XCTAssertTrue(test(code: 402, error: .paymentRequired, serverError: dummyError))
        XCTAssertTrue(test(code: 405, error: .methodNotAllowed, serverError: dummyError))
        
        XCTAssertTrue(test(code: 600, error: .unknown(600), serverError: dummyError))
        XCTAssertTrue(test(code: 999, error: .unknown(999), serverError: dummyError))
        XCTAssertTrue(test(code: 001, error: .unknown(001), serverError: dummyError))
        
        XCTAssertTrue(test(code: 400,
                           error: .badRequest(EndpointDefaultServerError(reason: "Error #1")),
                           serverError: EndpointDefaultServerError(error: nil, reason: "Error #1", detail: nil)))
        XCTAssertTrue(test(code: 403,
                           error: .forbidden(EndpointDefaultServerError(reason: "Error #3")),
                           serverError: EndpointDefaultServerError(error: nil, reason: "Error #3", detail: nil)))
        XCTAssertTrue(test(code: 404,
                           error: .notFound(EndpointDefaultServerError(reason: "Error #5")),
                           serverError: EndpointDefaultServerError(error: nil, reason: "Error #5", detail: nil)))
        XCTAssertTrue(test(code: 401,
                           error: .unauthorized(EndpointDefaultServerError(reason: "Error #7")),
                           serverError: EndpointDefaultServerError(error: nil, reason: "Error #7", detail: nil)))

        XCTAssertTrue(test(code: 505,
                           error: .serverError(EndpointDefaultServerError(reason: "Error #9")),
                           serverError: EndpointDefaultServerError(error: nil, reason: "Error #9", detail: nil)))
    }
    
    func testSucess() {
        let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self)
        let headers = ["Content-Type": "application/json"]
        let url = URL(string: "http://www.oakcity.io")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "v1.1", headerFields: headers)
        
        let data = "{\"status\": \"ok\"}".data(using: .utf8)!
        let req = URLRequest(url: url)
        
        let validationResult = validator.validate(data: data,
                                                  response: response,
                                                  request: req)
        
        if case ValidationResult.failure = validationResult {
            XCTFail("Error -- response should validate.")
        }
    }
    
    func testMimeType() {
        let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self,
                                              acceptedMimeTypes: ["foo/bar"])
        let headers = ["Content-Type": "application/json"]
        let url = URL(string: "http://www.oakcity.io")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "v1.1", headerFields: headers)
        
        let data = "{\"status\": \"ok\"}".data(using: .utf8)!
        let req = URLRequest(url: url)
        
        let validationResult = validator.validate(data: data,
                                                  response: response,
                                                  request: req)
        
        switch validationResult {
        case .success:
            XCTFail("Error -- response should be invalid.")
        case .failure(let error):
            XCTAssertEqual(error as! ServerValidationError,
                           ServerValidationError.invalidMimeType("application/json"))
        }
    }
    
    func testStatusCodeFail() {
        let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self,
                                              acceptedStatusCodes: Array(500...599))
        let headers = ["Content-Type": "application/json"]
        let url = URL(string: "http://www.oakcity.io")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "v1.1", headerFields: headers)
        
        let data = "{\"status\": \"ok\"}".data(using: .utf8)!
        let req = URLRequest(url: url)
        
        let validationResult = validator.validate(data: data,
                                                  response: response,
                                                  request: req)
        
        switch validationResult {
        case .success:
            XCTFail("Error -- response should be invalid.")
        case .failure(let error):
            XCTAssertEqual(error as! ServerValidationError, ServerValidationError.unknown(200))
        }
    }
    
    func testStatusCodeSuccess() {
        let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self,
                                              acceptedStatusCodes: Array(500...599))
        let headers = ["Content-Type": "application/json"]
        let url = URL(string: "http://www.oakcity.io")!
        let response = HTTPURLResponse(url: url, statusCode: 503, httpVersion: "v1.1", headerFields: headers)
        
        let data = "{\"status\": \"ok\"}".data(using: .utf8)!
        let req = URLRequest(url: url)
        
        let validationResult = validator.validate(data: data,
                                                  response: response,
                                                  request: req)
        
        if case ValidationResult.failure = validationResult {
            XCTFail("Error -- response should validate.")
        }
    }
    
    func testInvalidRequest() {
        let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self,
                                              acceptedStatusCodes: Array(500...599))
        let url = URL(string: "foo://www.oakcity.io")!
        let response = URLResponse(url: url,
                                   mimeType: "application/json",
                                   expectedContentLength: 200,
                                   textEncodingName: nil)
        
        let data = "{\"reason\": \"ok\"}".data(using: .utf8)!
        let req = URLRequest(url: url)
        
        let validationResult = validator.validate(data: data,
                                                  response: response,
                                                  request: req)

        switch validationResult {
        case .success:
            XCTFail("Error -- response should be invalid.")
        case .failure(let error):
            XCTAssertEqual(error as! ServerValidationError, ServerValidationError.invalidUrlResponse)
        }
    }
    
    func testLogging() {
        let validator = HttpResponseValidator(serverErrorType: EndpointDefaultServerError.self)
        let headers = ["Content-Type": "application/json"]
        let url = URL(string: "http://www.oakcity.io")!
        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "v1.1", headerFields: headers)
        
        let serverError = EndpointDefaultServerError(reason: "This resource was not found.")
        let responseData = try! JSONEncoder().encode(serverError)
        
        var req = URLRequest(url: url)
        req.httpBody = "{\"update\": \"foo\"}".data(using: .utf8)!
        req.allHTTPHeaderFields = ["compress": "gzip"]
        
        let validationResult = validator.validate(data: responseData, response: response, request: req)
        
        switch validationResult {
        case .success:
            XCTFail("Error -- response should be invalid.")
        case .failure(let error):
            XCTAssertEqual(error as! ServerValidationError,
                           ServerValidationError
                            .notFound(EndpointDefaultServerError(reason: "This resource was not found.")))
        }
        
        let lines = [
            "Request URL: http://www.oakcity.io",
            "Request Method: GET",
            "Request Headers:     compress: gzip",
            "Request Body: {\"update\": \"foo\"}",
            "Response code: 404",
            "Response Headers:     Content-Type: application/json",
            "Response Body: {\"reason\":\"This resource was not found.\"}"
        ]
                
        let file = "HttpResponseValidator.swift"
        let function = "performDebug(data:response:request:)"
        for line in lines {
            FakeLogStorage.shared.assertMessageContains(level: .debug, message: line, file: file, function: function)
        }
        
    }
}
