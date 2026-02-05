//
//  ExplainSlangIntent.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import AppIntents
import Foundation
import UIKit

struct ExplainSlangIntent: AppIntent {
    static var title: LocalizedStringResource = "Explain Slang"
    static var description = IntentDescription("Detect and explain Indonesian slang in text, including full English translation and sentiment tone.")

    @Parameter(title: "Text", requestValueDialog: IntentDialog("Enter text"))
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
            return .result(value: [], dialog: IntentDialog("Failed to analyze text: \(error.localizedDescription)"))
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
                dialog: IntentDialog("""
                No slang detected in the text.
                Sentiment: \(sentiment.rawValue.capitalized)
                Full translation: "\(fullTranslation)"
                """
                )
            )
        } else {
            let list = results.map { "\($0.slang) → \($0.translationEN)" }.joined(separator: "\n")
            return .result(
                value: results,
                dialog: IntentDialog("""
                Full English translation (\(sentiment.rawValue)):
                "\(fullTranslation)"

                Detected \(results.count) slang:
                \(list)
                """
                )
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

struct QuickTranslateIntent: AppIntent {
    static var title: LocalizedStringResource = "Quick Translate"
    static var description = IntentDescription("Translate any text to English and detect sentiment tone.")

    @Parameter(title: "Text", requestValueDialog: IntentDialog("Enter text"))
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let useCase: TranslateSentenceUseCaseImpl = await MainActor.run {
            let context = SharedModelContainer.shared.context
            let baseURLString = Bundle.main.infoDictionary?["BackendBaseURL"] as? String ?? "https://api.slng.space"
            let baseURL = URL(string: baseURLString)!
            let client = BackendClient(baseURL: baseURL)
            let translationRepository = TranslationRepositoryImpl(client: client, context: context)
            let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
            return TranslateSentenceUseCaseImpl(translationRepository: translationRepository, slangRepository: slangRepository)
        }

        let result = try await useCase.execute(text)
        let sentiment = result.translation.sentiment?.rawValue.capitalized ?? "Neutral"
        let fullTranslation = result.translation.englishTranslation

        return .result(
            value: fullTranslation,
            dialog: IntentDialog("Sentiment: \(sentiment)\n\"\(fullTranslation)\"")
        )
    }
}

struct TranslateClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Translate Clipboard"
    static var description = IntentDescription("Translate text from clipboard using SLNG and show sentiment.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let useCase: TranslateSentenceUseCaseImpl = await MainActor.run {
            let context = SharedModelContainer.shared.context
            let baseURLString = Bundle.main.infoDictionary?["BackendBaseURL"] as? String ?? "https://api.slng.space"
            let baseURL = URL(string: baseURLString)!
            let client = BackendClient(baseURL: baseURL)
            let translationRepository = TranslationRepositoryImpl(client: client, context: context)
            let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
            return TranslateSentenceUseCaseImpl(translationRepository: translationRepository, slangRepository: slangRepository)
        }

        let raw = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if raw.isEmpty {
            return .result(value: "", dialog: IntentDialog("Clipboard is empty or contains no text."))
        }

        let result = try await useCase.execute(raw)
        let sentiment = result.translation.sentiment?.rawValue.capitalized ?? "Neutral"
        let fullTranslation = result.translation.englishTranslation

        return .result(
            value: fullTranslation,
            dialog: IntentDialog("Sentiment: \(sentiment)\n\"\(fullTranslation)\"")
        )
    }
}

struct ExplainSingleSlangIntent: AppIntent {
    static var title: LocalizedStringResource = "Explain Slang Term"
    static var description = IntentDescription("Find and explain a single slang term from SLNG dictionary.")

    @Parameter(title: "Slang")
    var input: TextInputEntity

    func perform() async throws -> some IntentResult & ReturnsValue<[SlangResult]> & ProvidesDialog {
        let repository: SlangRepositoryImpl = await MainActor.run {
            SlangRepositoryImpl(container: SharedModelContainer.shared.container)
        }

        let term = input.value.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = await repository.loadAll()
        let matches = all.filter {
            $0.slang.lowercased() == term.lowercased() ||
            $0.canonicalForm.lowercased() == term.lowercased()
        }

        let results = matches.map {
            SlangResult(
                slang: $0.slang,
                translationID: $0.translationID,
                translationEN: $0.translationEN,
                contextEN: $0.contextEN,
                exampleEN: $0.exampleEN,
                sentiment: $0.sentiment.rawValue,
                fullTranslation: $0.translationEN
            )
        }

        if results.isEmpty {
            return .result(value: [], dialog: IntentDialog("No slang found for ‘\(term)’."))
        }

        let list = results.map { "\($0.slang) → \($0.translationEN)" }.joined(separator: "\n")
        return .result(
            value: results,
            dialog: IntentDialog("Found \(results.count) result(s) for ‘\(term)’:\n\(list)")
        )
    }
}

struct RandomSlangOfTheDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Slang of the Day"
    static var description = IntentDescription("Show a random slang entry for today from SLNG.")

    func perform() async throws -> some IntentResult & ReturnsValue<[SlangResult]> & ProvidesDialog {
        let repository: SlangRepositoryImpl = await MainActor.run {
            SlangRepositoryImpl(container: SharedModelContainer.shared.container)
        }

        let all = await repository.loadAll()
        if all.isEmpty {
            return .result(value: [], dialog: IntentDialog("Slang data is empty."))
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        let seed = dateString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let index = seed % all.count
        let s = all[index]

        let result = SlangResult(
            slang: s.slang,
            translationID: s.translationID,
            translationEN: s.translationEN,
            contextEN: s.contextEN,
            exampleEN: s.exampleEN,
            sentiment: s.sentiment.rawValue,
            fullTranslation: s.translationEN
        )

        let dialog = IntentDialog("Slang of the Day: \(s.slang)\nTranslation: \(s.translationEN)\nSentiment: \(s.sentiment.rawValue.capitalized)\nExample: \(s.exampleEN)")

        return .result(value: [result], dialog: dialog)
    }
}
