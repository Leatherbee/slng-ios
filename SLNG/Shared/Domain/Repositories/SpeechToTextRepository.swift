//
//  SpeechToTextRepository.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 12/11/25.
//

import Foundation

protocol SpeechToTextRepository {
    func transcribeAudio(data: Data, fileName: String, mimeType: String) async throws -> TranscriptionResponse
}
