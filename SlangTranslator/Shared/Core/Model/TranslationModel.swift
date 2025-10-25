//
//  TranslationModel.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import SwiftData

@Model
class TranslationModel {
    @Attribute(.unique) var originalText: String
    var englishTranslation: String
    var sentiment: SentimentType
    
    init(originalText: String, englishTranslation: String, sentiment: SentimentType) {
        self.originalText = originalText
        self.englishTranslation = englishTranslation
        self.sentiment = sentiment
    }
}
