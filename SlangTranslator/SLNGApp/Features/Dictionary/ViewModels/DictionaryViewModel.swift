//
//  DictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import Foundation
import SwiftData
internal import Combine

enum DictionaryDisplayMode {
    case allVariants    // Show all variants separately (like before)
    case groupedByCanonical // Show grouped by canonical form (new)
}

struct SlangGrouped: Identifiable {
    let id = UUID()
    let canonicalForm: String
    let canonicalPronunciation: String
    let variants: [SlangData]
    
    var primaryVariant: SlangData {
        variants.first ?? variants[0]
    }
}

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var displayMode: DictionaryDisplayMode = .groupedByCanonical
    
    @Published var allSlangs: [SlangData] = []      // semua data
    @Published var slangs: [SlangData] = []         // data paginated
    @Published var filteredSlangs: [SlangData] = [] // hasil filter (yang ditampilkan)
    
    @Published var allGroups: [SlangGrouped] = []
    @Published var groups: [SlangGrouped] = []
    @Published var filteredGroups: [SlangGrouped] = []
    
    @Published var searchText: String = ""
    @Published var selectedIndex: Int = 0
    @Published var dragActiveLetter: String? = nil

    private let slangRepo: SlangRepositoryImpl
    private var cancellables = Set<AnyCancellable>()
    private var isLoading: Bool = false

    private var offset: Int = 0
    private var totalCount: Int = 0
    private let pageSize: Int = 100

    init(context: ModelContext) {
        self.slangRepo = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
        setupSearch()
        Task { await loadInitial() }
    }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        offset = 0
 
        // Load all data
        allSlangs = slangRepo.loadAll()
        totalCount = allSlangs.count
        
        // Group by canonical form
        allGroups = groupSlangsByCanonical(allSlangs)
 
        // Initial pagination
        slangs = Array(allSlangs)
        groups = Array(allGroups)
        
        applyFilter()
        isLoading = false
    }
    
    func switchDisplayMode(to mode: DictionaryDisplayMode) {
        displayMode = mode
        applyFilter()
    }
    
    func getSlang(at index: Int) -> SlangData? {
        switch displayMode {
        case .allVariants:
            guard index >= 0, index < filteredSlangs.count else { return nil }
            return filteredSlangs[index]
            
        case .groupedByCanonical:
            guard index >= 0, index < filteredGroups.count else { return nil }
            return filteredGroups[index].primaryVariant
        }
    }
    
    func getGroup(at index: Int) -> SlangGrouped? {
        guard displayMode == .groupedByCanonical else { return nil }
        guard index >= 0, index < filteredGroups.count else { return nil }
        return filteredGroups[index]
    }
    
    // Get count based on mode
    var itemCount: Int {
        switch displayMode {
        case .allVariants:
            return filteredSlangs.count
        case .groupedByCanonical:
            return filteredGroups.count
        }
    }

    func isLetterActive(_ letter: String) -> Bool {
        guard selectedIndex < itemCount else { return false }
        
        switch displayMode {
        case .allVariants:
            guard selectedIndex < filteredSlangs.count else { return false }
            return filteredSlangs[selectedIndex].slang.lowercased().hasPrefix(letter.lowercased())
            
        case .groupedByCanonical:
            guard selectedIndex < filteredGroups.count else { return false }
            return filteredGroups[selectedIndex].canonicalForm.lowercased().hasPrefix(letter.lowercased())
        }
    }

    func handleLetterDrag(_ letter: String) {
        dragActiveLetter = letter
        
        switch displayMode {
        case .allVariants:
            if let index = allSlangs.firstIndex(where: {
                $0.slang.lowercased().hasPrefix(letter.lowercased())
            }) {
                selectedIndex = index
                // Jika belum terload sampai huruf ini, muat datanya
                if index >= slangs.count {
                    let nextOffset = min(index + pageSize, allSlangs.count)
                    slangs = Array(allSlangs.prefix(nextOffset))
                    applyFilter()
                }
            }
            
        case .groupedByCanonical:
            if let index = allGroups.firstIndex(where: {
                $0.canonicalForm.lowercased().hasPrefix(letter.lowercased())
            }) {
                selectedIndex = index
                if index >= groups.count {
                    let nextOffset = min(index + pageSize, allGroups.count)
                    groups = Array(allGroups.prefix(nextOffset))
                    applyFilter()
                }
            }
        }
    }

    func handleLetterDragEnd() {
        dragActiveLetter = nil
    }

    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyFilter()
            }
            .store(in: &cancellables)
    }

    private func applyFilter() {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch displayMode {
        case .allVariants:
            if keyword.isEmpty {
                filteredSlangs = slangs
            } else {
                // Search in all data including new fields
                filteredSlangs = allSlangs.filter {
                    $0.slang.localizedCaseInsensitiveContains(keyword) ||
                    $0.canonicalForm.localizedCaseInsensitiveContains(keyword) ||
                    $0.translationID.localizedCaseInsensitiveContains(keyword) ||
                    $0.translationEN.localizedCaseInsensitiveContains(keyword) ||
                    $0.contextID.localizedCaseInsensitiveContains(keyword) ||
                    $0.contextEN.localizedCaseInsensitiveContains(keyword)
                }
            }
            
        case .groupedByCanonical:
            if keyword.isEmpty {
                filteredGroups = groups
            } else {
                // Search and filter groups
                filteredGroups = allGroups.filter { group in
                    // Search in canonical form
                    group.canonicalForm.localizedCaseInsensitiveContains(keyword) ||
                    // Or search in any variant
                    group.variants.contains { variant in
                        variant.slang.localizedCaseInsensitiveContains(keyword) ||
                        variant.translationID.localizedCaseInsensitiveContains(keyword) ||
                        variant.translationEN.localizedCaseInsensitiveContains(keyword) ||
                        variant.contextID.localizedCaseInsensitiveContains(keyword) ||
                        variant.contextEN.localizedCaseInsensitiveContains(keyword)
                    }
                }
            }
        }
    }
    
    private func groupSlangsByCanonical(_ slangs: [SlangData]) -> [SlangGrouped] {
        // Group by canonicalForm
        let grouped = Dictionary(grouping: slangs, by: { $0.canonicalForm })
        
        // Convert to SlangGroup array and sort
        return grouped.map { (canonical, variants) in
            SlangGrouped(
                canonicalForm: canonical,
                canonicalPronunciation: variants.first?.canonicalPronunciation ?? "",
                variants: variants.sorted { $0.slang < $1.slang }
            )
        }
        .sorted { $0.canonicalForm < $1.canonicalForm }
    }
    
    var totalVariantsCount: Int {
        allSlangs.count
    }
    
    var totalCanonicalCount: Int {
        allGroups.count
    }
    
    var statsText: String {
        switch displayMode {
        case .allVariants:
            return "\(filteredSlangs.count) variants"
        case .groupedByCanonical:
            let variantCount = filteredGroups.reduce(0) { $0 + $1.variants.count }
            return "\(filteredGroups.count) slangs (\(variantCount) variants)"
        }
    }
}

extension DictionaryViewModel {
    // Get all variants for a specific canonical form (for detail view)
    func getVariants(for canonicalForm: String) -> [SlangData] {
        allSlangs.filter { $0.canonicalForm == canonicalForm }
            .sorted { $0.slang < $1.slang }
    }
    
    // Check if a group has multiple variants
    func hasMultipleVariants(at index: Int) -> Bool {
        guard displayMode == .groupedByCanonical,
              index >= 0, index < filteredGroups.count else { return false }
        return filteredGroups[index].variants.count > 1
    }
    
    // Get variant count for a group
    func variantCount(at index: Int) -> Int {
        guard displayMode == .groupedByCanonical,
              index >= 0, index < filteredGroups.count else { return 0 }
        return filteredGroups[index].variants.count
    }
}
