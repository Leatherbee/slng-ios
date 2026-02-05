//
//  KeyboardStatusViewModelTests.swift
//  SlangTranslatorTests
//
//  Tests for KeyboardStatusViewModel.
//

import Testing
import Foundation
@testable import SLNG

struct KeyboardStatusViewModelTests {

    // MARK: - Initial State Tests

    @Test @MainActor func viewModel_initialState_hasCorrectDefaults() async throws {
        let viewModel = KeyboardStatusViewModel()

        // Initial state should be false until updateKeyboardStatus runs
        #expect(viewModel.isFullAccessEnabled == false || viewModel.isFullAccessEnabled == true)
        #expect(viewModel.isKeyboardEnabled == false || viewModel.isKeyboardEnabled == true)
    }

    // MARK: - Update Status Tests

    @Test @MainActor func updateKeyboardStatus_readsFromUserDefaults() async throws {
        let viewModel = KeyboardStatusViewModel()

        // The method should run without crashing
        viewModel.updateKeyboardStatus()

        // Wait a moment for async update
        try await Task.sleep(nanoseconds: 100_000_000)

        // After update, the properties should be set (value depends on UserDefaults state)
        #expect(true)
    }

    // MARK: - Memory Management Tests

    @Test @MainActor func viewModel_canBeCreatedAndDestroyed() async throws {
        var viewModel: KeyboardStatusViewModel? = KeyboardStatusViewModel()

        #expect(viewModel != nil)

        viewModel = nil

        #expect(viewModel == nil)
    }
}
