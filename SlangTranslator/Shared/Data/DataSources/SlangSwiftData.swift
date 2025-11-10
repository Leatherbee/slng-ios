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
            print("Loaded \(slangs.count) slangs from SwiftData.")
            return slangs
        }

        print("Importing slangs from JSON...")
        if let newSlangs = loadFromJSON() {
            for (index, slang) in newSlangs.enumerated() {
                context.insert(slang)
                if index % 500 == 0 { try? context.save() }
            }
            try? context.save()
            print("Imported \(newSlangs.count) slangs into SwiftData.")
            return newSlangs
        }

        return []
    }

    private func loadFromJSON() -> [SlangModel]? {
        guard !isLoaded else { return nil }
        isLoaded = true

        guard let url = Bundle.main.url(forResource: "slng_data_v1.1", withExtension: "json"),
              let stream = InputStream(url: url) else {
            print("Slang JSON not found!")
            return nil
        }

        stream.open()
        defer { stream.close() }

        do {
            guard let array = try JSONSerialization.jsonObject(with: stream, options: []) as? [Any] else {
                print("Invalid JSON format")
                return nil
            }

            let decoder = JSONDecoder()
            var temp: [SlangModel] = []
            temp.reserveCapacity(array.count)

            for case let dict as [String: Any] in array {
                if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                   let slangData = try? decoder.decode(SlangData.self, from: data) {
                    // Convert ke model SwiftData
                    let slang = SlangModel(id: slangData.id, slang: slangData.slang, translationID: slangData.translationID, translationEN: slangData.translationEN, contextID: slangData.contextID, contextEN: slangData.contextEN, exampleID: slangData.exampleID, exampleEN: slangData.exampleEN, sentiment: slangData.sentiment)
                    temp.append(slang)
                }
            }

            print("Finished decoding \(temp.count) slangs from JSON.")
            return temp
        } catch {
            print("Failed to parse slang JSON: \(error)")
            return nil
        }
    }
}
