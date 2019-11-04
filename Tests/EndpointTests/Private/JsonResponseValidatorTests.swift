//
//  JsonResponseValidatorTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 11/4/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

@testable import Endpoint
import XCTest

private typealias ServerValidationError = ValidationError<EndpointDefaultServerError>

class JsonResponseValidatorTests: XCTestCase {
    
    func testSucess() {
        let validator = JsonResponseValidator(serverErrorType: EndpointDefaultServerError.self)
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
    
    func testFail() {
        let validator = JsonResponseValidator(serverErrorType: EndpointDefaultServerError.self)
        let headers = ["Content-Type": "foo/bar"]
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
            XCTAssertEqual(error as! ServerValidationError, ServerValidationError.invalidMimeType("foo/bar"))
        }
    }
    
}
