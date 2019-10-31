//
//  DateFormatterTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

final class DateFormatterTests: XCTestCase {
    let formatter = DateFormatter.iso8601Full
    
    func testFormat() {
        let refDate = Date(timeIntervalSince1970: 1_531_939_232)
        let refStr = formatter.string(from: refDate)
        let str = "2018-07-18T18:40:32.000Z"
        XCTAssertEqual(str, refStr)
    }

    func testParse() {
        let str = "2018-07-18T18:40:28.0000+00:00"
        let date = formatter.date(from: str)
        let refDate = Date(timeIntervalSince1970: 1_531_939_228)
        XCTAssertEqual(date, refDate)
    }

    static var allTests = [
        ("testFormat", testFormat),
        ("testParse", testParse)
    ]
}
