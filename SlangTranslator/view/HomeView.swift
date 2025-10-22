//
//  HomeView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    var body: some View {
        TabView {
            Tab("Translate", systemImage: "translate") {
                TranslateView()
            }


            Tab("Keyboard", systemImage: "keyboard") {
                KeyboardView() //keyboard
            }


            Tab("Dictionary", systemImage: "text.book.closed") {
                TranslateView() //dictionary
            }
        }
    }

    
}

#Preview {
    HomeView()
}
