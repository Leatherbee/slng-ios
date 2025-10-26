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
    static var description = IntentDescription("Detect and explain Indonesian slang in text.")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<[SlangResult]> & ProvidesDialog {
        // MARK: - Step 1. Ambil context dari MainActor
//        let context = await MainActor.run { SharedModelContainer.shared.context }
        
//        let apiKey = Bundle.main.infoDictionary?["APIKey"] as? String ?? ""
//        let repository = await TranslationRepositoryImpl(apiKey: apiKey, context: context)
//        let useCase = await TranslateSentenceUseCaseImpl(repository: repository)
        
        let (useCase, _): (TranslateSentenceUseCaseImpl, String) = await MainActor.run {
            let context = SharedModelContainer.shared.context
            let apiKey = Bundle.main.infoDictionary?["APIKey"] as? String ?? ""
            let repository = TranslationRepositoryImpl(apiKey: apiKey, context: context)
            let useCase = TranslateSentenceUseCaseImpl(repository: repository)
            // Return useCase; also return a trivial string to ensure tuple is trivially sendable
            return (useCase, "")
        }

        // MARK: - Step 2. Terjemahkan dengan GPT
        let translation: TranslationResponse
        do {
            translation = try await useCase.execute(text)
        } catch {
            return .result(value: [], dialog: "Failed to analyze text: \(error.localizedDescription)")
        }

        // MARK: - Step 3. Filter slang sesuai sentiment
        let sentiment = translation.sentiment ?? .neutral
        let wordFound = await SlangDictionary.shared.findSlang(in: text, matching: sentiment)

        // MARK: - Step 4. Bangun hasil
        let results = wordFound.map {
            SlangResult(
                slang: $0.slang,
                translationID: $0.translationID,
                translationEN: $0.translationEN,
                contextEN: $0.contextEN,
                exampleEN: $0.exampleEN,
                sentiment: $0.sentiment.rawValue
            )
        }

        if results.isEmpty {
            return .result(value: [], dialog: "No slang detected in the text. The sentence sentiment is \(sentiment.rawValue).")
        } else {
            let list = results.map { "\($0.slang) → \($0.translationEN)" }.joined(separator: "\n")
            return .result(value: results, dialog: "Detected \(results.count) slang (\(sentiment.rawValue) tone):\n\(list)")
        }
    }

}

// MARK: - AppEntity
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
}

// MARK: - Entity Query (dummy)
struct SlangResultQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SlangResult] { [] }
    func suggestedEntities() async throws -> [SlangResult] { [] }
}
