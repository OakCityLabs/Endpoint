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
    static let endpointServerNotResponding = Notification.Name("EndpointServerNotResponding")  // Server not responding
}

open class EndpointController<ServerError: EndpointServerError> {
    
    public let session: URLSession
    public let reachability: ReachabilityTester
    public let defaultServerUrl: URL?
    
    public let recordResponses = false
    
    private lazy var tmpDirectory: URL? = {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: tmpDir,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        } catch {
            logger.error("Failed to create temp dir at \(tmpDir)")
            return nil
        }
        let source = defaultServerUrl?.absoluteString ?? "server"
        logger.info("Recording responses from \(source) to \(tmpDir)")
        return tmpDir
    }()
    
    private(set) var extraHeaders = [String: String]()

    public var allHttpHeaders: [String: String] {
        return extraHeaders
    }
    
    private let logger = Logger(label: "com.oakcity.endpoint.logger")
    private let maxHttpResponseSize: Int
    
    /// Create an EndpointController instance
    /// - Parameters:
    ///   - session: (optional) URLSession to be used for network calls.  Unless a session is specified, one will
    ///   be created with the default config (URLSessionConfiguration.default)
    ///   - reachability: (optional) ReachabilityTester instance to use for testing network connectivity.  Unless
    ///   specified, one will be created
    ///   - defaultServerUrl: (optional) A server URL for generating an URLRequest for endpoints that have a nil
    ///   serverUrl of their own.
    ///   - maxHttpResponseSize: (optional) Integer value of the response size in bytes that will cause the
    ///   HttpRespnoseValidator to cause a warning.  The default is Int.max which effectively disables the warning.
    public init(defaultServerUrl: URL? = nil,
                session: URLSession = URLSession(configuration: URLSessionConfiguration.default),
                reachability: ReachabilityTester = ReachabilityTester(),
                maxHttpResponseSize: Int = Int.max) {
        
        self.reachability = reachability
        self.session = session
        self.defaultServerUrl = defaultServerUrl
        self.maxHttpResponseSize = maxHttpResponseSize
    }
    
    /// Remove a registered auth token
    open func removeAuthToken() {
        extraHeaders.removeValue(forKey: "Authorization")
    }
    
    /// Add an auth token to be used for all subsequent requests.  This creates an "Authorization" header with the
    /// value of "Bearer <AUTHTOKEN>" where <AUTHTOKEN> is the string supplied here.
    /// - Parameter authToken: String to be used as the <AUTHTOKEN> in the "Authorization" header
    open func addAuthBearer(authToken: String) {
        logger.debug("Setting auth token to: \(authToken)")
        extraHeaders["Authorization"] = "Bearer \(authToken)"
    }
    
    /// Reset the controller's URLSession.
    /// - Parameter completion: Completion block called when the reset is complete.
    open func reset(completion: (() -> Void)? = nil) {
        session.reset {
            completion?()
        }
    }
    
    /// Create the URLRequest associated with the given endpoint including an extra header information
    /// - Parameters:
    ///   - endpoint: Endpoint to create a URL from
    ///   - page: For pageable content, the page to retrieve
    open func urlRequest<Payload>(forEndpoint endpoint: Endpoint<Payload>, page: Int) -> URLRequest? {
        return endpoint.urlRequest(page: page, extraHeaders: allHttpHeaders, defaultServerUrl: defaultServerUrl)
    }
    
    /// Load data from an endpoint.
    /// - Parameters:
    ///   - endpoint: Endpoint object from which to load data
    ///   - page: (optional) For pageable content, the page to load.  The default value is page 1.
    ///   - synchronous: (optional) If synchronous is true, this method will not return until after the network
    ///   call has completed, including the completion block.  If false, the load method returns immediately after
    ///   queueing the network request.  The default if false.
    ///   - completion: (optional) This completion block is called after the network request is complete.  The
    ///   single argument is a Result object with either a Payload(.success) object or an Error(.failure).
    open func load<Payload>(_ endpoint: Endpoint<Payload>,
                            page: Int = 1,
                            synchronous: Bool = false,
                            completion: ((Result<Payload, Error>) -> Void)? = nil) {
        
        guard reachability.isConnectedToNetwork() else {
            logger.info("Server is unreachable")
            completion?(.failure(EndpointError.serverUnreachable))
            NotificationCenter.default.post(Notification(name: .endpointServerUnreachable))
            return
        }
        
        guard let req = urlRequest(forEndpoint: endpoint, page: page) else {
                assertionFailure("Failed to create urlRequest in `load`")
                completion?(.failure(EndpointError.urlRequestCreationError))
                return
        }
        
        // If synchronous is requested, make a sempaphore
        let semaphore = synchronous ? DispatchSemaphore(value: 0) : nil
        
        session.dataTask(with: req) { data, urlResponse, error in
            defer {
                semaphore?.signal()
            }
                        
            if let apiError = self.process(networkError: error, failSilently: endpoint.failSilently) {
                DispatchQueue.performOnMainThread { completion?(.failure(apiError)) }
                return
            }
            
            self.record(data: data, forResponse: urlResponse)

            // print data: po String(data: data, encoding: .utf8)
            let validator = HttpResponseValidator(serverErrorType: ServerError.self,
                                                  acceptedMimeTypes: endpoint.mimeTypes,
                                                  acceptedStatusCodes: endpoint.statusCodes,
                                                  maxHttpResponseSize: self.maxHttpResponseSize)
            let validationResult = validator.validate(data: data,
                                                      response: urlResponse,
                                                      request: req)
            
            if case ValidationResult.failure(let error) = validationResult {
                DispatchQueue.performOnMainThread { completion?(.failure(error)) }
                return
            }

            if let data = data {
                do {
                    let obj = try endpoint.parse(data: data)
                    DispatchQueue.performOnMainThread { completion?(.success(obj)) }
                } catch {
                    // endpoint.parse failed internally with error
                    DispatchQueue.performOnMainThread { completion?(.failure(error)) }
                    return
                }
            } else {
                DispatchQueue.performOnMainThread { completion?(.failure(EndpointError.parseError)) }
            }
            
        }.resume()
        
        semaphore?.wait()
    }
    
    /// Process a network error by mapping a raw error into an EndpointError object.
    /// - Parameter error: an error to process
    open func process(networkError error: Error?,
                      failSilently: Bool) -> EndpointError? {
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
            if !failSilently {
                logger.warning("Network connection error: \(error)")
            }
            NotificationCenter.default.post(Notification(name: .endpointServerNotResponding))
            return .connectionError
        }
        if let error = error {
            if !failSilently { logger.warning("Unknown network error: \(error)") }
            return .unknownError
        }
        return nil
    }
    
    open func record(data: Data?, forResponse response: URLResponse?) {
        guard recordResponses else { return }
        guard let data = data, let response = response else { return }       // nothing to record!
        
        guard let targetUrl = recordUrl(forResponse: response) else { return }
        do {
            try data.write(to: targetUrl)
        } catch {
            logger.error("Failed to log response data to \(targetUrl)")
        }
    }
    
    private func recordUrl(forResponse response: URLResponse) -> URL? {
        guard let url = response.url else { return nil }
        
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        guard let host = comps.host, let port = comps.port else { return nil }
        guard let tmpDirectory = tmpDirectory else { return nil }
        
        var count = 0
        let baseTmpUrl = tmpDirectory
            .appendingPathComponent("\(host)_\(port)")
            .appendingPathComponent(comps.path)
        
        var tmpUrl = baseTmpUrl.appendingPathExtension(".data")
                
        while FileManager.default.fileExists(atPath: tmpUrl.path) {
            tmpUrl = baseTmpUrl.appendingPathExtension("_\(count)").appendingPathExtension(".data")
            count += 1
        }
        return tmpUrl
    }
}
