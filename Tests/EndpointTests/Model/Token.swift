//
//  Token.swift
//  
//
//  Created by Jay Lyerly on 11/5/19.
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
