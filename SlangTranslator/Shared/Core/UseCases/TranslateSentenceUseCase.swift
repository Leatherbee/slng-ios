//
//  Untitled.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation

protocol TranslateSentenceUseCase {
    func execute(_ text: String) async throws -> TranslationResponse
}

final class TranslateSentenceUseCaseImpl: TranslateSentenceUseCase {
    private let repository: TranslationRepository

    init(repository: TranslationRepository) {
        self.repository = repository
    }

    func execute(_ text: String) async throws -> TranslationResponse {
        return try await repository.translateSentence(text)
    }
}
