//
//  SlangSwiftData.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 05/11/25.
//

import Foundation
import SwiftData

final class SlangSwiftData {
    private var isLoaded = false
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func loadAll() -> [SlangModel] {
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<SlangModel>()
        if let slangs = try? context.fetch(descriptor), !slangs.isEmpty {
            logDebug("Loaded \(slangs.count) slangs from SwiftData.", category: .data)
            return slangs
        }

        logInfo("Importing slangs from JSON...", category: .data)
        if let newSlangs = loadFromJSON() {
            for (index, slang) in newSlangs.enumerated() {
                context.insert(slang)
                if index % 500 == 0 { try? context.save() }
            }
            try? context.save()
            logInfo("Imported \(newSlangs.count) slangs into SwiftData.", category: .data)
            return newSlangs
        }

        return []
    }

    private func loadFromJSON() -> [SlangModel]? {
        guard !isLoaded else { return nil }
        isLoaded = true

        guard let url = Bundle.main.url(forResource: "slng_data_v1.2", withExtension: "json"),
              let stream = InputStream(url: url) else {
            logError("Slang JSON not found!", category: .data)
            return nil
        }

        stream.open()
        defer { stream.close() }

        do {
            // Decode using SlangData helper method
            let allSlangData = try SlangData.decodeFromStream(stream)
            
            // Convert SlangData to SlangModel
            var temp: [SlangModel] = []
            temp.reserveCapacity(allSlangData.count)

            for slangData in allSlangData {
                let slangModel = SlangModel(
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
                temp.append(slangModel)
            }

            logDebug("Finished decoding \(temp.count) slangs from JSON.", category: .data)
            return temp
        } catch {
            logError("Failed to parse slang JSON: \(error)", category: .data)
            return nil
        }
    }
}
