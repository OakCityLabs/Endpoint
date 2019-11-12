//
//  DispatchQueue.swift
//  Endpoint
//
//  Created by Jay Lyerly on 11/12/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    // This is useful for testing and keeps things sequential if called from
    // the main thread already.
    static func performOnMainThread(closure: @escaping () -> Void) {
        if Thread.isMainThread {
            closure()
        } else {
            DispatchQueue.main.async(execute: closure)
        }
    }
    
}
