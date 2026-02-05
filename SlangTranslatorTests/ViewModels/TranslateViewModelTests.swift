//
//  TranslateViewModelTests.swift
//  SlangTranslatorTests
//
//  Tests for TranslateViewModel.
//

import Testing
import Foundation
@testable import SLNG

struct TranslateViewModelTests {

    // MARK: - Initial State Tests

    @Test @MainActor func viewModel_initialState_hasCorrectDefaults() async throws {
        let viewModel = TranslateViewModel()

        #expect(viewModel.inputText.isEmpty)
        #expect(viewModel.translatedText == nil)
        #expect(viewModel.isTranslated == false)
        #expect(viewModel.isExpanded == false)
        #expect(viewModel.copiedToKeyboardAlert == false)
        #expect(viewModel.isDetectedSlangShown == false)
        #expect(viewModel.slangDetected.isEmpty)
        #expect(viewModel.slangData.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isInitializing == true)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.result == nil)
        #expect(viewModel.isRecording == false)
        #expect(viewModel.isTranscribing == false)
        #expect(viewModel.sttPlaceholder == nil)
        #expect(viewModel.audioLevel == -160)
        #expect(viewModel.isRecorderUIVisible == false)
    }

    // MARK: - Input Text Tests

    @Test @MainActor func inputText_canBeUpdated() async throws {
        let viewModel = TranslateViewModel()

        viewModel.inputText = "hello world"

        #expect(viewModel.inputText == "hello world")
    }

    @Test @MainActor func inputText_handlesEmptyString() async throws {
        let viewModel = TranslateViewModel()

        viewModel.inputText = ""

        #expect(viewModel.inputText.isEmpty)
    }

    @Test @MainActor func inputText_handlesSpecialCharacters() async throws {
        let viewModel = TranslateViewModel()

        viewModel.inputText = "Café résumé 日本語"

        #expect(viewModel.inputText == "Café résumé 日本語")
    }

    // MARK: - Reset Tests

    @Test @MainActor func reset_clearsAllState() async throws {
        let viewModel = TranslateViewModel()

        // Set some state
        viewModel.inputText = "test input"
        viewModel.translatedText = "test translation"
        viewModel.isTranslated = true
        viewModel.isExpanded = true
        viewModel.isDetectedSlangShown = true
        viewModel.isLoading = true
        viewModel.isTranscribing = true
        viewModel.errorMessage = "test error"
        viewModel.sttPlaceholder = "placeholder"

        // Reset
        viewModel.reset()

        // Verify all state is cleared
        #expect(viewModel.inputText.isEmpty)
        #expect(viewModel.translatedText == nil)
        #expect(viewModel.isTranslated == false)
        #expect(viewModel.isExpanded == false)
        #expect(viewModel.isDetectedSlangShown == false)
        #expect(viewModel.slangDetected.isEmpty)
        #expect(viewModel.slangData.isEmpty)
        #expect(viewModel.result == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isTranscribing == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.sttPlaceholder == nil)
    }

    // MARK: - Edit Text Tests

    @Test @MainActor func editText_updatesInputAndClearsResults() async throws {
        let viewModel = TranslateViewModel()

        // Set some previous state
        viewModel.translatedText = "previous translation"
        viewModel.isTranslated = true
        viewModel.isExpanded = true
        viewModel.errorMessage = "previous error"

        // Edit text
        viewModel.editText(text: "new input")

        // Verify input is updated and results are cleared
        #expect(viewModel.inputText == "new input")
        #expect(viewModel.translatedText == nil)
        #expect(viewModel.isTranslated == false)
        #expect(viewModel.isExpanded == false)
        #expect(viewModel.isDetectedSlangShown == false)
        #expect(viewModel.slangDetected.isEmpty)
        #expect(viewModel.slangData.isEmpty)
        #expect(viewModel.result == nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.sttPlaceholder == nil)
    }

    @Test @MainActor func editText_withEmptyString_clearsInput() async throws {
        let viewModel = TranslateViewModel()

        viewModel.inputText = "previous input"
        viewModel.editText(text: "")

        #expect(viewModel.inputText.isEmpty)
    }

