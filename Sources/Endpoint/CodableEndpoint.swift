//
//  CodableEndpoint.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

open class CodableEndpoint<Payload: Codable>: Endpoint<Payload> {

    override open func parse(data: Data, page: Int = 0) throws -> Payload {
//            let inputStr = String(data: data, encoding: .utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return try decoder.decode(Payload.self, from: data)
    }
}
