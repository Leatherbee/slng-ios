//
//  DictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import Foundation
import SwiftData
internal import Combine

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var allSlangs: [SlangData] = []      // semua data
    @Published var slangs: [SlangData] = []         // data paginated
    @Published var filteredSlangs: [SlangData] = [] // hasil filter (yang ditampilkan)
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
 
        allSlangs = slangRepo.loadAll()
        totalCount = allSlangs.count
 
        slangs = Array(allSlangs)
        applyFilter()
        isLoading = false
    }
 

    func getSlang(at index: Int) -> SlangData? {
        guard index >= 0, index < filteredSlangs.count else { return nil }
        let s = filteredSlangs[index]
        return SlangData(
            id: s.id,
            slang: s.slang,
            translationID: s.translationID,
            translationEN: s.translationEN,
            contextID: s.contextID,
            contextEN: s.contextEN,
            exampleID: s.exampleID,
            exampleEN: s.exampleEN,
            sentiment: s.sentiment
        )
    }

    func isLetterActive(_ letter: String) -> Bool {
        guard selectedIndex < filteredSlangs.count else { return false }
        return filteredSlangs[selectedIndex].slang.lowercased().hasPrefix(letter.lowercased())
    }

    func handleLetterDrag(_ letter: String) {
        dragActiveLetter = letter
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
        if keyword.isEmpty {
            filteredSlangs = slangs
        } else {
            // Cari dari semua data
            filteredSlangs = allSlangs.filter {
                $0.slang.localizedCaseInsensitiveContains(keyword) ||
                $0.translationID.localizedCaseInsensitiveContains(keyword) ||
                $0.translationEN.localizedCaseInsensitiveContains(keyword)
            }
        }
    }
}
