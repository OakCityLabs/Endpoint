//
//  File.swift
//  
//
//  Created by Jay Lyerly on 11/1/19.
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
