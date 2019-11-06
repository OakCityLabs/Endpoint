//
//  ReachabilityTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 11/4/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

@testable import Endpoint
import XCTest

private typealias ServerValidationError = ValidationError<EndpointDefaultServerError>

class ReachabilityTests: XCTestCase {

    func testIsReachable() {
        XCTAssertTrue(ReachabilityTester().isConnectedToNetwork())
    }
    
    // How to test the negative case?
}
    
