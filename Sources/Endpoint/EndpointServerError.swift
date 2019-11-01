//
//  File.swift
//  
//
//  Created by Jay Lyerly on 11/1/19.
//

import Foundation

// Roughly based on https://tools.ietf.org/html/draft-pbryan-http-json-resource-01#section-10

public protocol EndpointServerError: Codable, Equatable {
    var error: String? { get }      // Error name -- AuthorizationFailed
    var reason: String? { get }     // Reson for error -- Username not found
    var detail: String? { get }     // Further details -- http://www.server.com/error/username.html
}

public struct EndpointDefaultServerError: EndpointServerError {
    public let error: String?
    public let reason: String?
    public let detail: String?
}

public extension EndpointDefaultServerError {
    init(reason: String?) {
        self.reason = reason
        error = nil
        detail = nil
    }
}
