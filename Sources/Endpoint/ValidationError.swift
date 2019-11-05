//
//  ValidationError.swift
//  Endpoint
//
//  Created by Jay Lyerly on 11/01/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

public enum ValidationError<ServerError: EndpointServerError>: Error {
    case unknown(Int)                       // Unknown with attached status code
    case invalidMimeType(String?)
    case invalidUrlResponse
    case noData
    case serverError(ServerError?)          // All 5xx
    case badRequest(ServerError?)           // 400 with associated error and description
    case unauthorized(ServerError?)         // 401
    case paymentRequired                    // 402
    case forbidden(ServerError?)            // 403 with associated error and description
    case notFound(ServerError?)             // 404 with associated error and description
    case methodNotAllowed                   // 405
    
    public init(statusCode: Int, serverError: ServerError?) {
        
        switch statusCode {
        case 500...599:
            self = .serverError(serverError)
        case 400:
            self = .badRequest(serverError)
        case 401:
            self = .unauthorized(serverError)
        case 402:
            self = .paymentRequired
        case 403:
            self = .forbidden(serverError)
        case 404:
            self = .notFound(serverError)
        case 405:
            self = .methodNotAllowed
        default:
            self = .unknown(statusCode)
        }
    }
    
    public var prettyDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error has occured."
        case .invalidMimeType(let mimeType):
            if let mimeType = mimeType {
                return "Invalid mime type: \(mimeType)."
            } else {
                return nil
            }
        case .invalidUrlResponse:
            return nil
        case .noData:
            return "Server returned no data."
        case let .serverError(serverError):
            return serverError?.reason ?? "A server error has occured."
        case let .badRequest(serverError):
            return serverError?.reason ?? "The client made a bad request to the server."
        case let .unauthorized(serverError):
            return serverError?.reason ?? "The user is unauthorized."
        case .paymentRequired:
            return nil
        case let .forbidden(serverError):
            return serverError?.reason ?? "Access is forbidden."
        case let .notFound(serverError):
            return serverError?.reason ?? "The requested resource was not found on the server."
        case .methodNotAllowed:
            return nil
        }
    }
    
}

extension ValidationError: Equatable {
    //swiftlint:disable:next cyclomatic_complexity function_body_length
    public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        switch lhs {
        case .unknown:
            switch rhs {
            case .unknown:
                return true
            default:
                return false
            }
            
        case .invalidMimeType(let lhsMimeType):
            switch rhs {
            case .invalidMimeType(let rhsMimeType):
                return lhsMimeType == rhsMimeType
            default:
                return false
            }
            
        case .invalidUrlResponse:
            switch rhs {
            case .invalidUrlResponse:
                return true
            default:
                return false
            }
            
        case .noData:
            switch rhs {
            case .noData:
                return true
            default:
                return false
            }
            
        case .serverError:
            switch rhs {
            case .serverError:
                return true
            default:
                return false
            }
            
        case let .badRequest(lhServerError):
            switch rhs {
            case let .badRequest(rhServerError):
                return lhServerError == rhServerError
            default:
                return false
            }
            
        case .unauthorized:
            switch rhs {
            case .unauthorized:
                return true
            default:
                return false
            }
            
        case .paymentRequired:
            switch rhs {
            case .paymentRequired:
                return true
            default:
                return false
            }
            
        case let .forbidden(lhServerError):
            switch rhs {
            case let .forbidden(rhServerError):
                return lhServerError == rhServerError
            default:
                return false
            }
            
        case let .notFound(lhServerError):
            switch rhs {
            case let .notFound(rhServerError):
                return lhServerError == rhServerError
            default:
                return false
            }
        case .methodNotAllowed:
            switch rhs {
            case .methodNotAllowed:
                return true
            default:
                return false
            }
            
        }
    }
    
}
