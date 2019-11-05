//
//  MimeTypeTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

@testable import Endpoint
import XCTest

class MimeTypeTests: XCTestCase {
    
    func testWildcard() {
        let fooType = MimeType("foo/bar")
        XCTAssertNotNil(fooType)
        
        let wildType = MimeType("*/*")
        XCTAssertNotNil(wildType)
        XCTAssertTrue(wildType!.isWildcard)
        
        XCTAssertEqual(fooType, wildType)
        XCTAssertEqual(wildType, fooType)
    }
    
    func testEquality() {
        let fooType = MimeType("foo/bar")
        XCTAssertNotNil(fooType)
        
        let fooType2 = MimeType("foo/bar")
        XCTAssertNotNil(fooType2)

        let barType = MimeType("baz/bat")
        XCTAssertNotNil(barType)
        
        XCTAssertEqual(fooType, fooType2)
        XCTAssertNotEqual(fooType, barType)
        XCTAssertNotEqual(fooType2, barType)
    }

    func testCreation() {
        // Should succeed
        let fooType = MimeType("foo/bar")
        XCTAssertNotNil(fooType)
        XCTAssertEqual(fooType!.type, "foo")
        XCTAssertEqual(fooType!.subtype, "bar")
        XCTAssertFalse(fooType!.isWildcard)

        let textType = MimeType("   text / html ")
        XCTAssertNotNil(textType)
        XCTAssertEqual(textType!.type, "text")
        XCTAssertEqual(textType!.subtype, "html")
        XCTAssertFalse(textType!.isWildcard)

        let wildType = MimeType("*/*")
        XCTAssertNotNil(wildType)
        XCTAssertEqual(wildType!.type, "*")
        XCTAssertEqual(wildType!.subtype, "*")
        XCTAssertTrue(wildType!.isWildcard)

        // Should fail
        XCTAssertNil(MimeType("Hello World!"))
        XCTAssertNil(MimeType(nil))
        XCTAssertNil(MimeType("foo/bar/baz"))
    }
    
    static var allTests = [
        ("testWildcard", testWildcard),
        ("testEquality", testEquality),
        ("testCreation", testCreation)
    ]
}
