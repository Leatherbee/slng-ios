//
//  ExplainSlangIntent.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import AppIntents
import Foundation

struct ExplainSlangIntent: AppIntent {
    static var title: LocalizedStringResource = "Explain Slang"
    static var description = IntentDescription("Detect and explain Indonesian slang in text, including full English translation and sentiment tone.")

    @Parameter(title: "Text", requestValueDialog: "Input Slang")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<[SlangResult]> & ProvidesDialog {

        let (useCase, _): (TranslateSentenceUseCaseImpl, String) = await MainActor.run {
            let context = SharedModelContainer.shared.context
            let baseURLString = Bundle.main.infoDictionary?["BackendBaseURL"] as? String ?? "https://api.slng.space"
            let baseURL = URL(string: baseURLString)!
            let client = BackendClient(baseURL: baseURL)
            let translationRepository = TranslationRepositoryImpl(client: client, context: context)
            let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
            let useCase = TranslateSentenceUseCaseImpl(translationRepository: translationRepository, slangRepository: slangRepository)
            return (useCase, "")
        }

        let result: TranslationResult
        do {
            result = try await useCase.execute(text)
        } catch {
            return .result(value: [], dialog: "Failed to analyze text: \(error.localizedDescription)")
        }

        let translation = result.translation
        let slangs = result.detectedSlangs
        let sentiment = translation.sentiment ?? .neutral
        let fullTranslation = translation.englishTranslation

        let results = slangs.map {
            SlangResult(
                slang: $0.slang,
                translationID: $0.translationID,
                translationEN: $0.translationEN,
                contextEN: $0.contextEN,
                exampleEN: $0.exampleEN,
                sentiment: $0.sentiment.rawValue,
                fullTranslation: fullTranslation
            )
        }

        if results.isEmpty {
            return .result(
                value: [],
                dialog: """
                No slang detected in the text.
                Sentiment: \(sentiment.rawValue.capitalized)
                Full translation: "\(fullTranslation)"
                """
            )
        } else {
            let list = results.map { "\($0.slang) → \($0.translationEN)" }.joined(separator: "\n")
            return .result(
                value: results,
                dialog: """
                Full English translation (\(sentiment.rawValue)):
                "\(fullTranslation)"

                Detected \(results.count) slang:
                \(list)
                """
            )
        }
    }
}

struct SlangResult: Identifiable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Slang Result")
    static var defaultQuery = SlangResultQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(slang)",
            subtitle: "\(translationEN) (\(sentiment))"
        )
    }

    var id: String { "\(slang)-\(sentiment)" }

    let slang: String
    let translationID: String
    let translationEN: String
    let contextEN: String
    let exampleEN: String
    let sentiment: String
    let fullTranslation: String
}

struct SlangResultQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SlangResult] { [] }
    func suggestedEntities() async throws -> [SlangResult] { [] }
}
