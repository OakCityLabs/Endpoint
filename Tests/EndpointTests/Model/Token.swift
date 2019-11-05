//
//  Token.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

struct Token: Codable {
    let value: String
    let expiration: Date

    static let sampleJsonData: Data? = """
        {
            "value": "e8944fdd-0680-44a1-8cee-f8badb82f6e7",
            "expiration": "2020-12-31"
        }
    """.data(using: .utf8)

}
