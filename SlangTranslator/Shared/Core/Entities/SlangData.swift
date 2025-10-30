//
//  SlangData.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import Foundation

struct SlangData: Equatable, Codable, Identifiable {
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

    init(id: UUID = UUID(),
         slang: String,
         translationID: String,
         translationEN: String,
         contextID: String,
         contextEN: String,
         exampleID: String,
         exampleEN: String,
         sentiment: SentimentType) {
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
    private var isLoaded = false

    private init() {
        loadFromJSON()
    }

    private func loadFromJSON() {
        guard !isLoaded else { return }
        isLoaded = true

        guard let url = Bundle.main.url(forResource: "slng_data_seeded", withExtension: "json"),
              let stream = InputStream(url: url) else {
            print("Slang JSON not found!")
            return
        }

        stream.open()
        defer { stream.close() }

        do {
            guard let array = try JSONSerialization.jsonObject(with: stream, options: []) as? [Any] else {
                print("Invalid JSON format")
                return
            }

            let decoder = JSONDecoder()
            var temp: [SlangData] = []
            temp.reserveCapacity(array.count)

            for case let dict as [String: Any] in array {
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                   let slang = try? decoder.decode(SlangData.self, from: data) {
                    temp.append(slang)
                }
            }

            self.slangs = temp
            print("Finished loading \(slangs.count) entries (sync stream).")
        } catch {
            print("Failed to parse slang JSON: \(error)")
        }
    }

    func findSlang(in text: String, matching sentiment: SentimentType?) -> [SlangData] {
        let normalizedText = text.normalizedForSlangMatching()
        var found: [(data: SlangData, range: NSRange)] = []

        for slangData in slangs {
            let slang = slangData.slang.lowercased()
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: slang))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let fullRange = NSRange(location: 0, length: normalizedText.utf16.count)

            regex.enumerateMatches(in: normalizedText, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    found.append((data: slangData, range: range))
                }
            }
        }

        var filtered: [SlangData] = []
        for (_, group) in Dictionary(grouping: found, by: { $0.data.slang.lowercased() }) {
            let variants = group.map { $0.data }
            if variants.count == 1 {
                filtered.append(variants.first!)
            } else if let sentiment = sentiment {
                if let match = variants.first(where: { $0.sentiment == sentiment }) {
                    filtered.append(match)
                } else if let neutral = variants.first(where: { $0.sentiment == .neutral }) {
                    filtered.append(neutral)
                } else {
                    filtered.append(variants.first!)
                }
            } else {
                let selected = variants.first(where: { $0.sentiment == .neutral }) ?? variants.first!
                filtered.append(selected)
            }
        }

        var firstPositions: [String: Int] = [:]
        for slang in found {
            let key = slang.data.slang.lowercased()
            if firstPositions[key] == nil {
                firstPositions[key] = slang.range.location
            }
        }

        // Filter only based on unique slang and its first position on text
        let uniqueOrdered = filtered
            .reduce(into: [String: SlangData]()) { dict, slang in
                let key = slang.slang.lowercased()
                if dict[key] == nil {
                    dict[key] = slang
                }
            }
            .values
            .sorted {
                let pos1 = firstPositions[$0.slang.lowercased()] ?? .max
                let pos2 = firstPositions[$1.slang.lowercased()] ?? .max
                return pos1 < pos2
            }

        return uniqueOrdered
    }
}
