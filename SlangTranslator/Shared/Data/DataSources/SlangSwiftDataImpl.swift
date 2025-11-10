//
//  SlangSwiftDataImpl.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 05/11/25.
//
import Foundation
import SwiftData

final class SlangSwiftDataImpl {
    private let context: ModelContext
    private let pageSize: Int
    
    init(context: ModelContext, pageSize: Int = 50) {
        self.context = context
        self.pageSize = pageSize
    }
    
    /// Ambil data berdasarkan offset (untuk lazy load)
    func fetch(offset: Int = 0, keyword: String? = nil) async throws -> [SlangModel] {
        var predicate: Predicate<SlangModel>? = nil
        
        if let keyword, !keyword.isEmpty {
            predicate = #Predicate<SlangModel> { slang in
                slang.slang.localizedStandardContains(keyword) ||
                slang.translationID.localizedStandardContains(keyword) ||
                slang.translationEN.localizedStandardContains(keyword)
            }
        }
        
        var descriptor = FetchDescriptor<SlangModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.slang, order: .forward)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = offset

        
        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch slangs: \(error)")
            return []
        }
    }
    
    func fetchAll() -> [SlangModel]? {
        let descriptor = FetchDescriptor<SlangModel>(
            sortBy: [SortDescriptor(\.slang, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    
    func totalCount(keyword: String? = nil) -> Int {
        var predicate: Predicate<SlangModel>? = nil
        
        if let keyword, !keyword.isEmpty {
            predicate = #Predicate<SlangModel> { slang in
                slang.slang.localizedStandardContains(keyword) ||
                slang.translationID.localizedStandardContains(keyword) ||
                slang.translationEN.localizedStandardContains(keyword)
            }
        }
        
        let descriptor = FetchDescriptor<SlangModel>(predicate: predicate)
        do {
            return try context.fetch(descriptor).count
        } catch {
            print("❌ Failed to count slangs: \(error)")
            return 0
        }
    }
}
