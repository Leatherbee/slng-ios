//
//  MainTabbedView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI
//private let items: [(icon: String, title: String)] = [
//    ("translate", "Translate"),
//    ("keyboard", "Keyboard"),
//    ("text.book.closed", "Dictionary")
//]

enum TabSelection: Hashable {
    case translate
    case keyboard
    case dictionary
}

struct MainTabbedView: View {
    @State private var selectedTab: TabSelection = .translate
    
    var body: some View{
        TabView(selection: $selectedTab) {
            Tab("Translate", systemImage: "translate", value: .translate) {
                TranslateView()
            }
            
            Tab("Keyboard", systemImage: "keyboard", value: .keyboard) {
                KeyboardView()
            }
            
            Tab("Dictionary", systemImage: "text.book.closed", value: .dictionary) {
                DictionaryView()
            }
        }
        .tint(.primary)
    }
    
}

