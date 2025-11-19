//
//  SettingsView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 19/11/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSettings: Bool
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("Sound Effect")
                    Toggle("", isOn: .constant(true))
                }
                HStack {
                    Text("Motion")
                    Toggle("", isOn: .constant(true))
                }
                HStack {
                    Image(systemName: "globe")
                    Text("Sound Effect")
                }
                HStack {
                    Image(systemName: "swirl.circle.righthalf.filled")
                    Text("Theme")
                }
            }
            .listRowBackground(Color.listRowPrimary)
            
            Section {
                HStack {
                    Image(systemName: "water.waves")
                    Text("Haptic")
                    Spacer()
                    Toggle("", isOn: .constant(true))
                }
            }
            .listRowBackground(Color.listRowPrimary)
            
            Section {
                HStack {
                    Image(systemName: "person")
                    Text("About")
                }
            }
            .listRowBackground(Color.listRowPrimary)
        }
        .navigationBarTitle(Text("Settings"), displayMode: .large)
        .serifNavigationBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Close")
                .accessibilityHint("Dismiss setting view")
                .accessibilityIdentifier("SettingsView.Close")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(AppColor.Background.secondary))
        .scrollIndicators(.hidden)
    }
}

struct SerifNavigationBar: ViewModifier {
    init() {
        let largeTitle = UIFont.preferredFont(forTextStyle: .extraLargeTitle)

        let descriptor = largeTitle.fontDescriptor.withDesign(.serif)!
        let largeFont = UIFont(descriptor: descriptor, size: largeTitle.pointSize)
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: largeFont]
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func serifNavigationBar() -> some View {
        self.modifier(SerifNavigationBar())
    }
}

#Preview {
    NavigationStack {
        SettingsView(showSettings: .constant(false))
    }
}
