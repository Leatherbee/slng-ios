//
//  MockRepositories.swift
//  SlangTranslatorTests
//
//  Mock implementations of repositories for testing.
//

import Foundation
@testable import SLNG

// MARK: - Mock Translation Repository

class MockTranslationRepository: TranslationRepository {
    var translateSentenceResult: Result<TranslationResponse, Error>?
    var cachedTranslation: TranslationResponse?
    var translateCallCount = 0
    var lastTranslateInput: String?

    func translateSentence(_ text: String) async throws -> TranslationResponse {
        translateCallCount += 1
        lastTranslateInput = text

        guard let result = translateSentenceResult else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock result set"])
        }

        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }

    func fetchCachedTranslation(for text: String) -> TranslationResponse? {
        return cachedTranslation
    }

    // MARK: - Helper Methods

    func mockSuccessResponse(
        originalText: String,
        englishTranslation: String,
        sentiment: SentimentType = .neutral,
        source: TranslationSource = .openAI
    ) {
        translateSentenceResult = .success(TranslationResponse(
            id: UUID(),
            originalText: originalText,
            englishTranslation: englishTranslation,
            sentiment: sentiment,
            source: source
        ))
    }

    func mockError(_ error: Error) {
        translateSentenceResult = .failure(error)
    }

    func reset() {
        translateSentenceResult = nil
        cachedTranslation = nil
        translateCallCount = 0
        lastTranslateInput = nil
    }
}

// MARK: - Mock Slang Repository

class MockSlangRepository: SlangRepository {
    var slangs: [SlangData] = []
    var loadAllCallCount = 0

    func loadAll() -> [SlangData] {
        loadAllCallCount += 1
        return slangs
    }

    // MARK: - Helper Methods

    func addSlang(
        canonicalForm: String,
        slang: String,
        translationEN: String,
        sentiment: SentimentType = .neutral
    ) {
        let slangData = SlangData(
            id: UUID(),
            canonicalForm: canonicalForm,
            canonicalPronunciation: canonicalForm,
            slang: slang,
            pronunciation: slang,
            translationID: "",
            translationEN: translationEN,
            contextID: "",
            contextEN: "",
            exampleID: "",
            exampleEN: "",
            sentiment: sentiment
        )
        slangs.append(slangData)
    }

    func addSlangWithVariants(
        canonicalForm: String,
        variants: [(slang: String, sentiment: SentimentType)]
    ) {
        for variant in variants {
            let slangData = SlangData(
                id: UUID(),
                canonicalForm: canonicalForm,
                canonicalPronunciation: canonicalForm,
                slang: variant.slang,
                pronunciation: variant.slang,
                translationID: "",
                translationEN: "translation",
                contextID: "",
                contextEN: "",
                exampleID: "",
                exampleEN: "",
                sentiment: variant.sentiment
            )
            slangs.append(slangData)
        }
    }

    func reset() {
        slangs = []
        loadAllCallCount = 0
    }
}

// MARK: - Test Data Factory

struct TestDataFactory {
    static func createSlangData(
        canonicalForm: String = "test",
        slang: String = "test",
        translationEN: String = "test translation",
        sentiment: SentimentType = .neutral
    ) -> SlangData {
        return SlangData(
            id: UUID(),
            canonicalForm: canonicalForm,
            canonicalPronunciation: canonicalForm,
            slang: slang,
            pronunciation: slang,
            translationID: "terjemahan",
            translationEN: translationEN,
            contextID: "konteks",
            contextEN: "context",
            exampleID: "contoh",
            exampleEN: "example",
            sentiment: sentiment
        )
    }

    static func createTranslationResponse(
        originalText: String = "test",
        englishTranslation: String = "test translation",
        sentiment: SentimentType = .neutral,
        source: TranslationSource = .openAI
    ) -> TranslationResponse {
        return TranslationResponse(
            id: UUID(),
            originalText: originalText,
            englishTranslation: englishTranslation,
            sentiment: sentiment,
            source: source
        )
    }

    // Common Indonesian slangs for testing
    static func createCommonSlangs() -> [SlangData] {
        return [
            createSlangData(canonicalForm: "gak", slang: "gak", translationEN: "no/not", sentiment: .neutral),
            createSlangData(canonicalForm: "gak", slang: "gaak", translationEN: "no/not", sentiment: .negative),
            createSlangData(canonicalForm: "woi", slang: "woi", translationEN: "hey", sentiment: .neutral),
            createSlangData(canonicalForm: "woi", slang: "woyyy", translationEN: "hey", sentiment: .positive),
            createSlangData(canonicalForm: "mantap", slang: "mantap", translationEN: "awesome", sentiment: .positive),
            createSlangData(canonicalForm: "baper", slang: "baper", translationEN: "emotional", sentiment: .negative),
        ]
    }
}
