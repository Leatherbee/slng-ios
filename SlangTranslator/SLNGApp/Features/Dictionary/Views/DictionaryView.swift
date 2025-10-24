//
//  DictionaryView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI

struct DictionaryView: View {
    @StateObject private var vm = DictionaryViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(vm.getItems()) { item in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { vm.expandedItems.contains(item.id) },
                            set: { isExpanded in
                                withAnimation {
                                    if isExpanded {
                                        vm.expandedItems.insert(item.id)
                                    } else {
                                        vm.expandedItems.remove(item.id)
                                    }
                                }
                            }
                        ),
                        content: {
                            VStack(alignment: .leading, spacing: 4) {
                                Rectangle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(height: 1)
                                Text("Meaning")
                                    .font(.system(size: 15))
                                Text(item.meaning)
                                    .font(.system(size: 15))
                            }
                            .padding(.leading, 8)
                        },
                        label: {
                            Text(item.title)
                                .font(.headline)
                        }
                    )
                }
            }
            .listStyle(.plain)
            .searchable(text: $vm.searchText, prompt: "Cari kategori atau item")
            .navigationTitle("Dictionary")
        }
    }
}


#Preview {
    DictionaryView()
}
