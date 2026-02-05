//
//  DictionaryViewModelTests.swift
//  SlangTranslatorTests
//
//  Tests for DictionaryViewModel.
//

import Testing
import Foundation
@testable import SLNG

struct DictionaryViewModelTests {

    // MARK: - Initialization Tests

    @Test @MainActor func viewModel_initialState_hasEmptyData() async throws {
        let viewModel = DictionaryViewModel()

        #expect(viewModel.data.isEmpty)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.filtered.isEmpty)
        #expect(viewModel.activeLetter == nil)
        #expect(viewModel.isDraggingLetter == false)
        #expect(viewModel.canonicalGroups.isEmpty)
        #expect(viewModel.filteredCanonicals.isEmpty)
    }

    // MARK: - Search Text Tests

    @Test @MainActor func searchText_canBeUpdated() async throws {
        let viewModel = DictionaryViewModel()

        viewModel.searchText = "gak"

        #expect(viewModel.searchText == "gak")
    }

    @Test @MainActor func searchText_emptyString_isValid() async throws {
        let viewModel = DictionaryViewModel()

        viewModel.searchText = ""

        #expect(viewModel.searchText.isEmpty)
    }

    // MARK: - Letter Drag Tests

    @Test @MainActor func handleLetterDrag_setsActiveLetter() async throws {
        let viewModel = DictionaryViewModel()

        viewModel.handleLetterDrag("A")

        #expect(viewModel.activeLetter == "A")
        #expect(viewModel.isDraggingLetter == true)
    }

    @Test @MainActor func handleLetterDragEnd_resetsDraggingState() async throws {
        let viewModel = DictionaryViewModel()

        viewModel.handleLetterDrag("B")
        viewModel.handleLetterDragEnd()

        #expect(viewModel.isDraggingLetter == false)
        // activeLetter should still be set (not cleared on drag end)
        #expect(viewModel.activeLetter == "B")
    }

    @Test @MainActor func handleLetterDrag_multipleTimes_updatesActiveLetter() async throws {
        let viewModel = DictionaryViewModel()

        viewModel.handleLetterDrag("A")
        #expect(viewModel.activeLetter == "A")

        viewModel.handleLetterDrag("B")
        #expect(viewModel.activeLetter == "B")

        viewModel.handleLetterDrag("C")
        #expect(viewModel.activeLetter == "C")
    }

    // MARK: - Index For Letter Tests

    @Test @MainActor func indexForLetter_withEmptyData_returnsNil() async throws {
        let viewModel = DictionaryViewModel()

        let index = viewModel.indexForLetter("A")

        #expect(index == nil)
    }

    @Test @MainActor func indexForLetter_caseInsensitive() async throws {
        let viewModel = DictionaryViewModel()

        // Both uppercase and lowercase should work the same way
        let indexUpper = viewModel.indexForLetter("A")
        let indexLower = viewModel.indexForLetter("a")

        #expect(indexUpper == indexLower)
    }

    // MARK: - Load Data Tests

    @Test @MainActor func loadData_withoutContext_doesNotCrash() async throws {
        let viewModel = DictionaryViewModel()

        // Should handle gracefully when slangRepo is nil
        viewModel.loadData()

        #expect(viewModel.canonicalGroups.isEmpty)
    }

    // MARK: - Memory Management Tests

    @Test @MainActor func viewModel_canBeCreatedAndDestroyed() async throws {
        var viewModel: DictionaryViewModel? = DictionaryViewModel()

        #expect(viewModel != nil)

        viewModel = nil

        #expect(viewModel == nil)
    }
}
