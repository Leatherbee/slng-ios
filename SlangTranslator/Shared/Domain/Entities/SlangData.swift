//
//  SlangData.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import Foundation

struct SlangGroup: Codable {
    let canonicalForm: String
    let canonicalPronunciation: String
    let variants: [SlangVariant]
}

struct SlangVariant: Codable {
    let slang: String
    let pronunciation: String
    let translationID: String
    let translationEN: String
    let contextID: String
    let contextEN: String
    let exampleID: String
    let exampleEN: String
    let sentiment: String
}

struct SlangData: Equatable, Identifiable, Codable {
    let id: UUID
    let canonicalForm: String
    let canonicalPronunciation: String
    let slang: String
    let pronunciation: String
    let translationID: String
    let translationEN: String
    let contextID: String
    let contextEN: String
    let exampleID: String
    let exampleEN: String
    let sentiment: SentimentType
    
    private enum CodingKeys: String, CodingKey {
        case id
        case canonicalForm
        case canonicalPronunciation
        case slang
        case pronunciation
        case translationID
        case translationEN
        case contextID
        case contextEN
        case exampleID
        case exampleEN
        case sentiment
    }
    
    init(from group: SlangGroup, variant: SlangVariant) {
        self.id = UUID()
        self.canonicalForm = group.canonicalForm
        self.canonicalPronunciation = group.canonicalPronunciation
        self.slang = variant.slang
        self.pronunciation = variant.pronunciation
        self.translationID = variant.translationID
        self.translationEN = variant.translationEN
        self.contextID = variant.contextID
        self.contextEN = variant.contextEN
        self.exampleID = variant.exampleID
        self.exampleEN = variant.exampleEN
        self.sentiment = SentimentType(rawValue: variant.sentiment) ?? .neutral
    }
    
    init(id: UUID = UUID(),
         canonicalForm: String,
         canonicalPronunciation: String,
         slang: String,
         pronunciation: String,
         translationID: String,
         translationEN: String,
         contextID: String,
         contextEN: String,
         exampleID: String,
         exampleEN: String,
         sentiment: SentimentType) {
        self.id = id
        self.canonicalForm = canonicalForm
        self.canonicalPronunciation = canonicalPronunciation
        self.slang = slang
        self.pronunciation = pronunciation
        self.translationID = translationID
        self.translationEN = translationEN
        self.contextID = contextID
        self.contextEN = contextEN
        self.exampleID = exampleID
        self.exampleEN = exampleEN
        self.sentiment = sentiment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.canonicalForm = try container.decode(String.self, forKey: .canonicalForm)
        self.canonicalPronunciation = try container.decode(String.self, forKey: .canonicalPronunciation)
        self.slang = try container.decode(String.self, forKey: .slang)
        self.pronunciation = try container.decode(String.self, forKey: .pronunciation)
        self.translationID = try container.decode(String.self, forKey: .translationID)
        self.translationEN = try container.decode(String.self, forKey: .translationEN)
        self.contextID = try container.decode(String.self, forKey: .contextID)
        self.contextEN = try container.decode(String.self, forKey: .contextEN)
        self.exampleID = try container.decode(String.self, forKey: .exampleID)
        self.exampleEN = try container.decode(String.self, forKey: .exampleEN)
        let sentimentRaw = try container.decode(String.self, forKey: .sentiment)
        self.sentiment = SentimentType(rawValue: sentimentRaw) ?? .neutral
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(canonicalForm, forKey: .canonicalForm)
        try container.encode(canonicalPronunciation, forKey: .canonicalPronunciation)
        try container.encode(slang, forKey: .slang)
        try container.encode(pronunciation, forKey: .pronunciation)
        try container.encode(translationID, forKey: .translationID)
        try container.encode(translationEN, forKey: .translationEN)
        try container.encode(contextID, forKey: .contextID)
        try container.encode(contextEN, forKey: .contextEN)
        try container.encode(exampleID, forKey: .exampleID)
        try container.encode(exampleEN, forKey: .exampleEN)
        try container.encode(sentiment.rawValue, forKey: .sentiment)
    }
}

extension SlangData {
    static func decodeFromJSON(data: Data) throws -> [SlangData] {
        let decoder = JSONDecoder()
        let groups = try decoder.decode([SlangGroup].self, from: data)
        
        var allSlangs: [SlangData] = []
        for group in groups {
            for variant in group.variants {
                let slangData = SlangData(from: group, variant: variant)
                allSlangs.append(slangData)
            }
        }
        
        return allSlangs
    }
    
    static func decodeFromStream(_ stream: InputStream) throws -> [SlangData] {
        stream.open()
        defer { stream.close() }
        
        guard let array = try JSONSerialization.jsonObject(with: stream, options: []) as? [[String: Any]] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid JSON format"
                )
            )
        }
        
        let decoder = JSONDecoder()
        var allSlangs: [SlangData] = []
        
        for groupDict in array {
            guard let groupData = try? JSONSerialization.data(withJSONObject: groupDict),
                  let group = try? decoder.decode(SlangGroup.self, from: groupData) else {
                if let canonical = groupDict["canonicalForm"] as? String {
                    print("Skipped group '\(canonical)' due to invalid structure")
                } else {
                    print("Skipped group due to invalid structure")
                }
                continue
            }
            
            for variant in group.variants {
                let slangData = SlangData(from: group, variant: variant)
                allSlangs.append(slangData)
            }
        }
        
        return allSlangs
    }
}
