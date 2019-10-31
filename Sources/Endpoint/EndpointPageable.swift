//
//  EndpointPageable.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

public protocol EndpointPageable {
    /// How many objects per page?
    static var perPage: Int { get }
    
    /// Label for the query parameter to specify object per page, eg 'per_page'
    static var perPageLabel: String { get }
    
    /// Label for the query paramter to specify which page of results, eg 'page'
    static var pageLabel: String { get }
}

public extension EndpointPageable {
    static var perPage: Int {
        return 30
    }
    
    static var perPageLabel: String {
        return "per_page"
    }
    
    static var pageLabel: String {
        return "page"
    }
}

extension Array: EndpointPageable where Element: EndpointPageable {
    public static var perPageLabel: String {
        return Element.perPageLabel
    }
    
    public static var perPage: Int {
        return Element.perPage
    }
    
    public static var pageLabel: String {
        return Element.pageLabel
    }
}
