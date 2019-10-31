//
//  StringTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

@testable import Endpoint
import XCTest

class StringTests: XCTestCase {
    
    func testPercentEscaped() {
        // See https://en.wikipedia.org/wiki/Percent-encoding
        
        XCTAssertEqual("abcd".percentEscaped, "abcd")
        XCTAssertEqual("ab!cd".percentEscaped, "ab%21cd")
        XCTAssertEqual("ab#cd".percentEscaped, "ab%23cd")
        XCTAssertEqual("ab$cd".percentEscaped, "ab%24cd")
        XCTAssertEqual("ab%cd".percentEscaped, "ab%25cd")
        XCTAssertEqual("ab&cd".percentEscaped, "ab%26cd")
        XCTAssertEqual("ab'cd".percentEscaped, "ab%27cd")
        XCTAssertEqual("ab(cd".percentEscaped, "ab%28cd")
        XCTAssertEqual("ab)cd".percentEscaped, "ab%29cd")
        XCTAssertEqual("ab*cd".percentEscaped, "ab%2Acd")
        XCTAssertEqual("ab+cd".percentEscaped, "ab%2Bcd")
        XCTAssertEqual("ab,cd".percentEscaped, "ab%2Ccd")
        XCTAssertEqual("ab/cd".percentEscaped, "ab%2Fcd")
        XCTAssertEqual("ab:cd".percentEscaped, "ab%3Acd")
        XCTAssertEqual("ab;cd".percentEscaped, "ab%3Bcd")
        XCTAssertEqual("ab=cd".percentEscaped, "ab%3Dcd")
        XCTAssertEqual("ab?cd".percentEscaped, "ab%3Fcd")
        XCTAssertEqual("ab@cd".percentEscaped, "ab%40cd")
        XCTAssertEqual("ab[cd".percentEscaped, "ab%5Bcd")
        XCTAssertEqual("ab]cd".percentEscaped, "ab%5Dcd")
        XCTAssertEqual("ab cd".percentEscaped, "ab+cd")
    }

    static var allTests = [
        ("testPercentEscaped", testPercentEscaped)
    ]
}
