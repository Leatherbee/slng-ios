//
//  TranslationRepository.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation

protocol TranslationRepository {
    func translateSentence(_ text: String) async throws -> TranslationResponse
}
