//
//  WheelPickerDictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
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
    @Published var data: [SlangModel] = []

    @Published var displayMode: DictionaryDisplayMode = .groupedByCanonical
    
    @Published var allSlangs: [SlangData] = []      // semua data
    @Published var slangs: [SlangData] = []         // data paginated
    @Published var filteredSlangs: [SlangData] = [] // hasil filter (yang ditampilkan)
    
    @Published var allGroups: [SlangGrouped] = []
    @Published var groups: [SlangGrouped] = []
    @Published var filteredGroups: [SlangGrouped] = []
    
    @Published var searchText: String = ""
    @Published var filtered: [SlangModel] = []
    @Published var activeLetter: String? = nil
    @Published var isDraggingLetter: Bool = false
    @Published var canonicalGroups: [(canonical: String, variants: [SlangModel])] = []
    @Published var filteredCanonicals: [(canonical: String, variants: [SlangModel])] = []
    
    private var slangRepo: SlangSwiftDataImpl?
    private var context: ModelContext?
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        setupSearch()
    }
    
    func setContext(context: ModelContext) {
        self.context = context
        self.slangRepo = SlangSwiftDataImpl(context: context)
    }
    
    func loadData() {
        guard let slangRepo = slangRepo else { return }
        let groups = slangRepo.fetchGroupedByCanonical()
        canonicalGroups = groups
        filteredCanonicals = groups
        let allData = slangRepo.fetchAll()
        data = allData
        filtered = allData
    }
    
    func handleLetterDrag(_ letter: String) {
        activeLetter = letter
        isDraggingLetter = true
    }

    func handleLetterDragEnd() {
        isDraggingLetter = false
    }

    /// Cari index pertama dari slang yang dimulai dengan huruf tertentu pada list yang sedang ditampilkan
    func indexForLetter(_ letter: String) -> Int? {
        let lower = letter.lowercased()
        return filteredCanonicals.firstIndex(where: { $0.canonical.lowercased().hasPrefix(lower) })
        return filtered.firstIndex(where: { $0.slang.lowercased().hasPrefix(lower) })
    }

    /// Setup reactive search pipeline
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let slangRepo = self.slangRepo else { return }
                if q.isEmpty {
                    self.filteredCanonicals = self.canonicalGroups
                } else {
                    self.filteredCanonicals = slangRepo.fetchGroupedByCanonical(offset: 0, keyword: q)
                }
            }
            .store(in: &cancellables)
    }
}
