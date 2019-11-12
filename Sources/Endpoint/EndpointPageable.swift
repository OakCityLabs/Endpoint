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

    /// Paging is assumed to start at page == 1, which is true for most servers.
    /// This value (default 0) is added to the page before sending to the server,
    /// so a value of -1 for the offSet would work with zero based paging on the
    /// server
    static var pageOffset: Int { get }
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
    
    static var pageOffset: Int {
        return 0
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

    public static var pageOffset: Int {
        return Element.pageOffset
    }
}
