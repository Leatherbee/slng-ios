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
    private var slangs: [SlangData] = []
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
                slang: model.slang,
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
        
        // If there is hash changes or data is empty, sync from JSON.
        if previousHash != currentHash || existing.isEmpty {
            print("Syncing data from JSON...")
            upsertFromJSON()
            if let currentHash {
                defaults?.set(currentHash, forKey: Self.jsonHashKey)
            }
        }
        
        print("Loaded \(existing.count) from Local DB. JSON is not changed.")
    }
    
    private func upsertFromJSON() {
        guard let url = Bundle.main.url(forResource: "slng_data_v1.1", withExtension: "json"),
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
            var newItems: [SlangData] = []
            newItems.reserveCapacity(array.count)
            
            for case let dict as [String: Any] in array {
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                   let slangData = try? decoder.decode(SlangData.self, from: data) {
                    newItems.append(slangData)
                }
            }
            
            let descriptor = FetchDescriptor<SlangModel>()
            let existing = (try? context.fetch(descriptor)) ?? []
            let existingById: [UUID: SlangModel] = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            
            var seenIds = Set<UUID>()
            var processed = 0
            
            for slangData in newItems {
                seenIds.insert(slangData.id)
                
                if let model = existingById[slangData.id] {
                    model.slang = slangData.slang
                    model.translationID = slangData.translationID
                    model.translationEN = slangData.translationEN
                    model.contextID = slangData.contextID
                    model.contextEN = slangData.contextEN
                    model.exampleID = slangData.exampleID
                    model.exampleEN = slangData.exampleEN
                    model.sentiment = slangData.sentiment
                } else {
                    let model = SlangModel(
                        id: slangData.id,
                        slang: slangData.slang,
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
            
            for model in existing where !seenIds.contains(model.id) {
                context.delete(model)
            }
            
            try? context.save()
            print("Sync finished: \(processed) slangs upserted, \(existing.count - seenIds.count) delete if exist.")
        } catch {
            print("Failed to parse slang JSON: \(error)")
        }
    }
    
    private func loadFromJSON() {
        guard !isLoaded else { return }
        isLoaded = true

        guard let url = Bundle.main.url(forResource: "slng_data_v1.1", withExtension: "json"),
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
            var importedCount = 0
            
            for (index, element) in array.enumerated() {
                guard let dict = element as? [String: Any],
                      let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                      let slangData = try? decoder.decode(SlangData.self, from: data) else {
                    continue
                }
                
                let slangModel = SlangModel(
                    id: slangData.id,
                    slang: slangData.slang,
                    translationID: slangData.translationID,
                    translationEN: slangData.translationEN,
                    contextID: slangData.contextID,
                    contextEN: slangData.contextEN,
                    exampleID: slangData.exampleID,
                    exampleEN: slangData.exampleEN,
                    sentiment: slangData.sentiment
                )
                
                context.insert(slangModel)
                importedCount += 1
                
                if index % 500 == 0 {
                    try? context.save()
                }
            }
            
            try? context.save()
            print("Import finished: \(importedCount) slangs imported.")
        } catch {
            print("Failed to parse slang JSON: \(error)")
        }
    }
    
    private func computeJSONHash() -> String? {
        guard let url = Bundle.main.url(forResource: "slng_data_v1.1", withExtension: "json"),
                let data = try? Data(contentsOf: url)
        else {
            print("Cannot find SLNG JSON for hashing")
            return nil
        }
        
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return hex
    }
    
    // TODO: Refactor loadFromJSON to separate the insertion
}
