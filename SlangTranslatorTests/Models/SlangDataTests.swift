//
//  SlangDataTests.swift
//  SlangTranslatorTests
//
//  Tests for SlangData model and related types.
//

import Testing
import Foundation
@testable import SLNG

struct SlangDataTests {

    // MARK: - SlangData Initialization Tests

    @Test func slangData_initWithAllParameters_createsCorrectly() async throws {
        let id = UUID()
        let slangData = SlangData(
            id: id,
            canonicalForm: "gak",
            canonicalPronunciation: "gak",
            slang: "gak",
            pronunciation: "gak",
            translationID: "tidak",
            translationEN: "no/not",
            contextID: "Digunakan untuk menyatakan penolakan",
            contextEN: "Used to express negation",
            exampleID: "Gak mau",
            exampleEN: "Don't want to",
            sentiment: .neutral
        )

        #expect(slangData.id == id)
        #expect(slangData.canonicalForm == "gak")
        #expect(slangData.slang == "gak")
        #expect(slangData.translationEN == "no/not")
        #expect(slangData.sentiment == .neutral)
    }

    @Test func slangData_initFromGroupAndVariant_createsCorrectly() async throws {
        let group = SlangGroup(
            canonicalForm: "woi",
            canonicalPronunciation: "woi",
            variants: []
        )

        let variant = SlangVariant(
            slang: "woyyy",
            pronunciation: "woi",
            translationID: "hei",
            translationEN: "hey",
            contextID: "Panggilan informal",
            contextEN: "Informal calling",
            exampleID: "Woyyy, kesini!",
            exampleEN: "Hey, come here!",
            sentiment: "neutral"
        )

        let slangData = SlangData(from: group, variant: variant)

        #expect(slangData.canonicalForm == "woi")
        #expect(slangData.slang == "woyyy")
        #expect(slangData.translationEN == "hey")
        #expect(slangData.sentiment == .neutral)
    }

    // MARK: - Equatable Tests

    @Test func slangData_equality_worksCorrectly() async throws {
        let id = UUID()
        let slang1 = SlangData(
            id: id,
            canonicalForm: "test",
            canonicalPronunciation: "test",
            slang: "test",
            pronunciation: "test",
            translationID: "test",
            translationEN: "test",
            contextID: "test",
            contextEN: "test",
            exampleID: "test",
            exampleEN: "test",
            sentiment: .neutral
        )

        let slang2 = SlangData(
            id: id,
            canonicalForm: "test",
            canonicalPronunciation: "test",
            slang: "test",
            pronunciation: "test",
            translationID: "test",
            translationEN: "test",
            contextID: "test",
            contextEN: "test",
            exampleID: "test",
            exampleEN: "test",
            sentiment: .neutral
        )

        #expect(slang1 == slang2)
    }

    @Test func slangData_differentIds_areNotEqual() async throws {
        let slang1 = SlangData(
            id: UUID(),
            canonicalForm: "test",
            canonicalPronunciation: "test",
            slang: "test",
            pronunciation: "test",
            translationID: "test",
            translationEN: "test",
            contextID: "test",
            contextEN: "test",
            exampleID: "test",
            exampleEN: "test",
            sentiment: .neutral
        )

        let slang2 = SlangData(
            id: UUID(),
            canonicalForm: "test",
            canonicalPronunciation: "test",
            slang: "test",
            pronunciation: "test",
            translationID: "test",
            translationEN: "test",
            contextID: "test",
            contextEN: "test",
            exampleID: "test",
            exampleEN: "test",
            sentiment: .neutral
        )

        #expect(slang1 != slang2)
    }

    // MARK: - Encoding/Decoding Tests

