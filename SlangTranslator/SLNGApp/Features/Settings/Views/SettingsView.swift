//
//  SettingsView.swift
//  SlangTranslator
//

import SwiftUI
import UIKit
import FirebaseAnalytics

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(Router.self) private var route
    @Binding var showSettings: Bool
    @AppStorage("selectedTheme", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var selectedThemeRaw: String = ThemeOption.light.rawValue
    @AppStorage("hapticEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var hapticEnabled: Bool = true
    @AppStorage("reduceMotionEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var reduceMotionEnabled: Bool = false
    @AppStorage("soundEffectEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var soundEffectEnabled: Bool = true
    enum ThemeOption: String { case dark, light }
    
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
                        Toggle("", isOn: $soundEffectEnabled)
                            .tint(.green)
                    }
                    .contentShape(.rect)
                    
                    HStack {
                        Image(systemName: "circle.dotted.and.circle")
                        Text("Reduce Motion")
                        Spacer()
                        Toggle("", isOn: $reduceMotionEnabled)
                            .tint(.green)
                    }
                    .contentShape(.rect)

                    HStack {
                        Image(systemName: "swirl.circle.righthalf.filled")
                        Text("Theme")
                        Spacer()
                        Picker("", selection: $selectedThemeRaw) {
                            Text("Light").tag(ThemeOption.light.rawValue)
                            Text("Dark").tag(ThemeOption.dark.rawValue)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 180)
                    }
                    .contentShape(.rect)
                    
                }
                .listRowBackground(Color.listRowPrimary)
                
                Section {
                    HStack {
                        Image(systemName: "water.waves")
                        Text("Haptic")
                        Spacer()
                        Toggle("", isOn: $hapticEnabled)
                            .tint(.green)
                    }
                    .contentShape(.rect)
                    
                }
                .listRowBackground(Color.listRowPrimary)
                
                Section {
                    Button {
                        guard let url = URL(string: "https://slng.space/") else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        HStack {
                            Image(systemName: "person")
                            Text("About")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .contentShape(.rect)
                    }
                    
                    Button {
                        guard let url = URL(string: "https://apps.apple.com/id/app/slng/id6754663192?action=write-review") else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        HStack {
                            Image(systemName: "star")
                            Text("Rate the App")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .contentShape(.rect)
                    }
                    
                }
                .listRowBackground(Color.listRowPrimary)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color(AppColor.Background.secondary))
            .onChange(of: soundEffectEnabled) { oldValue, newValue in
                Analytics.logEvent("settings_changed", parameters: [
                    "setting_name": "sound_effect",
                    "state": newValue ? "enabled" : "disabled"
                ])
            }
        }
        .background(Color(AppColor.Background.secondary))
        .onAppear {
            let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
            if defaults.object(forKey: "selectedTheme") == nil {
                let style = UIScreen.main.traitCollection.userInterfaceStyle
                selectedThemeRaw = style == .dark ? ThemeOption.dark.rawValue : ThemeOption.light.rawValue
            }
        }
    }
}

#Preview {
    SettingsView(showSettings: .constant(true))
        .environment(Router())
}
