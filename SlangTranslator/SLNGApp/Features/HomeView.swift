//
//  HomeView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @SceneStorage("selectedTab") var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Translate", systemImage: "translate", value: 0) {
                TranslateView()
            }


            Tab("Keyboard", systemImage: "keyboard", value: 1) {
                KeyboardView() //keyboard
            }


            Tab("Dictionary", systemImage: "text.book.closed", value: 2) {
                DictionaryView() //dictionary
            }
            
            if selectedTab == 2 || selectedTab == 3 {
                Tab("Search", systemImage: "magnifyingglass", value: 3, role: .search){
                    DictionaryView()
                }
            }
        
        }
//        .tabViewBottomAccessory {
//            Image(systemName: "star.fill")
//        }
//        .tabBarMinimizeBehavior(.onScrollDown)
    }

    
}

#Preview {
    HomeView()
}
