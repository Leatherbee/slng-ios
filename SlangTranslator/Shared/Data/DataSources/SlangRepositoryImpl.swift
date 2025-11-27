//
//  SlangRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import Foundation
import SwiftData
import CryptoKit

final class SlangRepositoryImpl: SlangRepository {
    private let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")
    private static let jsonHashKey = "slng_json_hash"
    private let container: ModelContainer
    private let context: ModelContext
    private var isLoaded: Bool = false
    
    init(container: ModelContainer) {
        self.container = container
        self.context = ModelContext(container)
    }
    
    func loadAll() -> [SlangData] {
        if !isLoaded {
            LoadFromLocalDB()
        }
        
        let descriptor = FetchDescriptor<SlangModel>(
            sortBy: [SortDescriptor(\.slang, order: .forward)]
        )
        
        guard let models = try? context.fetch(descriptor) else {
            print("Failed to fetch from Local DB")
            return []
        }
        
        return models.map { model in
            SlangData(
                id: model.id,
                canonicalForm: model.canonicalForm,
                canonicalPronunciation: model.canonicalPronunciation,
                slang: model.slang,
                pronunciation: model.pronunciation,
                translationID: model.translationID,
                translationEN: model.translationEN,
                contextID: model.contextID,
                contextEN: model.contextEN,
                exampleID: model.exampleID,
                exampleEN: model.exampleEN,
                sentiment: model.sentiment
            )
        }
    }
    
    private func LoadFromLocalDB() {
        guard !isLoaded else { return }
        isLoaded = true
        
        let previousHash = defaults?.string(forKey: Self.jsonHashKey)
        let currentHash = computeJSONHash()
        
        let descriptor = FetchDescriptor<SlangModel>()
        let existing = (try? context.fetch(descriptor)) ?? []
        
        let shouldSync = (previousHash != currentHash) || existing.isEmpty
        if shouldSync {
            print("Syncing data from JSON...")
            upsertFromJSON()
            if let currentHash { defaults?.set(currentHash, forKey: Self.jsonHashKey) }
            let final = (try? context.fetch(descriptor)) ?? []
            print("Loaded \(final.count) from Local DB. JSON synced.")
        } else {
            print("Loaded \(existing.count) from Local DB. JSON is not changed.")
        }
    }
    
    private func upsertFromJSON() {
        guard let url = Bundle.main.url(forResource: "slng_data_v1.2", withExtension: "json"),
              let stream = InputStream(url: url) else {
            print("Slang JSON not found!")
            return
        }
        
        do {
            let allSlangs = try SlangData.decodeFromStream(stream)
            let canonicalCount = Set(allSlangs.map { $0.canonicalForm }).count
            print("Decoded \(allSlangs.count) slangs across \(canonicalCount) canonical forms")
            
            let descriptor = FetchDescriptor<SlangModel>()
            let existing = (try? context.fetch(descriptor)) ?? []
            let existingById: [UUID: SlangModel] = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            
            var seenIds = Set<UUID>()
            var processed = 0
            
            for slangData in allSlangs {
                seenIds.insert(slangData.id)
                
                if let model = existingById[slangData.id] {
                    // Update existing
                    model.canonicalForm = slangData.canonicalForm
                    model.canonicalPronunciation = slangData.canonicalPronunciation
                    model.slang = slangData.slang
                    model.pronunciation = slangData.pronunciation
                    model.translationID = slangData.translationID
                    model.translationEN = slangData.translationEN
                    model.contextID = slangData.contextID
                    model.contextEN = slangData.contextEN
                    model.exampleID = slangData.exampleID
                    model.exampleEN = slangData.exampleEN
                    model.sentiment = slangData.sentiment
                } else {
                    // Insert new
                    let model = SlangModel(
                        id: slangData.id,
                        canonicalForm: slangData.canonicalForm,
                        canonicalPronunciation: slangData.canonicalPronunciation,
                        slang: slangData.slang,
                        pronunciation: slangData.pronunciation,
                        translationID: slangData.translationID,
                        translationEN: slangData.translationEN,
                        contextID: slangData.contextID,
                        contextEN: slangData.contextEN,
                        exampleID: slangData.exampleID,
                        exampleEN: slangData.exampleEN,
                        sentiment: slangData.sentiment
                    )
                    context.insert(model)
                }
                
                processed += 1
                if processed % 500 == 0 {
                    try? context.save()
                }
            }
            
            let toDelete = existing.filter { !seenIds.contains($0.id) }
            for model in toDelete { context.delete(model) }
            
            try? context.save()
            print("Sync finished: \(processed) slangs upserted, \(toDelete.count) deleted.")
        } catch {
            print("Failed to parse slang JSON: \(error)")
        }
    }
    
    private func computeJSONHash() -> String? {
        guard let url = Bundle.main.url(forResource: "slng_data_v1.2", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Cannot find SLNG JSON for hashing")
            return nil
        }
        
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex
    }
}
