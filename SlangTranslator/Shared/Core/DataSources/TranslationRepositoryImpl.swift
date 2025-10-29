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
    
    private func fetchCachedTranslation(for text: String) -> TranslationResponse? {
        let fetchDescriptor = FetchDescriptor<TranslationModel>(
            predicate: #Predicate { $0.originalText == text }
        )
        
        guard let cached = try? context.fetch(fetchDescriptor).first else { return nil }
        
        return TranslationResponse(
            id: UUID(),
            originalText: cached.originalText,
            englishTranslation: cached.englishTranslation,
            sentiment: cached.sentiment
        )
    }
    
    private func translateSentenceWithGPT(for text: String) async throws -> TranslationResponse {
        let prompt = """
        Terjemahkan kalimat berikut dari Bahasa Indonesia informal ke Bahasa Inggris natural.
        Juga tentukan sentimen dari kalimat tersebut (positif, netral, atau negatif).
        Format hasil sebagai JSON valid:
        {
          "englishTranslation": "...",
          "sentiment": "..."
        }
        
        Kalimat: "\(text)"
        """
        
        let query = ChatQuery(
            messages: [.user(.init(content: .string(prompt)))], model: .gpt4_o_mini,
            temperature: 0.7
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
            sentiment: sentiment
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

// Helper model for decoding JSON data
private struct GPTTranslationResult: Codable {
    let englishTranslation: String
    let sentiment: String
}