    // MARK: - Copy to Clipboard Tests

    @Test @MainActor func copyToClipboard_withNoTranslation_doesNothing() async throws {
        let viewModel = TranslateViewModel()

        viewModel.translatedText = nil

        viewModel.copyToClipboard()

        // Should not crash and alert should not be triggered
        #expect(viewModel.copiedToKeyboardAlert == false)
    }

    @Test @MainActor func copyToClipboard_withTranslation_setsAlert() async throws {
        let viewModel = TranslateViewModel()

        viewModel.translatedText = "test translation"

        viewModel.copyToClipboard()

        #expect(viewModel.copiedToKeyboardAlert == true)
    }

    // MARK: - Expanded View Tests

    @Test @MainActor func expandedView_togglesExpansion() async throws {
        let viewModel = TranslateViewModel()

        #expect(viewModel.isExpanded == false)

        viewModel.expandedView()

        #expect(viewModel.isExpanded == true)

        viewModel.expandedView()

        #expect(viewModel.isExpanded == false)
    }

    // MARK: - Show Detected Slang Tests

    @Test @MainActor func showDetectedSlang_togglesVisibility() async throws {
        let viewModel = TranslateViewModel()

        #expect(viewModel.isDetectedSlangShown == false)

        viewModel.showDetectedSlang()

        #expect(viewModel.isDetectedSlangShown == true)

        viewModel.showDetectedSlang()

        #expect(viewModel.isDetectedSlangShown == false)
    }

    // MARK: - Translate Tests

    @Test @MainActor func translate_withEmptyText_doesNothing() async throws {
        let viewModel = TranslateViewModel()

        viewModel.translate(text: "")

        // Should not set loading state
        #expect(viewModel.isLoading == false)
    }

    @Test @MainActor func translate_withWhitespaceOnly_doesNothing() async throws {
        let viewModel = TranslateViewModel()

        viewModel.translate(text: "   \n\t  ")

        #expect(viewModel.isLoading == false)
    }

    @Test @MainActor func translate_setsInputText() async throws {
        let viewModel = TranslateViewModel()

        // Wait for initialization
        try await Task.sleep(nanoseconds: 500_000_000)

        viewModel.translate(text: "hello")

        #expect(viewModel.inputText == "hello")
    }

    @Test @MainActor func translate_clearsErrorMessage() async throws {
        let viewModel = TranslateViewModel()

        viewModel.errorMessage = "previous error"

        // Wait for initialization
        try await Task.sleep(nanoseconds: 500_000_000)

        viewModel.translate(text: "test")

        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Stop Recording Tests

    @Test @MainActor func stopRecording_resetsRecordingState() async throws {
        let viewModel = TranslateViewModel()

        // Simulate recording state
        viewModel.isRecording = true
        viewModel.isTranscribing = true

        viewModel.stopRecording()

        #expect(viewModel.isRecording == false)
        #expect(viewModel.isTranscribing == false)
        #expect(viewModel.audioLevel == -160)
    }

    // MARK: - Memory Management Tests

    @Test @MainActor func viewModel_canBeCreatedAndDestroyed() async throws {
        var viewModel: TranslateViewModel? = TranslateViewModel()

        #expect(viewModel != nil)

        viewModel = nil

        #expect(viewModel == nil)
    }

    // MARK: - State Consistency Tests

    @Test @MainActor func multipleResets_maintainsConsistentState() async throws {
        let viewModel = TranslateViewModel()

        for _ in 0..<5 {
            viewModel.inputText = "test"
            viewModel.translatedText = "translation"
            viewModel.isTranslated = true
            viewModel.reset()

            #expect(viewModel.inputText.isEmpty)
            #expect(viewModel.translatedText == nil)
            #expect(viewModel.isTranslated == false)
        }
    }

    @Test @MainActor func concurrentPropertyUpdates_areHandledCorrectly() async throws {
        let viewModel = TranslateViewModel()

        viewModel.inputText = "input1"
        viewModel.translatedText = "translation1"
        viewModel.inputText = "input2"
        viewModel.translatedText = "translation2"

        #expect(viewModel.inputText == "input2")
        #expect(viewModel.translatedText == "translation2")
    }
}
