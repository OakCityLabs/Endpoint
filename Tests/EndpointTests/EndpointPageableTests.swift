//
//  EndpointPageableTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

private struct Foo: EndpointPageable {}

class EndpointPageableTests: XCTestCase {

    func testArrayExtension() {
        XCTAssertEqual(([Foo].self).pageLabel, "page")
        XCTAssertEqual(([Foo].self).perPage, 30)
        XCTAssertEqual(([Foo].self).perPageLabel, "per_page")
    }
    
}
