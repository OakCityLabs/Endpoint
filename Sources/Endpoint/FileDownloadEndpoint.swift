//
//  FileDownloadEndpoint.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

public enum FileDownloadError: Error {
    case writeDataError
}

public class FileDownloadEndpoint: Endpoint<URL> {
    
    override public var paging: Bool {         // files don't page
        return false
    }
    
    let destination: URL
    
    public init(destination: URL,
                serverUrl: URL?,
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
        
        self.destination = destination
        
        super.init(serverUrl: serverUrl,
                   pathPrefix: pathPrefix,
                   method: method,
                   objId: objId,
                   pathSuffix: pathSuffix,
                   queryParams: queryParams,
                   formParams: formParams,
                   jsonParams: jsonParams,
                   mimeTypes: mimeTypes,
                   contentType: contentType,
                   statusCodes: statusCodes,
                   username: username,
                   password: password,
                   body: body,
                   dateFormatter: dateFormatter)
    }
    
    override public func parse(data: Data, page: Int = 0) throws -> URL {
        let directory = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        try data.write(to: destination, options: [.atomic])
        return destination
    }
    
    public override func compareEquality(rhs: Endpoint<URL>) -> Bool {
        guard let rhs = rhs as? FileDownloadEndpoint else {
            return false
        }
        return destination == rhs.destination
    }
    
}
