//
//  MainTabbedView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI
private let items: [(icon: String, title: String)] = [
    ("translate", "Translate"),
    ("keyboard", "Keyboard"),
    ("text.book.closed", "Dictionary")
]
struct MainTabbedView: View {
    var body: some View{
        TabView {
            ForEach(items, id: \.title) { item in
                Text(item.title)
                    .tabItem {
                        VStack {
                            Image(systemName: item.icon)
                                .font(.system(size: 12))
                            Text(item.title)
                                .font(.system(size: 12)) 
                        }
                    }
            }
            
        }
        .tint(Color.black)
    }
    
}

