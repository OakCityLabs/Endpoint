//
//  Dictionary.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

extension Dictionary where Key: Comparable {
    
    func prettify(indentCount: Int = 1) -> String {
        var rString = ""
        
        let sortedKeys = keys.sorted { $0 < $1 }
        
        for key in sortedKeys {
            rString += "    " * indentCount + "\(key): "
            if let value = self[key] {
                rString += "\(value)"
            } else {
                rString += "<Missing Value>"
            }
            rString += "\n"
        }
        
        return rString
    }
}
