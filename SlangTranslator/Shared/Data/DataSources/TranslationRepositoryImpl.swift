//
//  TranslationRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation
import OpenAI
import SwiftData

final class TranslationRepositoryImpl: TranslationRepository {
    private let client: OpenAIProtocol
    private let context: ModelContext
    
    init(apiKey: String, context: ModelContext) {
        self.client = OpenAI(apiToken: apiKey)
        self.context = context
    }
    
    func translateSentence(_ text: String) async throws -> TranslationResponse {
        let lowercasedText = text.lowercased()
        
        // First, fetch cached translate result locally
        if let cached = fetchCachedTranslation(for: lowercasedText) {
            return cached
        }
        
        // Request to GPT if there is no cached translation
        let gptResponse = try await translateSentenceWithGPT(for: lowercasedText)
        
        // Save response to SwiftData for caching
        saveTranslationToSwiftData(gptResponse)
        
        return gptResponse
    }
    
    func fetchCachedTranslation(for text: String) -> TranslationResponse? {
        let fetchDescriptor = FetchDescriptor<TranslationModel>(
            predicate: #Predicate { $0.originalText == text }
        )
        
        guard let cached = try? context.fetch(fetchDescriptor).first else { return nil }
        
        return TranslationResponse(
            id: UUID(),
            originalText: cached.originalText,
            englishTranslation: cached.englishTranslation,
            sentiment: cached.sentiment,
            source: .localDB
        )
    }
    
    private func translateSentenceWithGPT(for text: String) async throws -> TranslationResponse {
        let prompt = """
        You are an expert Indonesian-English translator that understands modern Indonesian slang, abbreviations, and internet language. 
        Your goal is to translate informal or slang sentences into natural, fluent English that preserves the *meaning and emotional tone*, not word-for-word translation.

        For each input sentence:
        1. Translate it naturally to English (preserving tone and intention).
        2. Identify the sentiment as one of: "positive", "neutral", or "negative".
        3. If the sentence includes slang or figurative expressions, interpret their *contextual meaning*.

        Return ONLY valid JSON in this format:
        {
          "englishTranslation": "...",
          "sentiment": "...",
        }

        Examples:
        Input: "anjir, parah banget!"
        Output: {"englishTranslation": "Damn, that’s crazy!", "sentiment": "negative"}

        Input: "mantul bro!"
        Output: {"englishTranslation": "That’s awesome, bro!", "sentiment": "positive"}

        Now translate the following:
        "\(text)"
        """
        
        let query = ChatQuery(
            messages: [.user(.init(content: .string(prompt)))],
            model: .gpt4_o_mini,
            temperature: 0.3
        )
        
        let result = try await client.chats(query: query)
        
        guard let content = result.choices.first?.message.content else {
            throw NSError(domain: "TranslationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty GPT response"])
        }
        
        let clean = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = clean.data(using: .utf8) else {
            throw NSError(domain: "JSONError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid string encoding"])
        }
        
        let decoded = try JSONDecoder().decode(GPTTranslationResult.self, from: data)
        let sentiment = SentimentType(rawValue: decoded.sentiment.lowercased()) ?? .neutral
        
        let response = TranslationResponse(
            id: UUID(),
            originalText: text,
            englishTranslation: decoded.englishTranslation,
            sentiment: sentiment,
            source: .openAI
        )
        
        return response
    }
    
    private func saveTranslationToSwiftData(_ response: TranslationResponse) {
        let cache = TranslationModel(
            originalText: response.originalText.lowercased(),
            englishTranslation: response.englishTranslation,
            sentiment: response.sentiment ?? .neutral
        )
        
        context.insert(cache)
        try? context.save()
        print("Successfully saved slang into database")
    }
}

// Helper entity for decoding JSON data
private struct GPTTranslationResult: Codable {
    let englishTranslation: String
    let sentiment: String
}
