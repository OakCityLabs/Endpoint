//
//  EndpointServerError.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
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
    
    public init(error: String?, reason: String?, detail: String?) {
        self.error = error
        self.reason = reason
        self.detail = detail
    }

    public init(reason: String?) {
        self.reason = reason
        error = nil
        detail = nil
    }
}
