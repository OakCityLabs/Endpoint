//
//  MimeType.swift
//  Endpoint
//
//  Created by Jay Lyerly on 11/01/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

// Lifted from AlamoFire
// https://github.com/Alamofire/Alamofire/blob/master/Source/Validation.swift

struct MimeType {
    let type: String
    let subtype: String
    
    var isWildcard: Bool { return type == "*" && subtype == "*" }
    
    func matches(_ mime: MimeType) -> Bool {
        // true if either is a wildcard
        if mime.isWildcard || self.isWildcard {
            return true
        }
        
        return (mime.type == self.type) && (mime.subtype == mime.subtype)
    }
    
}

extension MimeType {
    init?(_ string: String?) {
        guard let string = string else {
            return nil
        }
        let components: [String] = {
            let stripped = string.trimmingCharacters(in: .whitespacesAndNewlines)
            let split = stripped[..<(stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)]
            return split.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }()
        
        guard components.count == 2 else {
            return nil
        }
        
        if let type = components.first, let subtype = components.last {
            self.type = type
            self.subtype = subtype
        } else {
            return nil
        }
    }
}

extension MimeType: Equatable {
    static func == (lhs: MimeType, rhs: MimeType) -> Bool {
        return lhs.matches(rhs)
    }
}
