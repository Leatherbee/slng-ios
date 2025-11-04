//
//  Untitled.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation

protocol TranslateSentenceUseCase {
    func execute(_ text: String) async throws -> TranslationResult
}

final class TranslateSentenceUseCaseImpl: TranslateSentenceUseCase {
    private let translationRepository: TranslationRepository
    private let slangRepository: SlangRepository

    init(translationRepository: TranslationRepository, slangRepository: SlangRepository) {
        self.translationRepository = translationRepository
        self.slangRepository = slangRepository
    }

    func execute(_ text: String) async throws -> TranslationResult {
        
        // TODO: Implement translation repos
        let translation = try await translationRepository.translateSentence(text)
        
        let detectedSlangs = findSlang(in: text, matching: translation.sentiment)
        
        return TranslationResult(translation: translation, detectedSlangs: detectedSlangs)
        
        // TODO: Logging service
    }
    
    private func findSlang(in text: String, matching sentiment: SentimentType?) -> [SlangData] {
        let slangs = slangRepository.loadAll()
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
