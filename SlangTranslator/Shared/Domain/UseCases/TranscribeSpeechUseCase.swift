//
//  TranscribeSpeechUseCase.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 12/11/25.
//

import Foundation

protocol TranscribeSpeechUseCase {
    func execute(audioData: Data, fileName: String, mimeType: String) async throws -> String
}

final class TranscribeSpeechUseCaseImpl: TranscribeSpeechUseCase {
    private let repository: SpeechToTextRepository
    
    init(repository: SpeechToTextRepository) {
        self.repository = repository
    }
    
    func execute(audioData: Data, fileName: String, mimeType: String) async throws -> String {
        let response = try await repository.transcribeAudio(data: audioData, fileName: fileName, mimeType: mimeType)
        return response.text
    }
}
