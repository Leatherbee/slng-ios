//
//  SlangData.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import Foundation

struct SlangData: Codable, Identifiable {
    private enum CodingKeys: String, CodingKey {
        case slang
        case translationID
        case translationEN
        case contextID
        case contextEN
        case exampleID
        case exampleEN
        case sentiment
    }

    let id: UUID
    let slang: String
    let translationID: String
    let translationEN: String
    let contextID: String
    let contextEN: String
    let exampleID: String
    let exampleEN: String
    let sentiment: SentimentType

    init(id: UUID = UUID(), slang: String, translationID: String, translationEN: String, contextID: String, contextEN: String, exampleID: String, exampleEN: String, sentiment: SentimentType) {
        self.id = id
        self.slang = slang
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
        self.id = UUID()
        self.slang = try container.decode(String.self, forKey: .slang)
        self.translationID = try container.decode(String.self, forKey: .translationID)
        self.translationEN = try container.decode(String.self, forKey: .translationEN)
        self.contextID = try container.decode(String.self, forKey: .contextID)
        self.contextEN = try container.decode(String.self, forKey: .contextEN)
        self.exampleID = try container.decode(String.self, forKey: .exampleID)
        self.exampleEN = try container.decode(String.self, forKey: .exampleEN)
        self.sentiment = try container.decode(SentimentType.self, forKey: .sentiment)
    }
}

final class SlangDictionary {
    static let shared = SlangDictionary()
    
    private(set) var slangs: [SlangData] = []
    
    private init() {
        loadFromJSON()
    }
    
    private func loadFromJSON() {
        guard let url = Bundle.main.url(forResource: "slng_data_seeded", withExtension: "json") else {
            print("Slang JSON not found!")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([SlangData].self, from: data)
            self.slangs = decoded
            print("Loaded \(slangs.count) entries!")
        } catch {
            fatalError("Failed to load JSON entry")
        }
    }

    func findSlang(in text: String, matching sentiment: SentimentType?) -> [SlangData] {
        let normalizedText = text.normalizedForSlangMatching()
        var found: [SlangData] = []
        
        // Search all slangs that occurs in text, without filter
        var rawMatches: [String: [SlangData]] = [:]
        
        for slangData in slangs {
            let slang = slangData.slang.lowercased()
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: slang))\\b"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: normalizedText.utf16.count)
                if regex.firstMatch(in: normalizedText, options: [], range: range) != nil {
                    rawMatches[slang, default: []].append(slangData)
                }
            }
        }
        
        // Loop for each slang that have more than one sentiment, then choose based on provided sentiment
        for (_, variants) in rawMatches {
            if variants.count == 1 {
                found.append(variants.first!)
            } else if let sentiment = sentiment {
                // Find slang that has the same sentiment as the provided one
                if let match = variants.first(where: { $0.sentiment == sentiment }) {
                    found.append(match)
                } else if let neutral = variants.first(where: { $0.sentiment == .neutral }){
                    // If none match, fall back to the first variant
                    found.append(neutral)
                } else {
                    // No sentiment provided; pick a default (first) to avoid ambiguity
                    found.append(variants.first!)
                }
            } else {
                // If GPT don't have sentiment for the sentence, pick the first or neutral
                let selected = variants.first(where: { $0.sentiment == .neutral }) ?? variants.first!
                found.append(selected)
            }
        }

        return found
    }
}

