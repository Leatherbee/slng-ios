//
//  DictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import Foundation
internal import Combine

struct DictionaryItems: Identifiable {
    let id = UUID()
    let title: String
    let meaning: String
}

@MainActor
final class DictionaryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var expandedItems: Set<UUID> = []
    private let items: [DictionaryItems] = [
        DictionaryItems(title: "Gabut", meaning: "Gabut adalah oke dan benar"),
        DictionaryItems(title: "Gua", meaning: "Gua is meaning of aku")
    ]
    init() {
        
    }
    
    func getItems() -> [DictionaryItems] {
        if searchText.isEmpty { return items }
        return items.filter {
            $0.title.lowercased().contains(searchText.lowercased()) ||
            $0.meaning.lowercased().contains(searchText.lowercased())
        }
    }
}
