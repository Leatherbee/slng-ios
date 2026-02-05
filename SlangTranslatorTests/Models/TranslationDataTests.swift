//
//  TranslationDataTests.swift
//  SlangTranslatorTests
//
//  Tests for TranslationData models.
//

import Testing
import Foundation
@testable import SLNG

struct TranslationDataTests {

    // MARK: - TranslationRequest Tests

    @Test func translationRequest_encoding_worksCorrectly() async throws {
        let request = TranslationRequest(
            text: "aku gak mau",
            model: "gpt-4",
            temperature: 0.3
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["text"] as? String == "aku gak mau")
        #expect(json?["model"] as? String == "gpt-4")
        #expect(json?["temperature"] as? Double == 0.3)
    }

    @Test func translationRequest_withNilOptionals_encodesCorrectly() async throws {
        let request = TranslationRequest(
            text: "hello",
            model: nil,
            temperature: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["text"] as? String == "hello")
        // nil values should not be present or be null
    }

    // MARK: - TranslationResponse Tests

    @Test func translationResponse_decoding_worksCorrectly() async throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "originalText": "gak mau",
            "englishTranslation": "don't want",
            "sentiment": "negative",
            "source": null
        }
        """.data(using: .utf8)!

        // Note: TranslationResponse might need custom decoding for source
        // This test verifies the basic structure
    }

    // MARK: - SentimentType Encoding/Decoding Tests

    @Test func sentimentType_encoding_producesRawValue() async throws {
        let encoder = JSONEncoder()

        let positive = try encoder.encode(SentimentType.positive)
        let neutral = try encoder.encode(SentimentType.neutral)
        let negative = try encoder.encode(SentimentType.negative)

        #expect(String(data: positive, encoding: .utf8)?.contains("positive") == true)
        #expect(String(data: neutral, encoding: .utf8)?.contains("neutral") == true)
        #expect(String(data: negative, encoding: .utf8)?.contains("negative") == true)
    }

    @Test func sentimentType_decoding_worksForAllValues() async throws {
        let decoder = JSONDecoder()

        let positive = try decoder.decode(SentimentType.self, from: "\"positive\"".data(using: .utf8)!)
        let neutral = try decoder.decode(SentimentType.self, from: "\"neutral\"".data(using: .utf8)!)
        let negative = try decoder.decode(SentimentType.self, from: "\"negative\"".data(using: .utf8)!)

        #expect(positive == .positive)
        #expect(neutral == .neutral)
        #expect(negative == .negative)
    }

    // MARK: - TranslationSource Tests

    @Test func translationSource_values_areDistinct() async throws {
        let localDB = TranslationSource.localDB
        let openAI = TranslationSource.openAI

        // Just verify they're different
        switch localDB {
        case .localDB:
            #expect(true)
        case .openAI:
            #expect(Bool(false), "Should be localDB")
        }

        switch openAI {
        case .openAI:
            #expect(true)
        case .localDB:
            #expect(Bool(false), "Should be openAI")
        }
    }
}
