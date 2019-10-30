//
//  File.swift
//  
//
//  Created by Jay Lyerly on 10/30/19.
//

import Foundation

class CodableEndpoint<Payload: Codable>: Endpoint<Payload> {

    override func parse(data: Data, page: Int = 0) -> Payload? {
//            let inputStr = String(data: data, encoding: .utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        do {
            return try decoder.decode(Payload.self, from: data)
        } catch {
            globalDebug("Failed to decode server response with error: \(error)")
            return nil
        }
    }
}
