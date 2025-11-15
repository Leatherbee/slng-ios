//
//  SlangModel.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import Foundation
import SwiftData

@Model
final class SlangModel {
    @Attribute(.unique) var id: UUID
    var canonicalForm: String
    var canonicalPronunciation: String
    var slang: String
    var pronunciation: String
    var translationID: String
    var translationEN: String
    var contextID: String
    var contextEN: String
    var exampleID: String
    var exampleEN: String
    var sentiment: SentimentType
    
    init(id: UUID,
         canonicalForm: String,
         canonicalPronunciation: String,
         slang: String,
         pronunciation: String,
         translationID: String,
         translationEN: String,
         contextID: String,
         contextEN: String,
         exampleID: String,
         exampleEN: String,
         sentiment: SentimentType) {
        self.id = id
        self.canonicalForm = canonicalForm
        self.canonicalPronunciation = canonicalPronunciation
        self.slang = slang
        self.pronunciation = pronunciation
        self.translationID = translationID
        self.translationEN = translationEN
        self.contextID = contextID
        self.contextEN = contextEN
        self.exampleID = exampleID
        self.exampleEN = exampleEN
        self.sentiment = sentiment
    }
}
