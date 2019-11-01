//
//  JsonResponseValidator.swift
//  Endpoint
//
//  Created by Jay Lyerly on 11/01/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation
import Logging

class JsonResponseValidator<ServerError: EndpointServerError>: HttpResponseValidator<ServerError> {
    
    init(serverErrorType: ServerError.Type,
         logger: Logger = Logger(label: "com.oakcity.endpoint.jsonresponsevalidator")) {
        super.init(serverErrorType: serverErrorType, logger: logger, acceptedMimeTypes: ["application/json"])
    }
}
