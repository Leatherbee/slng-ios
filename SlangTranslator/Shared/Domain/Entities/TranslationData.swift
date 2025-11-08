//
//  TranslationData.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation

struct TranslationResponse: Decodable, Identifiable {
    let id: UUID
    let originalText: String
    let englishTranslation: String
    let sentiment: SentimentType?
    let source: TranslationSource?
}

enum SentimentType: String, Codable {
    case positive
    case neutral
    case negative
}

enum TranslationSource: Decodable {
    case localDB
    case openAI
}
