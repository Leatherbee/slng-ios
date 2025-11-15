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
        let trSent = translation.sentiment?.rawValue ?? "nil"
        print("Debug overall sentence sentiment=\(trSent) text=\(text)")
        let detectedSlangs = findSlang(in: text, matching: translation.sentiment)
        let sentimentsList = detectedSlangs.map { "\($0.slang):\($0.sentiment.rawValue)" }.joined(separator: ", ")
        let sentimentsOut = sentimentsList.isEmpty ? "none" : sentimentsList
        print("Debug detected slangs sentiments=\(sentimentsOut)")
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
    
    // Original sorting strategy from Test.swift
    private func selectVariantFromGroup(
        _ variants: [SlangData],
        inputToken: String,
        sentiment: SentimentType?
    ) -> SlangData? {
        let lowerToken = inputToken.lowercased()
        let sRaw = sentiment?.rawValue ?? "nil"
        let variantsDesc = variants.map { "\($0.slang):\($0.sentiment.rawValue)" }.joined(separator: ", ")
        print("Debug selecting variant for token=\(lowerToken) sentiment=\(sRaw)")
        print("Debug variants for token=\(lowerToken) -> \(variantsDesc)")
        let exactMatches = variants.filter { $0.slang.lowercased() == lowerToken }
        if !exactMatches.isEmpty {
            if let s = sentiment, let pick = exactMatches.first(where: { $0.sentiment == s }) {
                print("Debug chosen variant=\(pick.slang) sentiment=\(pick.sentiment.rawValue)")
                return pick
            }
            if let pickNeutral = exactMatches.first(where: { $0.sentiment == .neutral }) {
                print("Debug chosen variant=\(pickNeutral.slang) sentiment=\(pickNeutral.sentiment.rawValue)")
                return pickNeutral
            }
            let pick = exactMatches.max(by: { $0.slang.count < $1.slang.count })!
            print("Debug chosen variant=\(pick.slang) sentiment=\(pick.sentiment.rawValue)")
            return pick
        }

        let target = lowerToken.maxRepeatRun()
        let sorted = variants.sorted { a, b in
            // Closest character repetition pattern
            let da = abs(a.slang.lowercased().maxRepeatRun() - target)
            let db = abs(b.slang.lowercased().maxRepeatRun() - target)
            if da != db { return da < db }

            // Prefer matching sentiment when available
            if let s = sentiment {
                let sa = (a.sentiment == s) ? 0 : 1
                let sb = (b.sentiment == s) ? 0 : 1
                if sa != sb { return sa < sb }
            }

            // Prefer neutral as fallback
            let na = (a.sentiment == .neutral) ? 0 : 1
            let nb = (b.sentiment == .neutral) ? 0 : 1
            if na != nb { return na < nb }

            // Longer slang is more specific
            return a.slang.count > b.slang.count
        }

        let chosen = sorted.first ?? variants.first
        let chosenSent = chosen?.sentiment.rawValue ?? "nil"
        print("Debug chosen variant=\(chosen?.slang ?? "-") sentiment=\(chosenSent)")
        return chosen
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
