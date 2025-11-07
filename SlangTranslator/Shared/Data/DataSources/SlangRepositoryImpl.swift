//
//  SlangRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import Foundation
import SwiftData

final class SlangRepositoryImpl: SlangRepository {
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
        
        let descriptor = FetchDescriptor<SlangModel>()
        if let slangs = try? context.fetch(descriptor), !slangs.isEmpty {
            print("Loaded \(slangs.count) slangs from Local DB.")
            return
        }
        print("Local DB is empty, importing from JSON...")
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
    
    // TODO: Refactor loadFromJSON to separate the insertion
}
