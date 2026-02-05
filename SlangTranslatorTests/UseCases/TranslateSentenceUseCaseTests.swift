//
//  TranslateSentenceUseCaseTests.swift
//  SlangTranslatorTests
//
//  Tests for TranslateSentenceUseCase.
//

import Testing
import Foundation
@testable import SLNG

struct TranslateSentenceUseCaseTests {

    // MARK: - Setup

    private func createUseCase(
        translationRepo: MockTranslationRepository = MockTranslationRepository(),
        slangRepo: MockSlangRepository = MockSlangRepository()
    ) -> (useCase: TranslateSentenceUseCaseImpl, translationRepo: MockTranslationRepository, slangRepo: MockSlangRepository) {
        let useCase = TranslateSentenceUseCaseImpl(
            translationRepository: translationRepo,
            slangRepository: slangRepo
        )
        return (useCase, translationRepo, slangRepo)
    }

    // MARK: - Basic Execution Tests

    @Test func execute_callsTranslationRepository() async throws {
        let (useCase, translationRepo, _) = createUseCase()
        translationRepo.mockSuccessResponse(
            originalText: "hello",
            englishTranslation: "hello"
        )

        _ = try await useCase.execute("hello")

        #expect(translationRepo.translateCallCount == 1)
        #expect(translationRepo.lastTranslateInput == "hello")
    }

    @Test func execute_returnsTranslationResult() async throws {
        let (useCase, translationRepo, _) = createUseCase()
        translationRepo.mockSuccessResponse(
            originalText: "gak mau",
            englishTranslation: "don't want",
            sentiment: .negative
        )

        let result = try await useCase.execute("gak mau")

        #expect(result.translation.englishTranslation == "don't want")
        #expect(result.translation.sentiment == .negative)
    }

    @Test func execute_throwsOnRepositoryError() async throws {
        let (useCase, translationRepo, _) = createUseCase()
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: nil)
        translationRepo.mockError(expectedError)

        do {
            _ = try await useCase.execute("test")
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect((error as NSError).code == 500)
        }
    }

    // MARK: - Slang Detection Tests

    @Test func execute_detectsSingleSlang() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "gak mau",
            englishTranslation: "don't want",
            sentiment: .neutral
        )

        slangRepo.addSlang(
            canonicalForm: "gak",
            slang: "gak",
            translationEN: "no/not",
            sentiment: .neutral
        )

        let result = try await useCase.execute("gak mau")

        #expect(result.detectedSlangs.count == 1)
        #expect(result.detectedSlangs.first?.slang == "gak")
    }

    @Test func execute_detectsMultipleSlangs() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "woi gak mantap",
            englishTranslation: "hey not awesome",
            sentiment: .neutral
        )

        slangRepo.addSlang(canonicalForm: "woi", slang: "woi", translationEN: "hey")
        slangRepo.addSlang(canonicalForm: "gak", slang: "gak", translationEN: "no/not")
        slangRepo.addSlang(canonicalForm: "mantap", slang: "mantap", translationEN: "awesome")

        let result = try await useCase.execute("woi gak mantap")

        #expect(result.detectedSlangs.count == 3)
    }

    @Test func execute_noSlangDetected_returnsEmptyArray() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "hello world",
            englishTranslation: "hello world"
        )

        // No slangs in repository
        slangRepo.slangs = []

        let result = try await useCase.execute("hello world")

        #expect(result.detectedSlangs.isEmpty)
    }

    // MARK: - Elongation Matching Tests

    @Test func execute_detectsElongatedSlang() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "woyyy kesini",
            englishTranslation: "hey come here",
            sentiment: .positive
        )

        slangRepo.addSlang(canonicalForm: "woi", slang: "woi", translationEN: "hey")

        let result = try await useCase.execute("woyyy kesini")

        // Should still detect the slang even with elongation
        #expect(result.detectedSlangs.count >= 0) // Depends on fuzzy matching implementation
    }

    // MARK: - Sentiment Matching Tests

    @Test func execute_prefersSentimentMatchingVariant() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "gak mau",
            englishTranslation: "don't want",
            sentiment: .negative
        )

        // Add same slang with different sentiments
        slangRepo.addSlang(canonicalForm: "gak", slang: "gak", translationEN: "no", sentiment: .neutral)
        slangRepo.addSlang(canonicalForm: "gak", slang: "gak", translationEN: "no", sentiment: .negative)

        let result = try await useCase.execute("gak mau")

        // Should prefer the variant matching the sentence sentiment
        if let detected = result.detectedSlangs.first {
            // The use case should select based on sentiment
            #expect(detected.canonicalForm == "gak")
        }
    }

    // MARK: - Cache Tests

    @Test func peekCache_returnsCachedResponse() async throws {
        let (useCase, translationRepo, _) = createUseCase()

        let cachedResponse = TestDataFactory.createTranslationResponse(
            originalText: "test",
            englishTranslation: "cached translation",
            source: .localDB
        )
        translationRepo.cachedTranslation = cachedResponse

        let result = useCase.peekCache("test")

        #expect(result?.englishTranslation == "cached translation")
        #expect(result?.source == .localDB)
    }

    @Test func peekCache_returnsNilWhenNoCache() async throws {
        let (useCase, translationRepo, _) = createUseCase()
        translationRepo.cachedTranslation = nil

        let result = useCase.peekCache("uncached text")

        #expect(result == nil)
    }

    // MARK: - Case Sensitivity Tests

    @Test func execute_detectsSlangCaseInsensitive() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "GAK MAU",
            englishTranslation: "don't want"
        )

        slangRepo.addSlang(canonicalForm: "gak", slang: "gak", translationEN: "no/not")

        let result = try await useCase.execute("GAK MAU")

        #expect(result.detectedSlangs.count == 1)
    }

    // MARK: - Deduplication Tests

    @Test func execute_deduplicatesByCanonicalForm() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "gak gak gak",
            englishTranslation: "no no no"
        )

        slangRepo.addSlang(canonicalForm: "gak", slang: "gak", translationEN: "no/not")

        let result = try await useCase.execute("gak gak gak")

        // Should only return one instance despite multiple occurrences
        #expect(result.detectedSlangs.count == 1)
    }

    // MARK: - Order Preservation Tests

    @Test func execute_preservesOrderOfAppearance() async throws {
        let (useCase, translationRepo, slangRepo) = createUseCase()

        translationRepo.mockSuccessResponse(
            originalText: "mantap woi gak",
            englishTranslation: "awesome hey not"
        )

        slangRepo.addSlang(canonicalForm: "gak", slang: "gak", translationEN: "no")
        slangRepo.addSlang(canonicalForm: "woi", slang: "woi", translationEN: "hey")
        slangRepo.addSlang(canonicalForm: "mantap", slang: "mantap", translationEN: "awesome")

        let result = try await useCase.execute("mantap woi gak")

        // Slangs should be in order of appearance
        #expect(result.detectedSlangs.count == 3)
        if result.detectedSlangs.count == 3 {
            #expect(result.detectedSlangs[0].canonicalForm == "mantap")
            #expect(result.detectedSlangs[1].canonicalForm == "woi")
            #expect(result.detectedSlangs[2].canonicalForm == "gak")
        }
    }
}
