//
//  TranslateSentenceUseCaseImpl.swift
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

        let rawText = text.lowercased()

        let foundRaw = findMatchesSlangs(in: rawText, from: slangs)

        let foundFuzzy = findFuzzyElongationMatches(
            in: rawText,
            from: slangs,
            excluding: foundRaw.map { $0.range }
        )

        var found = foundRaw + foundFuzzy

        if found.isEmpty {
            let normalizedText = text.normalizedForSlangMatching()
            found = findMatchesSlangs(in: normalizedText, from: slangs)
            let filtered = filterSlangBasedOnSentiment(found, in: normalizedText, sentiment: sentiment)
            let uniqueOrdered = deduplicateAndSortSlangs(filtered, found: found)
            return uniqueOrdered
        }

        let filtered = filterSlangBasedOnSentiment(found, in: rawText, sentiment: sentiment)
        let uniqueOrdered = deduplicateAndSortSlangs(filtered, found: found)
        return uniqueOrdered
    }
    
    private func findMatchesSlangs(in text: String, from slangs: [SlangData]) -> [(data: SlangData, range: NSRange)] {
        var results: [(data: SlangData, range: NSRange)] = []
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        let orderedSlangs = slangs.sorted { $0.slang.count > $1.slang.count }
        var occupiedRanges: [NSRange] = []

        for slangData in orderedSlangs {
            let slang = slangData.slang.lowercased()
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: slang))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }

            regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                let overlaps = occupiedRanges.contains { NSIntersectionRange($0, range).length > 0 }
                if overlaps { return }

                results.append((data: slangData, range: range))
                occupiedRanges.append(range)
            }
        }
        
        return results
    }

    private func findFuzzyElongationMatches(
        in text: String,
        from slangs: [SlangData],
        excluding existingRanges: [NSRange]
    ) -> [(data: SlangData, range: NSRange)] {
        var results: [(data: SlangData, range: NSRange)] = []
        let fullRange = NSRange(location: 0, length: text.utf16.count)

        let orderedSlangs = slangs.sorted { $0.slang.count > $1.slang.count }
        var occupiedRanges: [NSRange] = existingRanges

        for slangData in orderedSlangs {
            let base = slangData.slang.lowercased()
            let fuzzy = base.map { ch in
                NSRegularExpression.escapedPattern(for: String(ch)) + "+"
            }.joined()
            let pattern = "\\b" + fuzzy + "\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }

            regex.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
                guard let range = match?.range else { return }
                let overlaps = occupiedRanges.contains { NSIntersectionRange($0, range).length > 0 }
                if overlaps { return }

                results.append((data: slangData, range: range))
                occupiedRanges.append(range)
            }
        }

        return results
    }
    
    // Group by normalized slang, but handle sentiment with canonical awareness
    private func filterSlangBasedOnSentiment(
        _ found: [(data: SlangData, range: NSRange)],
        in text: String,
        sentiment: SentimentType?
    ) -> [SlangData] {
        // Group by normalized slang to preserve exact matching behavior
        let grouped = Dictionary(grouping: found, by: { $0.data.slang.normalizedForSlangMatching() })

        return grouped.values.compactMap { group in
            guard let firstRange = group.first?.range, let swiftRange = Range(firstRange, in: text) else {
                return group.first?.data
            }
            let token = String(text[swiftRange])
            return selectVariantFromGroup(group.map { $0.data }, inputToken: token, sentiment: sentiment)
        }
    }
    
    // Better variant selection with canonical awareness
    private func selectVariantFromGroup(
        _ variants: [SlangData],
        inputToken: String,
        sentiment: SentimentType?
    ) -> SlangData? {
        // Edge case: single variant
        if variants.count == 1 {
            return variants.first
        }
        
        let lowerToken = inputToken.lowercased()

        // Priority 1: Exact match (case-insensitive)
        if let exact = variants.first(where: { $0.slang.lowercased() == lowerToken }) {
            return exact
        }

        // Priority 2: Sort by multiple criteria
        let target = lowerToken.maxRepeatRun()
        let sorted = variants.sorted { a, b in
            // Criterion 1: Closest character repetition pattern (most important for elongation)
            let da = abs(a.slang.lowercased().maxRepeatRun() - target)
            let db = abs(b.slang.lowercased().maxRepeatRun() - target)
            if da != db { return da < db }

            // Criterion 2: Matching sentiment (if provided)
            if let sentiment = sentiment {
                let sa = (a.sentiment == sentiment) ? 0 : 1
                let sb = (b.sentiment == sentiment) ? 0 : 1
                if sa != sb { return sa < sb }
            }

            // Criterion 3: Prefer neutral sentiment as fallback
            let na = (a.sentiment == .neutral) ? 0 : 1
            let nb = (b.sentiment == .neutral) ? 0 : 1
            if na != nb { return na < nb }

            // Criterion 4: Longer slang is more specific
            return a.slang.count > b.slang.count
        }

        return sorted.first ?? variants.first
    }
    
    // Deduplicate by canonicalForm to avoid showing multiple variants of same slang
    private func deduplicateAndSortSlangs(
        _ filtered: [SlangData],
        found: [(data: SlangData, range: NSRange)]
    ) -> [SlangData] {
        var firstPositions: [String: Int] = [:]
        
        // Track first position by canonicalForm
        for slang in found {
            let key = slang.data.canonicalForm
            if firstPositions[key] == nil {
                firstPositions[key] = slang.range.location
            }
        }
        
        // Deduplicate by canonicalForm (keep only first/best variant of each canonical form)
        let unique = filtered.reduce(into: [String: SlangData]()) { dict, slang in
            let key = slang.canonicalForm
            if dict[key] == nil {
                dict[key] = slang
            }
        }
        
        // Sort by first occurrence position in text
        return unique.values.sorted {
            let pos1 = firstPositions[$0.canonicalForm] ?? .max
            let pos2 = firstPositions[$1.canonicalForm] ?? .max
            return pos1 < pos2
        }
    }

}
