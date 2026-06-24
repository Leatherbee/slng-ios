//
//  TranscriptionResponse.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 12/11/25.
//

import Foundation

struct TranscriptionResponse: Decodable, Identifiable {
    let id: UUID
    let text: String
    let confidence: Double?
    let source: TranscriptionSource?
}

enum TranscriptionSource: Decodable {
    case backend
    case local
}


