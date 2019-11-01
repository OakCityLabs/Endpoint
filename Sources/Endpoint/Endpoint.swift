//
//  Endpoint.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

public class Endpoint<Payload> {
    public let serverUrl: URL?
    public let pathPrefix: String
    public let pathSuffix: String?
    public let objId: String?
    public let method: EndpointHttpMethod
    public let queryParams: [String: String]
    public let formParams: [String: String]
    public let jsonParams: [String: Any]
    public let mimeTypes: [String]
    public let contentType: String?
    public let statusCodes: [Int]
    public let username: String?
    public let password: String?
    public let body: Data?
    public let dateFormatter: DateFormatter
    
    public var jsonBody: Data? {
        guard !jsonParams.isEmpty else {
            return nil
        }
        guard method == .post || method == .patch else {
            return nil
        }
        
        let options: JSONSerialization.WritingOptions = [.sortedKeys]
        
        return try? JSONSerialization.data(withJSONObject: jsonParams, options: options)
    }
    
    public var formBody: Data? {
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
    
    public var paging: Bool {
        return Payload.self is EndpointPageable.Type
    }
    
    public init(serverUrl: URL?,
                pathPrefix: String,
                method: EndpointHttpMethod = .get,
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
                dateFormatter: DateFormatter? = nil) {
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
    
    public func parse(data: Data, page: Int = 0) -> Payload? {
        return nil
    }
    
    public var url: URL? {
        guard let serverUrl = serverUrl else {
            return nil
        }
        var url = serverUrl
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
    
    public func requestQueryParams(page: Int = 0) -> [String: String]? {
        guard !queryParams.isEmpty else {
            return nil
        }
        var qParams = queryParams
        if let pageableClass = Payload.self as? EndpointPageable.Type {
            let pageParams = [
                pageableClass.perPageLabel: "\(pageableClass.perPage)",
                pageableClass.pageLabel: "\(page)"
            ]
            qParams = pageParams.merging(qParams) { (_, new) in new }
        }
        return qParams
    }
    
    public func requestEncodedQueryParams(forQueryParams qParams: [String: String]?) -> [URLQueryItem]? {
        guard let qParams = qParams else {
            return nil
        }
        let percentEncodedQueryItems: [URLQueryItem] = qParams.map { arg in
            let (key, value) = arg
            return URLQueryItem(name: key, value: "\(value)".percentEscaped)
        }

        return percentEncodedQueryItems
    }
    
    public var authorizationHeader: String? {
        // Basic auth
        if let username = username,
            let loginData = "\(username):\(password ?? "")".data(using: .utf8) {
            let base64LoginData = loginData.base64EncodedString()
            return "Basic \(base64LoginData)"
        }
        return nil
    }
    
    public func urlRequest(page: Int = 0, extraHeaders: [String: String] = [:]) -> URLRequest? {
        
        guard let url = url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let qParams = requestQueryParams(page: page)
        components.percentEncodedQueryItems = requestEncodedQueryParams(forQueryParams: qParams)
        
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
        
        headers["Authorization"] = authorizationHeader
        
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
    
    // This is a hack to provide a hook for comparing subclasses since the compiler
    // doesn't seem to like overriding === in a concrete subclass of a generic
    public func compareEquality(rhs: Endpoint<Payload>) -> Bool {
        return true
    }
}

extension Endpoint: Equatable {
    public static func ==<Payload>(lhs: Endpoint<Payload>, rhs: Endpoint<Payload>) -> Bool {
        return (lhs.serverUrl == rhs.serverUrl)
            && (lhs.pathPrefix == rhs.pathPrefix)
            && (lhs.pathSuffix == rhs.pathSuffix)
            && (lhs.objId == rhs.objId)
            && (lhs.method == rhs.method)
            && (lhs.queryParams == rhs.queryParams)
            && (lhs.formParams == rhs.formParams)
            && (lhs.jsonBody == rhs.jsonBody)
            && (lhs.mimeTypes == rhs.mimeTypes)
            && (lhs.contentType == rhs.contentType)
            && (lhs.statusCodes == rhs.statusCodes)
            && (lhs.username == rhs.username)
            && (lhs.password == rhs.password)
            && (lhs.body == rhs.body)
            && (lhs.dateFormatter == rhs.dateFormatter)
            && lhs.compareEquality(rhs: rhs)
    }
}
