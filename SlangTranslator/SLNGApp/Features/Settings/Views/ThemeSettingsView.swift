//
//  ThemeSettingView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 20/11/25.
//

import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme", store: UserDefaults.shared) private var selectedThemeRaw: String = ThemeOption.system.rawValue
    
    enum ThemeOption: String, CaseIterable {
        case system, light, dark
        
        var title: String {
            switch self {
            case .system: return "System"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
        
        var description: String {
            switch self {
            case .system: return "Automatically switch between light and dark themes based on your device settings"
            case .light: return "Use light theme for a bright, clear interface"
            case .dark: return "Use dark theme to reduce eye strain in low light"
            }
        }
    }
    
    private var selectedTheme: ThemeOption {
        ThemeOption(rawValue: selectedThemeRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(ThemeOption.allCases, id: \.self) { theme in
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)) {
                                selectedThemeRaw = theme.rawValue
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: theme.icon)
                                    .foregroundStyle(.primary)
                                    .frame(width: 24)
                                    .scaleEffect(selectedThemeRaw == theme.rawValue ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.5), value: selectedThemeRaw == theme.rawValue)
                                
                                Text(theme.title)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedThemeRaw == theme.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.primary)
                                        .transition(.scale.combined(with: .opacity))
                                        .scaleEffect(1.0)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: selectedThemeRaw == theme.rawValue)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                } header: {
                    Text("Appearance")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundStyle(.primary)
                        .padding(.bottom, 24)
                }
                .listRowBackground(AppColor.List.primary)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color(AppColor.Onboarding.background))
        }
        .background(Color(AppColor.Onboarding.background))
    }
}

// Custom bouncy button style
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
}
