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
    
    init(serverErrorType: ServerError.Type) {
        super.init(serverErrorType: serverErrorType, acceptedMimeTypes: ["application/json"])
    }
}
