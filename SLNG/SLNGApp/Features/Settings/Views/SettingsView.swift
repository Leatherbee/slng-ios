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
    @AppStorage("selectedTheme", store: UserDefaults.shared) private var selectedThemeRaw: String = ThemeOption.system.rawValue
    @AppStorage("hapticEnabled", store: UserDefaults.shared) private var hapticEnabled: Bool = true
    @AppStorage("reduceMotionEnabled", store: UserDefaults.shared) private var reduceMotionEnabled: Bool = false
    @AppStorage("soundEffectEnabled", store: UserDefaults.shared) private var soundEffectEnabled: Bool = true
    @AppStorage("notifications.slangEnabled", store: UserDefaults.shared) private var slangNotificationsEnabled: Bool = false
    @State private var showPermissionDeniedAlert = false
    enum ThemeOption: String { case dark, light, system }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Settings")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    Analytics.logEvent("settings_close_pressed", parameters: nil)
                    showSettings = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .padding(10)
                        .background(
                            Group {
                                if #available(iOS 26, *) {
                                    Circle()
                                        .glassEffect(.regular.interactive())
                                        .frame(width: 44, height: 44)
                                } else {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        )
                }
                .accessibilityLabel("Close")
                .accessibilityIdentifier("SettingsView.Close")
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color(AppColor.Onboarding.background))
            
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
                    
                    Button {
                        Analytics.logEvent("settings_theme_open_pressed", parameters: nil)
                        route.go(to: .settingsTheme)
                    } label: {
                        HStack {
                            Image(systemName: "swirl.circle.righthalf.filled")
                            Text("Theme")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .contentShape(.rect)
                    }
                }
                .listRowSeparatorTint(AppColor.Divider.primary)
                .listRowBackground(AppColor.List.primary)

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
                .listRowSeparatorTint(AppColor.Divider.primary)
                .listRowBackground(AppColor.List.primary)

                Section {
                    HStack {
                        Image(systemName: "bell.badge")
                        Text("Slang Notifications")
                        Spacer()
                        Toggle("", isOn: $slangNotificationsEnabled)
                            .tint(.green)
                            .onChange(of: slangNotificationsEnabled) { oldValue, newValue in
                                Task {
                                    if newValue {
                                        let status = await SlangNotificationManager.shared.checkAuthorizationStatus()
                                        if status == .denied {
                                            slangNotificationsEnabled = false
                                            showPermissionDeniedAlert = true
                                        } else {
                                            await SlangNotificationManager.shared.setEnabled(true)
                                            Analytics.logEvent("settings_changed", parameters: [
                                                "setting_name": "slang_notifications",
                                                "state": "enabled"
                                            ])
                                        }
                                    } else {
                                        await SlangNotificationManager.shared.setEnabled(false)
                                        Analytics.logEvent("settings_changed", parameters: [
                                            "setting_name": "slang_notifications",
                                            "state": "disabled"
                                        ])
                                    }
                                }
                            }
                    }
                    .contentShape(.rect)
                } footer: {
                    Text("Receive a new slang word to learn Indonesian slang.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .listRowSeparatorTint(AppColor.Divider.primary)
                .listRowBackground(AppColor.List.primary)

                Section {
                    Button {
                        Analytics.logEvent("settings_about_open", parameters: nil)
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
                        Analytics.logEvent("settings_rate_open", parameters: nil)
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
                .listRowSeparatorTint(AppColor.Divider.primary)
                .listRowBackground(AppColor.List.primary)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color(AppColor.Onboarding.background))
            .onChange(of: soundEffectEnabled) { oldValue, newValue in
                Analytics.logEvent("settings_changed", parameters: [
                    "setting_name": "sound_effect",
                    "state": newValue ? "enabled" : "disabled"
                ])
            }
        }
        .background(Color(AppColor.Onboarding.background))
        .onAppear {
            let defaults = UserDefaults.shared
            if defaults.object(forKey: "selectedTheme") == nil {
                selectedThemeRaw = ThemeOption.system.rawValue
            }
        }
        .trackScreen("SettingsView")
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive slang notifications, please enable notifications in Settings.")
        }
    }
}

#Preview {
    SettingsView(showSettings: .constant(true))
        .environment(Router())
}
