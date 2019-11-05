//
//  ValidationErrorTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

typealias VError = ValidationError<EndpointDefaultServerError>

class ValidationErrorTests: XCTestCase {
    
    func testInit() {
        XCTAssertEqual(VError(statusCode: 107, serverError: nil), VError.unknown(107))
        XCTAssertEqual(VError(statusCode: 402, serverError: nil), VError.paymentRequired)
        XCTAssertEqual(VError(statusCode: 405, serverError: nil), VError.methodNotAllowed)

        let badReqError = EndpointDefaultServerError(error: "badReq", reason: "robot monkey", detail: nil)
        XCTAssertEqual(VError(statusCode: 400, serverError: badReqError), VError.badRequest(badReqError))
        
        let unauthError = EndpointDefaultServerError(error: "unauth", reason: "bad monkey", detail: nil)
        XCTAssertEqual(VError(statusCode: 401, serverError: unauthError), VError.unauthorized(unauthError))

        let forbiddenError = EndpointDefaultServerError(error: "forbidden", reason: "bad robot", detail: nil)
        XCTAssertEqual(VError(statusCode: 403, serverError: forbiddenError), VError.forbidden(forbiddenError))

        let notFoundError = EndpointDefaultServerError(error: "notfound", reason: "monkey robot", detail: nil)
        XCTAssertEqual(VError(statusCode: 404, serverError: notFoundError), VError.notFound(notFoundError))

        let serverError = EndpointDefaultServerError(error: "serverError", reason: "bad bad", detail: nil)
        XCTAssertEqual(VError(statusCode: 529, serverError: serverError), VError.serverError(serverError))
    }
    
    func testPretty() {
        XCTAssertEqual(VError.unknown(107).prettyDescription, "An unknown error has occured.")
        
        XCTAssertEqual(VError.invalidMimeType("snoop/dog").prettyDescription, "Invalid mime type: snoop/dog.")
        XCTAssertNil(VError.invalidMimeType(nil).prettyDescription)
        
        XCTAssertNil(VError.invalidUrlResponse.prettyDescription)
        XCTAssertEqual(VError.noData.prettyDescription, "Server returned no data.")
        
        let serverError = VError(statusCode: 532, serverError: EndpointDefaultServerError(error: "serverError",
                                                                                          reason: "bad bad",
                                                                                          detail: nil))
        XCTAssertEqual(serverError.prettyDescription, "bad bad")
        XCTAssertEqual(VError.serverError(nil).prettyDescription, "A server error has occured.")

        let badReqError = VError(statusCode: 532, serverError: EndpointDefaultServerError(error: "badReq",
                                                                                          reason: "robot monkey",
                                                                                          detail: nil))
        XCTAssertEqual(badReqError.prettyDescription, "robot monkey")
        XCTAssertEqual(VError.badRequest(nil).prettyDescription, "The client made a bad request to the server.")

        let unauthError = VError(statusCode: 400, serverError: EndpointDefaultServerError(error: "unauth",
                                                                                          reason: "bad monkey",
                                                                                          detail: nil))
        XCTAssertEqual(unauthError.prettyDescription, "bad monkey")
        XCTAssertEqual(VError.unauthorized(nil).prettyDescription, "The user is unauthorized.")

        XCTAssertNil(VError.paymentRequired.prettyDescription)

        let forbiddenError = VError(statusCode: 403, serverError:  EndpointDefaultServerError(error: "forbidden",
                                                                                           reason: "bad robot",
                                                                                           detail: nil))
        XCTAssertEqual(forbiddenError.prettyDescription, "bad robot")
        XCTAssertEqual(VError.forbidden(nil).prettyDescription, "Access is forbidden.")

        let notFoundError = VError(statusCode: 403, serverError: EndpointDefaultServerError(error: "notfound",
                                                                                            reason: "monkey robot",
                                                                                            detail: nil))
        XCTAssertEqual(notFoundError.prettyDescription, "monkey robot")
        XCTAssertEqual(VError.notFound(nil).prettyDescription, "The requested resource was not found on the server.")
        
        XCTAssertNil(VError.methodNotAllowed.prettyDescription)
    }

    static var allTests = [
         ("testInit", testInit),
         ("testPretty", testPretty)
     ]
}
