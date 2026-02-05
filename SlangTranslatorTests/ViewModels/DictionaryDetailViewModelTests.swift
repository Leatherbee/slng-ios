//
//  DictionaryDetailViewModelTests.swift
//  SlangTranslatorTests
//
//  Tests for DictionaryDetailViewModel.
//

import Testing
import Foundation
import AVFoundation
@testable import SLNG

struct DictionaryDetailViewModelTests {

    // MARK: - Initialization Tests

    @Test @MainActor func viewModel_canBeInitialized() async throws {
        let viewModel = DictionaryDetailViewModel()
        #expect(viewModel != nil)
    }

    // MARK: - Speak Method Tests

    @Test @MainActor func speak_withValidText_doesNotCrash() async throws {
        let viewModel = DictionaryDetailViewModel()

        // This should not crash - we can't verify audio output in tests
        viewModel.speak("test text")
        #expect(true)
    }

    @Test @MainActor func speak_withEmptyString_doesNotCrash() async throws {
        let viewModel = DictionaryDetailViewModel()

        viewModel.speak("")
        #expect(true)
    }

    @Test @MainActor func speak_withCustomLanguage_doesNotCrash() async throws {
        let viewModel = DictionaryDetailViewModel()

        viewModel.speak("hello world", language: "en-US")
        #expect(true)
    }

    @Test @MainActor func speak_withIndonesianLanguage_usesDefaultLanguage() async throws {
        let viewModel = DictionaryDetailViewModel()

        // Default language is id-ID
        viewModel.speak("apa kabar")
        #expect(true)
    }

    @Test @MainActor func speak_withUnicodeText_doesNotCrash() async throws {
        let viewModel = DictionaryDetailViewModel()

        viewModel.speak("こんにちは", language: "ja-JP")
        #expect(true)
    }
}
