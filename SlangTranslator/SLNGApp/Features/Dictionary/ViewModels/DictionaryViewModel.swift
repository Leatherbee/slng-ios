//
//  WheelPickerDictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 07/11/25.
//

import Foundation
import SwiftData
internal import Combine

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var data: [SlangModel] = []
    @Published var searchText: String = ""
    @Published var filtered: [SlangModel] = []
    @Published var activeLetter: String? = nil
    @Published var isDraggingLetter: Bool = false
    
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
                if q.isEmpty {
                    self.filtered = self.data
                } else {
                    let lower = q.lowercased()
                    self.filtered = self.data.filter { item in
                        // Cocokkan ke beberapa field utama
                        if item.slang.lowercased().contains(lower) { return true }
                        if item.translationID.lowercased().contains(lower) { return true }
                        if item.translationEN.lowercased().contains(lower) { return true }
                        if item.contextID.lowercased().contains(lower) { return true }
                        if item.contextEN.lowercased().contains(lower) { return true }
                        if item.exampleID.lowercased().contains(lower) { return true }
                        if item.exampleEN.lowercased().contains(lower) { return true }
                        return false
                    }
                }
            }
            .store(in: &cancellables)
    }
}
