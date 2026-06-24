//
//  TranslationRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation
import SwiftData

final class TranslationRepositoryImpl: TranslationRepository {
    private let client: BackendClient
    private let context: ModelContext

    init(client: BackendClient, context: ModelContext) {
        self.client = client
        self.context = context
    }

    func translateSentence(_ text: String) async throws -> TranslationResponse {
        let lowercasedText = text.lowercased()
        if let cached = fetchCachedTranslation(for: lowercasedText) {
            return cached
        }
        let gptResponse = try await translateSentenceViaBackend(for: lowercasedText)
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

    private func translateSentenceViaBackend(for text: String) async throws -> TranslationResponse {
        var req = client.makeRequest(path: "api/v1/nlp/translate", method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let payload = TranslationRequest(text: text, model: nil, temperature: 0.3)
        req.httpBody = try JSONEncoder().encode(payload)

        // Use performRequest with automatic retry
        let (data, _) = try await client.performRequest(req)

        let decoded = try JSONDecoder().decode(BackendTranslationDTO.self, from: data)
        let sentiment = SentimentType(rawValue: decoded.sentiment ?? "") ?? .neutral
        return TranslationResponse(
            id: UUID(),
            originalText: decoded.originalText,
            englishTranslation: decoded.englishTranslation,
            sentiment: sentiment,
            source: .openAI
        )
    }

    private func saveTranslationToSwiftData(_ response: TranslationResponse) {
        let cache = TranslationModel(
            originalText: response.originalText.lowercased(),
            englishTranslation: response.englishTranslation,
            sentiment: response.sentiment ?? .neutral
        )
        context.insert(cache)
        try? context.save()
    }
}

private struct BackendTranslationDTO: Decodable {
    let englishTranslation: String
    let originalText: String
    let sentiment: String?
}
