//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 22/10/25.
//
import SwiftUI

struct DictionaryView: View {
    @SceneStorage("selectedTab") var selectedTab = 0
    
//    @Binding var selectedTab: Int
    var body: some View {
        @State var searchText: String = ""
        
        NavigationStack{
//            List(manager.filteredList.sorted(), id: \.self){ person in
//                Text(person)
//            }
            Text("hello")
            .navigationTitle("Dictionary")
            .isSearchable(selectedTab: selectedTab, searchText: $searchText)
        }
    }
}

#Preview {
    DictionaryView(selectedTab: 3)
}

struct IsSearchable: ViewModifier{
    let selectedTab: Int
    @Binding var searchText: String
    func body(content: Content) -> some View {
        if selectedTab == 3{
            content
                .searchable(text: $searchText)
        }
        else {
            content
        }
    }
}

extension View{
    func isSearchable(selectedTab: Int, searchText: Binding<String>) -> some View{
        self.modifier(IsSearchable(selectedTab: selectedTab, searchText: searchText))
    }
}
