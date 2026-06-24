//
//  Logger.swift
//  SlangTranslator
//
//  Centralized logging framework to replace scattered print() statements.
//  Supports log levels, categories, and can be disabled in production.
//

import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var prefix: String {
        switch self {
        case .debug: return "[DEBUG]"
        case .info: return "[INFO]"
        case .warning: return "[WARNING]"
        case .error: return "[ERROR]"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

enum LogCategory: String {
    case general = "General"
    case translation = "Translation"
    case speechToText = "STT"
    case audio = "Audio"
    case haptic = "Haptic"
    case data = "Data"
    case network = "Network"
    case ui = "UI"
    case keyboard = "Keyboard"
    case analytics = "Analytics"
    case notifications = "Notifications"
    case liveActivity = "LiveActivity"

    var osLog: OSLog {
        OSLog(subsystem: Logger.subsystem, category: rawValue)
    }
}

final class Logger {
    static let shared = Logger()

    static let subsystem = Bundle.main.bundleIdentifier ?? "com.slng.app"

    #if DEBUG
    var minimumLevel: LogLevel = .debug
    var isEnabled: Bool = true
    #else
    var minimumLevel: LogLevel = .warning
    var isEnabled: Bool = false
    #endif

    private init() {}

    func log(
        _ message: @autoclosure () -> String,
        level: LogLevel = .debug,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard isEnabled, level >= minimumLevel else { return }

        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(category.rawValue)] \(fileName):\(line) \(function) - \(message())"

        #if DEBUG
        print("\(level.prefix) \(logMessage)")
        #endif

        os_log("%{public}@", log: category.osLog, type: level.osLogType, logMessage)
    }

    // MARK: - Convenience Methods

    func debug(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .debug, category: category, file: file, function: function, line: line)
    }

    func info(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .info, category: category, file: file, function: function, line: line)
    }

    func warning(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .warning, category: category, file: file, function: function, line: line)
    }

    func error(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message(), level: .error, category: category, file: file, function: function, line: line)
    }
}

// MARK: - Global Convenience Functions

func logDebug(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.debug(message(), category: category, file: file, function: function, line: line)
}

func logInfo(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.info(message(), category: category, file: file, function: function, line: line)
}

func logWarning(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.warning(message(), category: category, file: file, function: function, line: line)
}

func logError(
    _ message: @autoclosure () -> String,
    category: LogCategory = .general,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.error(message(), category: category, file: file, function: function, line: line)
}
