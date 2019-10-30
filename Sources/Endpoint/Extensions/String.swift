//
//  String.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//
import Foundation

extension String {
    
    var percentEscaped: String {
        let characterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._* "))
        
        let escapedString = self
            .addingPercentEncoding(withAllowedCharacters: characterSet)?
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "/", with: "%2F")
            .replacingOccurrences(of: " ", with: "+")

        guard let retString = escapedString else {
            assertionFailure("Failed to percent encode string.")
            return ""
        }
        
        return retString
    }
    
}
