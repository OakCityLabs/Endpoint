//
//  HttpResponseValidator.swift
//  Endpoint
//
//  Created by Jay Lyerly on 11/01/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation
import Logging

extension NSNotification.Name {
    static let endpointValidationError401Unauthorized = Notification.Name("EndpointValidationError401Unauthorized")
}

public enum ValidationResult {
    case success
    case failure(Error)
    
    var needsDebug: Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }
}

class HttpResponseValidator<ServerError: EndpointServerError> {
    
    private let acceptedMimeTypes: [MimeType]
    private let acceptedStatusCodes: [Int]
    private let logger: Logger
    private let maxHttpResponseSize: Int
    private let debugAllHttp: Bool
    
    init(serverErrorType: ServerError.Type,
         logger: Logger = Logger(label: "com.oakcity.endpoint.httpresponsevalidator"),
         acceptedMimeTypes mTypes: [String] = ["*/*"],
         acceptedStatusCodes codes: [Int] = Array(200..<300),
         maxHttpResponseSize: Int = 5_000,
         debugAllHttp: Bool = false) {
        self.logger = logger
        self.maxHttpResponseSize = maxHttpResponseSize
        self.debugAllHttp = debugAllHttp
        acceptedMimeTypes = mTypes.compactMap { MimeType($0) }
        acceptedStatusCodes = codes
    }
    
    private func postErrorNotification(statusCode: Int) {
        switch statusCode {
        case 401:
            NotificationCenter.default.post(Notification(name: .endpointValidationError401Unauthorized))
        default:
            break
        }
        
    }
    
    private func performValidation(data: Data?,
                                   response urlResponse: URLResponse?,
                                   request: URLRequest) -> ValidationResult {
        
        guard let response = urlResponse as? HTTPURLResponse else {
            return .failure(ValidationError<ServerError>.invalidUrlResponse)
        }
        
        let statusCode = response.statusCode
        postErrorNotification(statusCode: statusCode)
        
        if data == nil, statusCode != 204 {
            return .failure(ValidationError<ServerError>.noData)
        }
        
        if !acceptedStatusCodes.contains(statusCode) {
            let serverError = data.flatMap { try? JSONDecoder().decode(ServerError.self, from: $0) }
            return .failure(ValidationError<ServerError>(statusCode: statusCode, serverError: serverError))
        }
        
        let mimeType = MimeType(response.mimeType) ?? MimeType(type: "missing", subtype: "missing")
        if !acceptedMimeTypes.contains(mimeType), statusCode != 204 {     // ignore mimetype on 204
            return .failure(ValidationError<ServerError>.invalidMimeType(response.mimeType))
        }
        
        return .success
    }
    
    private func performDebug(data: Data?, response urlResponse: URLResponse?, request: URLRequest) {
        guard let response = urlResponse as? HTTPURLResponse else {
            logger.debug(">>>>> Can't log non-HTTPURLResponse: \(String(describing: urlResponse))")
            return
        }
        
        let length = responseSize(response: response)
        if length > maxHttpResponseSize {
            logger.debug(">>>>> Reponse size too big! \(length)")
        }
        
        logger.debug("Request URL: \(request.url?.absoluteString ?? "<no URL>")")
        logger.debug("Request Method: \(request.httpMethod ?? "<no method>")")
        let reqHeaders = request.allHTTPHeaderFields?.prettify() ?? "<no headers>"
        logger.debug("Request Headers: \(reqHeaders)")
        if let data = request.httpBody {
            let requestBody = String(data: data, encoding: .utf8) ?? "<unable to decode>"
            logger.debug("Request Body: \(requestBody)")
        } else {
            logger.debug("Request Body: <no data>")
        }
        logger.debug("Response code: \(response.statusCode)")
        let headerFields = response.allHeaderFields as? [String: Any]
        if let respHeaders = headerFields?.prettify() {
            logger.debug("Response Headers: \(respHeaders)")
        } else {
            logger.debug("Response Headers: CAN NOT DECODE")
        }
        if let data = data {
            let responseBody = String(data: data, encoding: .utf8) ?? "<unable to decode>"
            logger.debug("Response Body: \(responseBody)")
        } else {
            logger.debug("Response Body: <no data>")
        }
    }
    
    private func responseSize(response: URLResponse?) -> Int {
        guard let httpResponse = response as? HTTPURLResponse else {
            return -1
        }
        guard let lengthStr = httpResponse.allHeaderFields["Content-Length"] as? String  else {
            return -2
        }
        let length = Int(lengthStr) ?? -3
        return length
    }
    
    func validate(data: Data?,
                  response urlResponse: URLResponse?,
                  request: URLRequest) -> ValidationResult {
        let result = performValidation(data: data, response: urlResponse, request: request)
        
        let maxSize = maxHttpResponseSize
        let responseTooBig = (responseSize(response: urlResponse) > maxSize)
        
        let shouldDebug = result.needsDebug || debugAllHttp || responseTooBig
        if shouldDebug {
            performDebug(data: data, response: urlResponse, request: request)
        }
        
        return result
    }
    
}
