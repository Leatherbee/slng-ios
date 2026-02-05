//
//  SlangTranslatorTests.swift
//  SlangTranslatorTests
//
//  Main test file - imports all test modules.
//

import Testing
@testable import SLNG

// This file serves as the main entry point for the test suite.
// Individual tests are organized in their respective files:
//
// - Utils/BackendClientTests.swift - Network client and retry logic tests
// - Utils/LoggerTests.swift - Logging framework tests
// - Extensions/StringSlangNormalizationTests.swift - String extension tests
// - Models/SlangDataTests.swift - SlangData model tests
// - Models/TranslationDataTests.swift - Translation model tests
// - UseCases/TranslateSentenceUseCaseTests.swift - Use case tests
// - ViewModels/TranslateViewModelTests.swift - TranslateViewModel tests
// - ViewModels/DictionaryViewModelTests.swift - DictionaryViewModel tests
// - ViewModels/DictionaryDetailViewModelTests.swift - DictionaryDetailViewModel tests
// - ViewModels/KeyboardStatusViewModelTests.swift - KeyboardStatusViewModel tests
// - Mocks/MockRepositories.swift - Mock implementations for testing
// - Mocks/MockURLProtocol.swift - Network mocking utility

struct SlangTranslatorTests {

    @Test func testModuleImport() async throws {
        // Verify the module can be imported
        #expect(true)
    }
}
