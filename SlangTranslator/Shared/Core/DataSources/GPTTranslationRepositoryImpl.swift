//
//  TranslationRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation
import OpenAI

final class GPTTranslationRepositoryImpl: TranslationRepository {
    private let client: OpenAIProtocol
    
    init(apiKey: String) {
        self.client = OpenAI(apiToken: apiKey)
    }
    
    func translateSentence(_ text: String) async throws -> TranslationResponse {
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

        return TranslationResponse(
            originalText: text,
            englishTranslation: decoded.englishTranslation,
            sentiment: sentiment
        )
    }
}

private struct GPTTranslationResult: Codable {
    let englishTranslation: String
    let sentiment: String
}


