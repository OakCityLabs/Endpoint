//
//  FileDownloadEndpoint.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

enum FileDownloadError: Error {
    case writeDataError
}

class FileDownloadEndpoint: Endpoint<URL> {
    
    override var paging: Bool {         // files don't page
        return false
    }
    
    let destination: URL
    
    init(destination: URL,
         serverUrl: URL?,
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
    
    override func parse(data: Data, page: Int = 0) -> URL? {
        do {
            let directory = destination.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directory,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
            try data.write(to: destination, options: [.atomic])
            return destination
        } catch {
            print("Failed to write data to file: \(destination)\nerror: \(error)")
            return nil
        }
    }
    
}
