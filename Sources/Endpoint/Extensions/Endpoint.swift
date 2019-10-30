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
}

extension Endpoint: Equatable {
    static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        return (lhs.pathPrefix == rhs.pathPrefix)
            && (lhs.pathSuffix == rhs.pathSuffix)
            && (lhs.objId == rhs.objId)
            && (lhs.method == rhs.method)
            && (lhs.queryParams == rhs.queryParams)
            && (lhs.formParams == rhs.formParams)
            && (lhs.jsonBody == rhs.jsonBody)
            && (lhs.mimeTypes == rhs.mimeTypes)
            && (lhs.statusCodes == rhs.statusCodes)
            && (lhs.username == rhs.username)
            && (lhs.password == rhs.password)
            && (lhs.body == rhs.body)
            && (lhs.dateFormatter == rhs.dateFormatter)
    }
}
