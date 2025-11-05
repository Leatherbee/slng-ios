//
//  SlangModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 05/11/25.
//
import SwiftData
import Foundation
@Model
class SlangModel {
    var id: UUID
    var slang: String
    var translationID: String
    var translationEN: String
    var contextID: String
    var contextEN: String
    var exampleID: String
    var exampleEN: String
    var sentiment: SentimentType
    
    init(id: UUID, slang: String, translationID: String, translationEN: String, contextID: String, contextEN: String, exampleID: String, exampleEN: String, sentiment: SentimentType) {
        self.id = id
        self.slang = slang
        self.translationID = translationID
        self.translationEN = translationEN
        self.contextID = contextID
        self.contextEN = contextEN
        self.exampleID = exampleID
        self.exampleEN = exampleEN
        self.sentiment = sentiment
    }
}
