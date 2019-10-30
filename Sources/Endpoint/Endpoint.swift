//
//  Endpoint.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

class Endpoint<Payload> {
    let serverUrl: URL?
    let pathPrefix: String
    let pathSuffix: String?
    let objId: String?
    let method: HTTPMethod
    let queryParams: [String: String]
    let formParams: [String: String]
    let jsonParams: [String: Any]
    let mimeTypes: [String]
    let contentType: String?
    let statusCodes: [Int]
    let username: String?
    let password: String?
    let body: Data?
    let dateFormatter: DateFormatter
    
    var jsonBody: Data? {
        guard !jsonParams.isEmpty else {
            return nil
        }
        guard method == .post || method == .patch else {
            return nil
        }
        
        let options: JSONSerialization.WritingOptions = [.sortedKeys]
        
        return try? JSONSerialization.data(withJSONObject: jsonParams, options: options)
    }
    
    var formBody: Data? {
        guard !formParams.isEmpty else {
            return nil
        }
        guard method == .post || method == .patch else {
            return nil
        }
        
        let parameterArray = formParams.map { (arg) -> String in
            let (key, value) = arg
            return "\(key)=\(value.percentEscaped)"
        }
        let body = parameterArray.joined(separator: "&").data(using: .utf8)
        return body
    }
    
    var paging: Bool {
        return Payload.self is EndpointPageable.Type
    }
    
    var perPage: Int {
        guard let pageableClass = Payload.self as? EndpointPageable.Type else {
            return 0
        }
        return pageableClass.perPage
    }
    
    init(serverUrl: URL?,
         pathPrefix: String,
         method: HTTPMethod = .get,
         objId: String? = nil,
         pathSuffix: String? = nil,
         queryParams: [String: String] = [:],
         formParams: [String: String] = [:],
         jsonParams: [String: Any] = [:],
         mimeTypes: [String] = ["application/json"],
         contentType: String? = nil,
         statusCodes: [Int] = Array(200..<300),
         username: String? = nil,
         password: String? = nil,
         body: Data? = nil,
         dateFormatter: DateFormatter? = nil
        ) {
        self.serverUrl = serverUrl
        self.pathPrefix = pathPrefix
        self.objId = objId
        self.pathSuffix = pathSuffix
        self.method = method
        self.queryParams = queryParams
        self.formParams = formParams
        self.jsonParams = jsonParams
        self.mimeTypes = mimeTypes
        self.contentType = contentType
        self.statusCodes = statusCodes
        self.username = username
        self.password = password
        self.body = body
        self.dateFormatter = dateFormatter ?? .iso8601Full
    }
    
    func parse(data: Data, page: Int = 0) -> Payload? {
        return nil
    }
    
    private func addPath(toUrl baseUrl: URL) -> URL {
        var url = baseUrl
        if !pathPrefix.isEmpty {
            url.appendPathComponent(pathPrefix)
        }
        
        if let objId = objId {
            url.appendPathComponent("\(objId)")
        }
        if let pathSuffix = pathSuffix {
            url.appendPathComponent(pathSuffix)
        }
        
        return url
    }
    
    func requestQueryParams(page: Int = 0) -> [String: String] {
        var qParams = queryParams
        if paging {
            let pageParams = [
                "page_size": "\(perPage)",
                "page_number": "\(page)"
            ]
            qParams = pageParams.merging(qParams) { (_, new) in new }
        }
        return qParams
    }
    
    func requestEncodedQueryParams(forQueryParams qParams: [String: String]) -> [URLQueryItem] {
        let percentEncodedQueryItems: [URLQueryItem] = qParams.map { arg in
            let (key, value) = arg
            return URLQueryItem(name: key, value: "\(value)".percentEscaped)
        }

        return percentEncodedQueryItems
    }
    
    
    func urlRequest(baseUrl: URL, page: Int = 0, extraHeaders: [String: String] = [:]) -> URLRequest? {
        
        let url = addPath(toUrl: baseUrl)
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        var qParams = requestQueryParams(page: page)
        components.percentEncodedQueryItems = requestEncodedQueryParams(forQueryParams: qParams)

        FIXME -- continue to break this stuff out
        
        guard let cUrl = components.url else {
            assertionFailure("Failed to get URL from components.")
            return nil
        }
        
        var headers = extraHeaders
        headers ["Accept-Encoding"] = "gzip"
        
        if (method == .post || method == .patch) && contentType == nil {
            headers["Content-Type"] = formBody != nil ? "application/x-www-form-urlencoded" : "application/json"
        }
        if let contentType = contentType {
            headers["Content-Type"] = contentType
        }
        
        // Basic auth
        if let username = username,
            let loginData = "\(username):\(password ?? "")".data(using: .utf8) {
            let base64LoginData = loginData.base64EncodedString()
            headers["Authorization"] = "Basic \(base64LoginData)"
        }
        
        var req = URLRequest(url: cUrl)
        req.httpMethod = method.rawValue
        req.allHTTPHeaderFields = headers
        
        if let body = body {
            req.httpBody = body
        } else if let formBody = formBody {
            req.httpBody = formBody
        } else {
            req.httpBody = jsonBody
        }
        
        return req
    }
}

extension Endpoint: Equatable {}
