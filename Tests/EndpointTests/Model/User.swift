//
//  File.swift
//  
//
//  Created by Jay Lyerly on 11/4/19.
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


