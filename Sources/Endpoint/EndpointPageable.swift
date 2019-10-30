//
//  File.swift
//  
//
//  Created by Jay Lyerly on 10/30/19.
//

import Foundation

protocol EndpointPageable {
    static var perPage: Int { get }
}

extension Array: EndpointPageable where Element: EndpointPageable {
    static var perPage: Int {
        return Element.perPage
    }
}
