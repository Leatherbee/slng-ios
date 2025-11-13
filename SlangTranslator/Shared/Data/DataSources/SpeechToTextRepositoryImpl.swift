//
//  SpeechToTextRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 12/11/25.
//

import Foundation

final class SpeechToTextRepositoryImpl: SpeechToTextRepository {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func transcribeAudio(data: Data, fileName: String, mimeType: String) async throws -> TranscriptionResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/stt/transcribe"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "audio",
            fileName: fileName,
            mimeType: mimeType,
            fileData: data
        )

        request.httpBody = body

        let (respData, resp) = try await session.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "STTError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Transcription failed"])
        }

        let dto = try JSONDecoder().decode(TranscriptionDTO.self, from: respData)
        return TranscriptionResponse(id: UUID(), text: dto.text, confidence: dto.confidence, source: .backend)
    }
}

private struct TranscriptionDTO: Decodable {
    let text: String
    let confidence: Double?
}
