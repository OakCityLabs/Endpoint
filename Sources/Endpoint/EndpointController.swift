//
//  EndpointController.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation
import Logging

extension NSNotification.Name {
    static let endpointServerUnreachable = Notification.Name("EndpointServerUnreachable")    // Reachability failure
    static let endpointServerNotResponding = Notification.Name("EndpointServerNotResponding")    // Server not responding
}

public class EndpointController<ServerError: EndpointServerError> {
    
    private let session: URLSession
    private(set) var extraHeaders = [String: String]()
    private let logger: Logger
    private let reachability: Reachability
    
    public init(session: URLSession = URLSession(configuration: URLSessionConfiguration.default),
                serverErrorType: ServerError.Type,
                logger: Logger = Logger(label: "com.oakcity.endpoint.logger"),
                reachability: Reachability = Reachability()) {
        
        self.logger = logger
        self.reachability = reachability
        self.session = session
    }
    
    public func removeAuthToken() {
        extraHeaders.removeValue(forKey: "Authorization")
    }
    
    public func addAuthBearer(authToken: String) {
        logger.debug("Setting auth token to: \(authToken)")
        extraHeaders["Authorization"] = "Bearer \(authToken)"
    }
    
    public func reset(completion: (() -> Void)? = nil) {
        session.reset {
            completion?()
        }
    }
    
    public func load<Payload>(_ endpoint: Endpoint<Payload>,
                              page: Int = 0,
                              synchronous: Bool = false,
                              completion: @escaping (Result<Payload, Error>) -> Void) {
        
        guard reachability.isConnectedToNetwork() else {
            logger.info("Server is unreachable")
            completion(.failure(EndpointError.serverUnreachable))
            NotificationCenter.default.post(Notification(name: .endpointServerUnreachable))
            return
        }
        
        guard let serverUrl = endpoint.serverUrl,
            let req = endpoint.urlRequest(page: page, extraHeaders: extraHeaders) else {
                assertionFailure("Failed to create urlRequest in `load`")
                completion(.failure(EndpointError.urlRequestCreation))
                return
        }
        
        // If synchronous is requested, make a sempaphore
        let semaphore = synchronous ? DispatchSemaphore(value: 0) : nil
        
        session.dataTask(with: req) { data, urlResponse, error in
            defer {
                semaphore?.signal()
            }
            
            if let apiError = self.process(networkError: error) {
                completion(.failure(apiError))
                return
            }
            
            // print data: po String(data: data, encoding: .utf8)
            let validator = HttpResponseValidator(serverErrorType: ServerError.self,
                                                  logger: self.logger,
                                                  acceptedMimeTypes: endpoint.mimeTypes,
                                                  acceptedStatusCodes: endpoint.statusCodes)
            let validationResult = validator.validate(data: data,
                                                      response: urlResponse,
                                                      request: req)
            
            if case ValidationResult.failure(let error) = validationResult {
                completion(.failure(error))
                return
            }
            
            if let data = data, let obj = endpoint.parse(data: data) {
                completion(.success(obj))
            } else {
                completion(.failure(EndpointError.parseError))
            }
            
        }.resume()
        
        semaphore?.wait()
    }
    
    private func process(networkError error: Error?) -> EndpointError? {
        if let error = error as NSError?, error.code == NSURLErrorCancelled {
            return .requestCancelled
        }
        
        let connectionErrors = [
            NSURLErrorCannotFindHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorTimedOut,
            NSURLErrorNotConnectedToInternet
        ]
        if let error = error as NSError?, connectionErrors.contains(error.code) {
            logger.warning("Network connection error: \(error)")
            NotificationCenter.default.post(Notification(name: .endpointServerNotResponding))
            return .connectionError
        }
        if let error = error {
            logger.warning("Unknown network error: \(error)")
            return .unknownError
        }
        return nil
    }
}
