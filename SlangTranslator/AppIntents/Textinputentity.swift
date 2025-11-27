//
//  Textinputentity.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 26/11/25.
//
import AppIntents

struct TextInputEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Text Input")
    static var defaultQuery = TextInputQuery()

    let id: String
    let value: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: value)
        )
    }
}

struct TextInputQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TextInputEntity] {
        identifiers.map { TextInputEntity(id: $0, value: $0) }
    }
}

