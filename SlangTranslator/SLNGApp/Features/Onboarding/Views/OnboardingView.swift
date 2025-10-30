//
//  OnboardingView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI
 
struct OnboardingView: View {
    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let items: [String]
    }
    
    let categories: [Category] = [
        Category(name: "Buah", items: ["Apel", "Jeruk", "Mangga", "Semangka", "Pisang"]),
        Category(name: "Sayur", items: ["Bayam", "Wortel", "Kangkung", "Brokoli", "Tomat"]),
        Category(name: "Daging", items: ["Ayam", "Sapi", "Kambing", "Ikan", "Udang"])
    ]
    
    @State private var expandedCategories: Set<UUID> = [] // bisa buka banyak
    @State private var searchText: String = ""
    
    var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.compactMap { category in
                let matchedItems = category.items.filter { $0.localizedCaseInsensitiveContains(searchText) }
                if category.name.localizedCaseInsensitiveContains(searchText) || !matchedItems.isEmpty {
                    return Category(name: category.name, items: matchedItems)
                } else {
                    return nil
                }
            }
        }
    }
    
    // MARK: - View
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCategories) { category in
                    Section {
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedCategories.contains(category.id) },
                                set: { isExpanded in
                                    withAnimation {
                                        if isExpanded {
                                            expandedCategories.insert(category.id)
                                        } else {
                                            expandedCategories.remove(category.id)
                                        }
                                    }
                                }
                            ),
                            content: {
                                ForEach(category.items, id: \.self) { item in
                                    Text(item)
                                        .padding(.leading, 8)
                                }
                            },
                            label: {
                                Text(category.name)
                                    .font(.headline)
                            }
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Makanan")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always) ,prompt: "Cari kategori atau item")
        }
    }
}


#Preview {
    OnboardingView()
}
