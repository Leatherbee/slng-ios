//
//  SpeechToTextRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 12/11/25.
//

import Foundation

final class SpeechToTextRepositoryImpl: SpeechToTextRepository {
    private let client: BackendClient
    
    init(client: BackendClient) {
        self.client = client
    }
    
    func transcribeAudio(data: Data, fileName: String, mimeType: String) async throws -> TranscriptionResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = client.makeRequest(path: "api/v1/stt/transcribe", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = MultipartFormData.build(
            boundary: boundary,
            fileFieldName: "audio",
            fileName: fileName,
            mimeType: mimeType,
            fileData: data
        )

        request.httpBody = body

        // Use performRequest with automatic retry
        let (respData, _) = try await client.performRequest(request)

        let dto = try JSONDecoder().decode(TranscriptionDTO.self, from: respData)
        return TranscriptionResponse(id: UUID(), text: dto.text, confidence: dto.confidence, source: .backend)
    }
}

private struct TranscriptionDTO: Decodable {
    let text: String
    let confidence: Double?
}
