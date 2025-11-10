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
final class WheelPickerDictionaryViewModel: ObservableObject {
    @Published var data: [SlangModel] = []
    @Published var searchText: String = ""
    @Published var activeLetter: String? = nil
    @Published var isDraggingLetter: Bool = false
    
    private var slangRepo: SlangSwiftDataImpl?
    private var context: ModelContext?
    
    init() {}
    
    func setContext(context: ModelContext) {
        self.context = context
        self.slangRepo = SlangSwiftDataImpl(context: context)
    }
    
    func loadData() {
        guard let slangRepo = slangRepo else { return }
        if let allData = slangRepo.fetchAll() {
            data = allData
        }
    }
    
    func handleLetterDrag(_ letter: String) {
        activeLetter = letter
        isDraggingLetter = true
    }

    func handleLetterDragEnd() {
        isDraggingLetter = false
    }

    /// Cari index pertama dari slang yang dimulai dengan huruf tertentu
    func indexForLetter(_ letter: String) -> Int? {
        let lower = letter.lowercased()
        return data.firstIndex(where: { $0.slang.lowercased().hasPrefix(lower) })
    }
}
