//
//  User.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

struct User: Codable {
    let objId: Int
    let firstName: String
    let lastName: String
    
    private enum CodingKeys: String, CodingKey {
        case objId = "id"
        case firstName = "first_name"
        case lastName = "last_name"
    }

    static let sampleJsonData: Data? = """
        {
            "id": 949,
            "first_name": "Larry",
            "last_name": "Bird"
        }
    """.data(using: .utf8)

}
