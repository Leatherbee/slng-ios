//
//  SlangRepositoryImpl.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import Foundation

final class SlangRepositoryImpl: SlangRepository {
    private var slangs: [SlangData] = []
    private var isLoaded: Bool = false
    
    func loadAll() -> [SlangData] {
        if !isLoaded {
            loadFromJSON()
        }
        
        return slangs
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
}