    @Test func slangData_encodeDecode_preservesData() async throws {
        let original = SlangData(
            id: UUID(),
            canonicalForm: "mantap",
            canonicalPronunciation: "man-tap",
            slang: "mantaaap",
            pronunciation: "man-tap",
            translationID: "bagus sekali",
            translationEN: "awesome",
            contextID: "Ekspresi kagum",
            contextEN: "Expression of admiration",
            exampleID: "Mantap jiwa!",
            exampleEN: "Awesome!",
            sentiment: .positive
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SlangData.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.canonicalForm == original.canonicalForm)
        #expect(decoded.slang == original.slang)
        #expect(decoded.translationEN == original.translationEN)
        #expect(decoded.sentiment == original.sentiment)
    }

    @Test func slangData_decodeWithoutId_generatesNewId() async throws {
        let json = """
        {
            "canonicalForm": "test",
            "canonicalPronunciation": "test",
            "slang": "test",
            "pronunciation": "test",
            "translationID": "test",
            "translationEN": "test",
            "contextID": "test",
            "contextEN": "test",
            "exampleID": "test",
            "exampleEN": "test",
            "sentiment": "neutral"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SlangData.self, from: json)

        #expect(decoded.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(decoded.slang == "test")
    }

    // MARK: - SentimentType Tests

    @Test func sentimentType_rawValues_areCorrect() async throws {
        #expect(SentimentType.positive.rawValue == "positive")
        #expect(SentimentType.neutral.rawValue == "neutral")
        #expect(SentimentType.negative.rawValue == "negative")
    }

    @Test func sentimentType_initFromRawValue_worksCorrectly() async throws {
        #expect(SentimentType(rawValue: "positive") == .positive)
        #expect(SentimentType(rawValue: "neutral") == .neutral)
        #expect(SentimentType(rawValue: "negative") == .negative)
        #expect(SentimentType(rawValue: "invalid") == nil)
    }

    // MARK: - SlangGroup Tests

    @Test func slangGroup_decoding_worksCorrectly() async throws {
        let json = """
        {
            "canonicalForm": "gak",
            "canonicalPronunciation": "gak",
            "variants": [
                {
                    "slang": "gak",
                    "pronunciation": "gak",
                    "translationID": "tidak",
                    "translationEN": "no",
                    "contextID": "Penolakan",
                    "contextEN": "Negation",
                    "exampleID": "Gak mau",
                    "exampleEN": "Don't want",
                    "sentiment": "neutral"
                },
                {
                    "slang": "gaak",
                    "pronunciation": "ga-ak",
                    "translationID": "tidak",
                    "translationEN": "no",
                    "contextID": "Penolakan",
                    "contextEN": "Negation",
                    "exampleID": "Gaak bisa",
                    "exampleEN": "Can't",
                    "sentiment": "negative"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let group = try decoder.decode(SlangGroup.self, from: json)

        #expect(group.canonicalForm == "gak")
        #expect(group.variants.count == 2)
        #expect(group.variants[0].slang == "gak")
        #expect(group.variants[1].slang == "gaak")
    }

    // MARK: - decodeFromJSON Tests

    @Test func slangData_decodeFromJSON_createsMultipleSlangs() async throws {
        let json = """
        [
            {
                "canonicalForm": "woi",
                "canonicalPronunciation": "woi",
                "variants": [
                    {
                        "slang": "woi",
                        "pronunciation": "woi",
                        "translationID": "hei",
                        "translationEN": "hey",
                        "contextID": "Panggilan",
                        "contextEN": "Calling",
                        "exampleID": "Woi!",
                        "exampleEN": "Hey!",
                        "sentiment": "neutral"
                    },
                    {
                        "slang": "woyyy",
                        "pronunciation": "woi",
                        "translationID": "hei",
                        "translationEN": "hey",
                        "contextID": "Panggilan",
                        "contextEN": "Calling",
                        "exampleID": "Woyyy!",
                        "exampleEN": "Hey!",
                        "sentiment": "positive"
                    }
                ]
            }
        ]
        """.data(using: .utf8)!

        let slangs = try SlangData.decodeFromJSON(data: json)

        #expect(slangs.count == 2)
        #expect(slangs[0].canonicalForm == "woi")
        #expect(slangs[0].slang == "woi")
        #expect(slangs[1].slang == "woyyy")
    }
}
