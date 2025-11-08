//
//  Untitled.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation

protocol TranslateSentenceUseCase {
    func execute(_ text: String) async throws -> TranslationResult
    func peekCache(_ text: String) -> TranslationResponse?
}

final class TranslateSentenceUseCaseImpl: TranslateSentenceUseCase {
    private let translationRepository: TranslationRepository
    private let slangRepository: SlangRepository

    init(translationRepository: TranslationRepository, slangRepository: SlangRepository) {
        self.translationRepository = translationRepository
        self.slangRepository = slangRepository
    }

    func execute(_ text: String) async throws -> TranslationResult {
        let translation = try await translationRepository.translateSentence(text)
        let detectedSlangs = findSlang(in: text, matching: translation.sentiment)
        return TranslationResult(translation: translation, detectedSlangs: detectedSlangs)
    }
    
    func peekCache(_ text: String) -> TranslationResponse? {
        let normalized = text.lowercased()
        return translationRepository.fetchCachedTranslation(for: normalized)
    }
    
    private func findSlang(in text: String, matching sentiment: SentimentType?) -> [SlangData] {
        let slangs = slangRepository.loadAll()
        let normalizedText = text.normalizedForSlangMatching()
        
        let found = findMatchesSlangs(in: normalizedText, from: slangs)
        let filtered = filterSlangBasedOnSentiment(found, sentiment: sentiment)
        let uniqueOrdered = deduplicateAndSortSlangs(filtered, found: found)
        
        return uniqueOrdered
    }
    
    private func findMatchesSlangs(in text: String, from slangs: [SlangData]) -> [(data: SlangData, range: NSRange)] {
        var results: [(data: SlangData, range: NSRange)] = []
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        for slangData in slangs {
            let slang = slangData.slang.lowercased()
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: slang))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }

            regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                if let range = match?.range {
                    results.append((data: slangData, range: range))
                }
            }
        }
        
        return results
    }
    
    private func filterSlangBasedOnSentiment(
        _ found: [(data: SlangData, range: NSRange)],
        sentiment: SentimentType?
    ) -> [SlangData] {
        let grouped = Dictionary(grouping: found, by: { $0.data.slang.lowercased() })
        
        return grouped.values.compactMap { group in
            let variants = group.map { $0.data }
            if variants.count == 1 {
                return variants.first
            }
            
            return selectVariant(from: variants, sentiment: sentiment)
        }
    }
    
    private func selectVariant(from variants: [SlangData], sentiment: SentimentType?) -> SlangData? {
        if let sentiment = sentiment {
            if let exact = variants.first(where: { $0.sentiment == sentiment }) {
                return exact
            }
            if let neutral = variants.first(where: { $0.sentiment == .neutral }) {
                return neutral
            }
            return variants.first
        } else {
            return variants.first(where: { $0.sentiment == .neutral }) ?? variants.first
        }
    }
    
    private func deduplicateAndSortSlangs(
        _ filtered: [SlangData],
        found: [(data: SlangData, range: NSRange)]
    ) -> [SlangData] {
        var firstPositions: [String: Int] = [:]
        
        for slang in found {
            let key = slang.data.slang.lowercased()
            if firstPositions[key] == nil {
                firstPositions[key] = slang.range.location
            }
        }
        
        let unique = filtered.reduce(into: [String: SlangData]()) { dict, slang in
            let key = slang.slang.lowercased()
            if dict[key] == nil {
                dict[key] = slang
            }
        }
        
        return unique.values.sorted {
            let pos1 = firstPositions[$0.slang.lowercased()] ?? .max
            let pos2 = firstPositions[$1.slang.lowercased()] ?? .max
            return pos1 < pos2
        }
    }

}
