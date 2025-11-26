import Foundation
import SwiftData

enum SLNGSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [TranslationModel.self, SlangModel.self]
    }
}

extension SLNGSchemaV1 {
    @Model
    final class TranslationModel {
        @Attribute(.unique) var originalText: String
        var englishTranslation: String
        var sentiment: SentimentType
        init(originalText: String, englishTranslation: String, sentiment: SentimentType) {
            self.originalText = originalText
            self.englishTranslation = englishTranslation
            self.sentiment = sentiment
        }
    }

    @Model
    final class SlangModel: Equatable {
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
}

typealias SLNGSchemaLatest = SLNGSchemaV1

enum SLNGMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SLNGSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
