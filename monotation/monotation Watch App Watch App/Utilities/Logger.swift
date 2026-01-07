//
//  Logger.swift
//  monotation Watch App
//
//  Detailed logging utility for debugging countdown issues
//

import Foundation
import OSLog

@MainActor
class Logger {
    static let shared = Logger()
    
    private let logger = OSLog(subsystem: "com.monotation.watch", category: "Countdown")
    private let logFileURL: URL?
    
    private init() {
        // Create log file in Documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            logFileURL = documentsPath.appendingPathComponent("countdown_debug.log")
            // Clear previous log
            try? FileManager.default.removeItem(at: logFileURL!)
        } else {
            logFileURL = nil
        }
    }
    
    private func log(_ level: String, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level)] [\(fileName):\(line)] \(function) - \(message)"
        
        // Print to console
        print(logMessage)
        
        // Log to OSLog
        let osLogType: OSLogType
        switch level {
        case "ERROR": osLogType = .error
        case "WARN": osLogType = .default
        case "INFO": osLogType = .info
        case "DEBUG": osLogType = .debug
        default: osLogType = .default
        }
        os_log("%{public}@", log: logger, type: osLogType, logMessage)
        
        // Write to file
        if let url = logFileURL {
            if let data = (logMessage + "\n").data(using: .utf8) {
                if FileManager.default.fileExists(atPath: url.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: url) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: url)
                }
            }
        }
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("ERROR", message, file: file, function: function, line: line)
    }
    
    func warn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("WARN", message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("INFO", message, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log("DEBUG", message, file: file, function: function, line: line)
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

