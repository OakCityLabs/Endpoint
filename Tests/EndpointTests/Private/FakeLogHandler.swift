//
//  FakeLogHandler.swift
//  EndpointTests
//
//  Created by Jay Lyerly on 11/4/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import Foundation
import Logging
import XCTest

struct LogRecord: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(level): \(message) -- \(file):\(function):\(line)"
    }
    
    let level: Logger.Level
    let message: Logger.Message
    let metadata: Logger.Metadata?
    let file: String
    let function: String
    let line: UInt
    
}

extension LogRecord: Equatable {}

class FakeLogStorage {
    static var shared = FakeLogStorage()

    private var records = [LogRecord]()
    
    func clear() {
        records = []
    }
    
    func append(logRecord: LogRecord) {
        records.append(logRecord)
    }
    
    func assertMessageContains(level: Logger.Level, message: String, file: String?, function: String?) {
        for record in records {
            if record.level == level, record.message.description.contains(message) {
                if let file = file, record.file != file {
                    // skip if file is specified and doesn't match
                    continue
                }
                if let function = function, record.function != function {
                    // skip if function is specified and doesn't match
                    continue
                }
                return
            }
        }
        XCTFail("Message: \(message) not found in LogStorage at log level: \(level)")
    }
    
    func assertMessageDoesNotContain(level: Logger.Level, message: String, file: String?, function: String?) {
        for record in records {
            if record.level == level, record.message.description.contains(message) {
                if let file = file, record.file != file {
                    // skip if file is specified and doesn't match
                    continue
                }
                if let function = function, record.function != function {
                    // skip if function is specified and doesn't match
                    continue
                }
                XCTFail("Message: \(message) was NOT expected to be found at log level: \(level)")
            }
        }
    }
    
    
    func assertMatches(level: Logger.Level, message: String) {
        let msg = Logger.Message(stringLiteral: message)
        records.forEach { (record) in
            if record.level == level && record.message == msg {
                return
            }
        }
        XCTFail("Message: \(message) not found in LogStorage at log level: \(level)")
    }
}

struct FakeLogHandler: LogHandler {
    var metadata = Logger.Metadata()
    var logLevel: Logger.Level = .trace
    
    static func factory(label: String) -> FakeLogHandler {
        return globalFakeLogHandler
    }
    
    static func install() {
        // We need to register this thing once.
        LoggingSystem.bootstrap { (_) -> LogHandler in
            return FakeLogHandler()
        }
    }
    
    static let globalFakeLogHandler: FakeLogHandler = {
       return FakeLogHandler()
    }()
    
    // swiftlint:disable:next function_parameter_count
    func log(level: Logger.Level,
             message: Logger.Message,
             metadata: Logger.Metadata?,
             file: String,
             function: String,
             line: UInt) {
        FakeLogStorage.shared.append(logRecord: LogRecord(level: level,
                                                          message: message,
                                                          metadata: metadata,
                                                          file: NSString(string: file).lastPathComponent,
                                                          function: function,
                                                          line: line))
    }
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return metadata[metadataKey]
        }
        set(newValue) {
            metadata[metadataKey] = newValue
        }
    }
    
}
