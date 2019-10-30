//
//  LinuxMain.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import XCTest

import EndpointTests

var tests = [XCTestCaseEntry]()
tests += EndpointTests.allTests()
XCTMain(tests)
