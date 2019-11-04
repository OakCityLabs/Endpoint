//
//  FileDownloadEndpointTests.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Endpoint
import XCTest

class FileDownloadEndpointTests: XCTestCase {

    // swiftlint:disable:next function_body_length
    func testEquality() {
        
        let destinationA = URL(fileURLWithPath: "/tmp/foo.txt")
        let destinationB = URL(fileURLWithPath: "/tmp/bar.txt")
        let url = URL(string: "http://oakcity.io/A")!
        let prefix = "api/v1"
        let objId = "837"
        let suffix = "followers"
        let qParams = ["level": "7", "rank": "full"]
        let jsonParams: [String: Any] = ["bob": "bob", "larry": true, "daryl": 47]
        let mimeTypes = ["text/text"]
        let contentType = "json"
        let statusCodes = Array(189...197)
        let username = "spock"
        let password = "hotgreenblooded"
        let dateFormatter: DateFormatter = {
            let dFormatter = DateFormatter()
            dFormatter.timeStyle = .long
            dFormatter.dateStyle = .none
            return dFormatter
        }()
        
        let endpointA = FileDownloadEndpoint(destination: destinationA,
                                             serverUrl: url,
                                             pathPrefix: prefix,
                                             method: .patch,
                                             objId: objId,
                                             pathSuffix: suffix,
                                             queryParams: qParams,
                                             jsonParams: jsonParams,
                                             mimeTypes: mimeTypes,
                                             contentType: contentType,
                                             statusCodes: statusCodes,
                                             username: username,
                                             password: password,
                                             dateFormatter: dateFormatter)
        let endpointA2 = FileDownloadEndpoint(destination: destinationA,
                                              serverUrl: url,
                                              pathPrefix: prefix,
                                              method: .patch,
                                              objId: objId,
                                              pathSuffix: suffix,
                                              queryParams: qParams,
                                              jsonParams: jsonParams,
                                              mimeTypes: mimeTypes,
                                              contentType: contentType,
                                              statusCodes: statusCodes,
                                              username: username,
                                              password: password,
                                              dateFormatter: dateFormatter)
        
        let endpointB = FileDownloadEndpoint(destination: destinationB,
                                             serverUrl: url,
                                             pathPrefix: prefix,
                                             method: .patch,
                                             objId: objId,
                                             pathSuffix: suffix,
                                             queryParams: qParams,
                                             jsonParams: jsonParams,
                                             mimeTypes: mimeTypes,
                                             contentType: contentType,
                                             statusCodes: statusCodes,
                                             username: username,
                                             password: password,
                                             dateFormatter: dateFormatter)
        
        XCTAssertEqual(endpointA, endpointA2)
        XCTAssertNotEqual(endpointA, endpointB)
    }

    func testDownload() {
        let data = UUID().uuidString.data(using: .utf8)!
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)

        let serverUrl = URL(string: "http://oakcity.io/foo")!
        let endpoint = FileDownloadEndpoint(destination: url, serverUrl: serverUrl, pathPrefix: "")
        
        // write data to file
        let writtenUrl = endpoint.parse(data: data)
        
        // load data from file
        let writtenData = try! Data(contentsOf: url)
        
        XCTAssertEqual(writtenData, data)
        XCTAssertEqual(writtenUrl, url)

        // cleanup
        try! FileManager.default.removeItem(at: url)
    }
    
    func testDownloadFail() {
        let data = UUID().uuidString.data(using: .utf8)!
        let url = URL(fileURLWithPath: "/rootfile.dat")

        let serverUrl = URL(string: "http://oakcity.io/foo")!
        let endpoint = FileDownloadEndpoint(destination: url, serverUrl: serverUrl, pathPrefix: "")
        
        // write data to file
        let writtenUrl = endpoint.parse(data: data)
        
        // load data from file
        let writtenData = try? Data(contentsOf: url)
        
        XCTAssertNil(writtenUrl)
        XCTAssertNil(writtenData)
    }
    
    static var allTests = [
        ("testEquality", testEquality),
        ("testDownload", testDownload),
        ("testDownloadFail", testDownloadFail)
    ]
}
