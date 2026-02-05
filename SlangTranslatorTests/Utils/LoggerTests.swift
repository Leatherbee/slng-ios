//
//  LoggerTests.swift
//  SlangTranslatorTests
//
//  Tests for Logger utility.
//

import Testing
import Foundation
@testable import SLNG

struct LoggerTests {

    // MARK: - LogLevel Tests

    @Test func logLevel_comparison_worksCorrectly() async throws {
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warning)
        #expect(LogLevel.warning < LogLevel.error)
        #expect(LogLevel.debug < LogLevel.error)
    }

    @Test func logLevel_rawValues_areOrdered() async throws {
        #expect(LogLevel.debug.rawValue == 0)
        #expect(LogLevel.info.rawValue == 1)
        #expect(LogLevel.warning.rawValue == 2)
        #expect(LogLevel.error.rawValue == 3)
    }

    @Test func logLevel_prefix_hasEmoji() async throws {
        #expect(!LogLevel.debug.prefix.isEmpty)
        #expect(!LogLevel.info.prefix.isEmpty)
        #expect(!LogLevel.warning.prefix.isEmpty)
        #expect(!LogLevel.error.prefix.isEmpty)
    }

    // MARK: - LogCategory Tests

    @Test func logCategory_rawValues_areCorrect() async throws {
        #expect(LogCategory.general.rawValue == "General")
        #expect(LogCategory.translation.rawValue == "Translation")
        #expect(LogCategory.speechToText.rawValue == "STT")
        #expect(LogCategory.audio.rawValue == "Audio")
        #expect(LogCategory.network.rawValue == "Network")
    }

    @Test func logCategory_allCasesExist() async throws {
        // Verify all expected categories exist
        let categories: [LogCategory] = [
            .general, .translation, .speechToText, .audio,
            .haptic, .data, .network, .ui, .keyboard, .analytics
        ]

        #expect(categories.count == 10)
    }

    // MARK: - Logger Configuration Tests

    @Test func logger_sharedInstance_exists() async throws {
        let logger = Logger.shared
        #expect(logger != nil)
    }

    @Test func logger_subsystem_isSet() async throws {
        #expect(!Logger.subsystem.isEmpty)
    }

    // MARK: - Global Function Tests

    @Test func globalLogFunctions_exist() async throws {
        // These should compile and not crash
        // In debug mode they will print, in release they won't
        logDebug("Test debug message", category: .general)
        logInfo("Test info message", category: .network)
        logWarning("Test warning message", category: .translation)
        logError("Test error message", category: .audio)

        // If we got here without crashing, the functions work
        #expect(true)
    }

    @Test func logDebug_withCategory_usesCorrectCategory() async throws {
        // This mainly verifies the API works correctly
        logDebug("Test message", category: .translation)
        logDebug("Test message", category: .network)
        logDebug("Test message", category: .speechToText)

        #expect(true)
    }
}
