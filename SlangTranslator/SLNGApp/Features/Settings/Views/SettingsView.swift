//
//  SettingsView.swift
//  SlangTranslator
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Settings")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    showSettings = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.Background.primary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(AppColor.Text.primary)
                        )
                }
                .accessibilityLabel("Close")
                .accessibilityIdentifier("SettingsView.Close")
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color(AppColor.Background.secondary))
            
            List {
                Section {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                        Text("Sound Effect")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    HStack {
                        Image(systemName: "circle.dotted.and.circle")
                        Text("Motion")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                        Text("Language")
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
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    HStack {
                        Image(systemName: "star")
                        Text("Rate the App")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .listRowBackground(Color.listRowPrimary)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color(AppColor.Background.secondary))
        }
        .background(Color(AppColor.Background.secondary))
    }
}

#Preview {
    SettingsView(showSettings: .constant(true))
}
