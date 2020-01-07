//
//  EndpointError.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

public enum EndpointError: Error, Equatable {
    case urlRequestCreationError
    case parseError
    case noParser
    case requestCancelled
    case serverUnreachable
    case connectionError
    case missingBackgroundSession
    case unknownError
}
