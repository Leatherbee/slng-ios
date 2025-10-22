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
        let wordFound = await SlangDictionary.shared.findSlang(in: text)
        
        let results = wordFound.map { slang in
            SlangResult(
                slang: slang.slang,
                translationID: slang.translationID,
                translationEN: slang.translationEN,
                contextEN: slang.contextEN,
                exampleEN: slang.exampleEN
            )
        }

        if results.isEmpty {
            return .result(value: [], dialog: "No slang detected in the text.")
        } else {
            let list = results.map { "\($0.slang) → \($0.translationEN)" }.joined(separator: "\n")
            return .result(value: results, dialog: "Detected \(results.count) slang: \(list)")
        }
    }
}

struct SlangResult: Identifiable, AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Slang Result")
    
    static var defaultQuery = SlangResultQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(slang)",
            subtitle: "\(translationEN)"
        )
    }

    var id: String { slang }
    let slang: String
    let translationID: String
    let translationEN: String
    let contextEN: String
    let exampleEN: String
}

struct SlangResultQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SlangResult] {
        return []
    }
    
    func suggestedEntities() async throws -> [SlangResult] {
        return []
    }
}
