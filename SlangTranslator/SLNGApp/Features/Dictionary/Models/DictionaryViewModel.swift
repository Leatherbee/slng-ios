//
//  DictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import Foundation
internal import Combine

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var expandedItems: Set<UUID> = []
    @Published var allSlangs: [SlangData] = []
    
    init() {
        loadAllSlangs()
    }
    
    private func loadAllSlangs() {
        allSlangs = SlangDictionary.shared.slangs
            .sorted { $0.slang.lowercased() < $1.slang.lowercased() }
    }
    
    func getFilteredSlangs() -> [SlangData] {
        if searchText.isEmpty {
            return allSlangs
        }
        return allSlangs.filter {
            $0.slang.localizedCaseInsensitiveContains(searchText) ||
            $0.translationEN.localizedCaseInsensitiveContains(searchText) ||
            $0.translationID.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func getSlang(at index: Int) -> SlangData? {
        let filtered = getFilteredSlangs()
        guard index < filtered.count else { return nil }
        return filtered[index]
    }
}
