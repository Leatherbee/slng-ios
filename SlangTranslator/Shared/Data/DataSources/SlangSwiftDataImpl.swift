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
    
    // Fetch data based on lazy load with updated search fields
    func fetch(offset: Int = 0, keyword: String? = nil) -> [SlangModel] {
        var predicate: Predicate<SlangModel>? = nil
        
        if let keyword, !keyword.isEmpty {
            predicate = #Predicate<SlangModel> { slang in
                slang.slang.localizedStandardContains(keyword) ||
                slang.canonicalForm.localizedStandardContains(keyword)
            }
        }
        
        var descriptor = FetchDescriptor<SlangModel>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.canonicalForm, order: .forward),
                SortDescriptor(\.slang, order: .forward)
            ]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = offset
        
        do {
            return try context.fetch(descriptor)
        } catch {
            logError("Failed to fetch slangs: \(error)", category: .data)
            return []
        }
    }
    
    func fetchAll() -> [SlangModel] {
        let descriptor = FetchDescriptor<SlangModel>(
            sortBy: [
                SortDescriptor(\.canonicalForm, order: .forward),
                SortDescriptor(\.slang, order: .forward)
            ]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // NEW: Fetch by canonical form (useful for showing all variants)
    func fetchByCanonicalForm(_ canonicalForm: String) -> [SlangModel] {
        let predicate = #Predicate<SlangModel> { slang in
            slang.canonicalForm == canonicalForm
        }
        
        let descriptor = FetchDescriptor<SlangModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.slang, order: .forward)]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // NEW: Fetch grouped by canonical form (for dictionary view)
    func fetchGroupedByCanonical(offset: Int = 0, keyword: String? = nil) -> [(canonical: String, variants: [SlangModel])] {
        let allSlangs: [SlangModel]
        if let keyword, !keyword.isEmpty {
            allSlangs = fetchAllMatching(keyword: keyword)
        } else {
            allSlangs = fetchAll()
        }
        
        let grouped = Dictionary(grouping: allSlangs, by: { $0.canonicalForm })
        
        return grouped
            .sorted { $0.key < $1.key }
            .map { (canonical: $0.key, variants: $0.value.sorted { $0.slang < $1.slang }) }
    }
    
    // NEW: Fetch all rows matching keyword without pagination
    private func fetchAllMatching(keyword: String) -> [SlangModel] {
        let predicate = #Predicate<SlangModel> { slang in
            slang.slang.localizedStandardContains(keyword) ||
            slang.canonicalForm.localizedStandardContains(keyword)
        }
        
        let descriptor = FetchDescriptor<SlangModel>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.canonicalForm, order: .forward),
                SortDescriptor(\.slang, order: .forward)
            ]
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func totalCount(keyword: String? = nil) -> Int {
        var predicate: Predicate<SlangModel>? = nil
        
        if let keyword, !keyword.isEmpty {
            predicate = #Predicate<SlangModel> { slang in
                slang.slang.localizedStandardContains(keyword) ||
                slang.canonicalForm.localizedStandardContains(keyword)
            }
        }
        
        let descriptor = FetchDescriptor<SlangModel>(predicate: predicate)
        do {
            return try context.fetch(descriptor).count
        } catch {
            logError("Failed to count slangs: \(error)", category: .data)
            return 0
        }
    }
    
    // NEW: Count unique canonical forms (useful for showing dictionary size)
    func totalCanonicalCount(keyword: String? = nil) -> Int {
        let allSlangs = keyword != nil ? fetch(offset: 0, keyword: keyword) : fetchAll()
        let uniqueCanonicals = Set(allSlangs.map { $0.canonicalForm })
        return uniqueCanonicals.count
    }
}
