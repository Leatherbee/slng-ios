//
//  WheelPickerDictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
//

import Foundation
import SwiftData
internal import Combine
import FirebaseAnalytics

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var data: [SlangModel] = []
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
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            filteredCanonicals = slangRepo?.fetchGroupedByCanonical(offset: 0, keyword: q) ?? []
        }
    }
    
    func loadData() {
        guard let slangRepo = slangRepo else { return }
        let groups = slangRepo.fetchGroupedByCanonical()
        canonicalGroups = groups
        filteredCanonicals = groups
    }
    
    func handleLetterDrag(_ letter: String) {
        activeLetter = letter
        isDraggingLetter = true
        Analytics.logEvent("dictionary_jump_letter", parameters: ["letter": letter])
    }

    func handleLetterDragEnd() {
        isDraggingLetter = false
    }

    /// Cari index pertama dari slang yang dimulai dengan huruf tertentu pada list yang sedang ditampilkan
    func indexForLetter(_ letter: String) -> Int? {
        let lower = letter.lowercased()
        return filteredCanonicals.firstIndex(where: { $0.canonical.lowercased().hasPrefix(lower) })
    }

    /// Setup reactive search pipeline
    private func setupSearch() {
        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(80), scheduler: RunLoop.main)
            .flatMap { [weak self] q -> AnyPublisher<[(canonical: String, variants: [SlangModel])], Never> in
                guard let self = self else { return Just([]).eraseToAnyPublisher() }
                if q.isEmpty {
                    return Just(self.canonicalGroups).eraseToAnyPublisher()
                }
                return Deferred {
                    Future { promise in
                        let fetched = self.slangRepo?.fetchGroupedByCanonical(offset: 0, keyword: q) ?? []
                        let ranked = self.rank(groups: fetched, query: q)
                        promise(.success(ranked))
                    }
                }
                .subscribe(on: DispatchQueue.global(qos: .userInitiated))
                .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] groups in
                guard let self = self else { return }
                self.filteredCanonicals = groups
                Analytics.logEvent("dictionary_search", parameters: [
                    "query_length": self.searchText.trimmingCharacters(in: .whitespacesAndNewlines).count,
                    "result_count": groups.count
                ])
            }
            .store(in: &cancellables)
    }

    private func rank(groups: [(canonical: String, variants: [SlangModel])], query: String) -> [(canonical: String, variants: [SlangModel])] {
        let q = query.lowercased()
        func score(_ g: (canonical: String, variants: [SlangModel])) -> Int {
            var s = 0
            let c = g.canonical.lowercased()
            if c == q { s = max(s, 100) }
            if c.hasPrefix(q) { s = max(s, 80) }
            if c.contains(q) { s = max(s, 60) }
            for v in g.variants {
                let vs = v.slang.lowercased()
                if vs == q { s = max(s, 90) }
                if vs.hasPrefix(q) { s = max(s, 70) }
                if vs.contains(q) { s = max(s, 50) }
            }
            return s
        }
        return groups
            .sorted { (a, b) in
                let sa = score(a)
                let sb = score(b)
                if sa == sb { return a.canonical < b.canonical }
                return sa > sb
            }
    }
}
