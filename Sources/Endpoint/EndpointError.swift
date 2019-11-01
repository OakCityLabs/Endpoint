//
//  EndpointError.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

public enum EndpointError: Error, Equatable {
    case urlRequestCreation
    case parseError
    case requestCancelled
    case serverUnreachable
    case connectionError
    case missingBackroundSession
    case unknownError
}
