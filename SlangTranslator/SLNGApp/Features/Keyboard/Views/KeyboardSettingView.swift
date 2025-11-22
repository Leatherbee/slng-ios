//
//  KeyboardSettingView.swift
//  SlangTranslator
//
//  Test searchable di Keyboard tab dengan ScrollView
//

import SwiftUI
import Lottie
import FirebaseAnalytics

struct KeyboardSettingView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @State private var showShareSheetPreview: Bool = false
    @State private var searchText = ""
    
    @AppStorage("settings.autoCorrect", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!)
    private var autoCorrect: Bool = true
    @AppStorage("settings.autoCaps", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!)
    private var autoCapslock: Bool = true
    @AppStorage("settings.keyboardLayout", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!)
        
    private var keyboardLayoutRaw: String = LayoutType.qwerty.rawValue

    private var selectedLayout: LayoutType {
        get { LayoutType(rawValue: keyboardLayoutRaw) ?? .qwerty }
        set { keyboardLayoutRaw = newValue.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                VStack(alignment: .leading, spacing: 8){
                    HStack {
                        Text("Keyboard")
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                        Spacer()
                    }
                    
                    Text("Now you can use this keyboard in any app")
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
                
                VStack(alignment: .center) {
                    LottieView(animation: .named(colorScheme == .light ? "keyboard-change-light" : "keyboard-change-dark"))
                        .looping()
                        .frame(width: 312, height: 268)
                        .padding(.vertical, 10)
                        .accessibilityHidden(true)
                    
                    Text("SLNG keyboard is now enabled")
                        .font(.body)
                        .foregroundStyle(AppColor.Text.primary)
                        .padding(.top, 4)
                    
                    Button {
                        showShareSheetPreview = true
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text("Long press")
                                Image(systemName: "globe")
                                Text("and select SLNG keyboard")
                            }
                            HStack(spacing: 4) {
                                Text("use Share extension")
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 14)
                        .padding(.top, 4)
                    }
                    .accessibilityLabel("Show Instructions")
                    .accessibilityHint("Opens guidance sheet with steps")
                    .accessibilityInputLabels(["Instructions", "Setup Tips", "Show Guide"])
                    .accessibilityIdentifier("KeyboardSettingView.ShowInstructions")
                }

                VStack(spacing: 24) {
                    Group {
                        if #available(iOS 26, *) {
                            VStack(spacing: 4) {
                                Toggle("Auto Capslock", isOn: $autoCapslock)
                                    .padding(.vertical, 2)
                                    .tint(.green)
                                    .accessibilityIdentifier("KeyboardSettingView.AutoCapslockToggle")
                                    .accessibilityInputLabels(["Auto Caps", "Auto Capitalization"])
                                    .onChange(of: autoCapslock) { _, newValue in
                                        Analytics.logEvent("settings_changed", parameters: [
                                            "setting_name": "auto_capslock",
                                            "state": newValue ? "enabled" : "disabled"
                                        ])
                                    }
                            }
                            .padding()
                            .glassEffect(.regular.tint(Color(.systemGray6)).interactive(), in: .rect(cornerRadius: 16))
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 4) {
                                Toggle("Auto Capslock", isOn: $autoCapslock)
                                    .padding(.vertical, 2)
                                    .tint(.green)
                                    .accessibilityIdentifier("KeyboardSettingView.AutoCapslockToggle")
                                    .accessibilityInputLabels(["Auto Caps", "Auto Capitalization"])
                                    .onChange(of: autoCapslock) { _, newValue in
                                        Analytics.logEvent("settings_changed", parameters: [
                                            "setting_name": "auto_capslock",
                                            "state": newValue ? "enabled" : "disabled"
                                        ])
                                    }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    Group {
                        if #available(iOS 26, *) {
                            VStack(alignment: .leading, spacing: 24) {
                            Text("Keyboard Layout")
                                .font(.system(.headline, design: .default, weight: .regular))
                            
                            HStack(spacing: 40) {
                                ForEach(LayoutType.allCases, id: \.self) { layout in
                                    VStack(spacing: 4) {
                                        Circle()
                                            .frame(width: 24, height: 24)
                                            .glassEffect(.regular.tint(selectedLayout == layout ? AppColor.Text.primary : Color(.systemGray6)).interactive())
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .resizable()
                                                    .frame(width: 10, height: 10)
                                                    .foregroundColor(AppColor.Background.primary)
                                                    .opacity(selectedLayout == layout ? 1 : 0)
                                            )
                                            .onTapGesture {
                                                withAnimation(.easeInOut) {
                                                    keyboardLayoutRaw = layout.rawValue
                                                }
                                                Analytics.logEvent("settings_changed", parameters: [
                                                    "setting_name": "keyboard_layout",
                                                    "state": layout.rawValue
                                                ])
                                            }
                                        Text(layout.rawValue)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(.rect)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityLabel(layout.rawValue)
                                    .accessibilityValue(selectedLayout == layout ? "Selected" : "Not selected")
                                    .accessibilityHint("Applies keyboard layout")
                                    .accessibilityInputLabels([layout.rawValue, "\(layout.rawValue) layout", "Select \(layout.rawValue)"])
                                    .accessibilityIdentifier("KeyboardSettingView.Layout.\(layout.rawValue)")
                                    .accessibilityAction {
                                        withAnimation(.easeInOut) {
                                            keyboardLayoutRaw = layout.rawValue
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .glassEffect(.regular.tint(Color(.systemGray6)).interactive(), in: .rect(cornerRadius: 16))
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 24) {
                                Text("Keyboard Layout")
                                    .font(.system(.headline, design: .default, weight: .regular))
                                
                                HStack(spacing: 40) {
                                    ForEach(LayoutType.allCases, id: \.self) { layout in
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(selectedLayout == layout ? AppColor.Text.primary : Color(.systemGray4))
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Image(systemName: "checkmark")
                                                        .resizable()
                                                        .frame(width: 10, height: 10)
                                                        .foregroundColor(AppColor.Background.primary)
                                                        .opacity(selectedLayout == layout ? 1 : 0)
                                                )
                                                .onTapGesture {
                                                    withAnimation(.easeInOut) {
                                                        keyboardLayoutRaw = layout.rawValue
                                                    }
                                                    Analytics.logEvent("settings_changed", parameters: [
                                                        "setting_name": "keyboard_layout",
                                                        "state": layout.rawValue
                                                    ])
                                                }
                                            Text(layout.rawValue)
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                        .contentShape(.rect)
                                        .accessibilityElement(children: .combine)
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityLabel(layout.rawValue)
                                        .accessibilityValue(selectedLayout == layout ? "Selected" : "Not selected")
                                        .accessibilityHint("Applies keyboard layout")
                                        .accessibilityInputLabels([layout.rawValue, "\(layout.rawValue) layout", "Select \(layout.rawValue)"])
                                        .accessibilityIdentifier("KeyboardSettingView.Layout.\(layout.rawValue)")
                                        .accessibilityAction {
                                            withAnimation(.easeInOut) {
                                                keyboardLayoutRaw = layout.rawValue
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationTitle("Keyboard Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showShareSheetPreview) {
            ShareSheetPreviewSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .scrollIndicators(.hidden)
    }
}

struct ShareSheetPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack {
                LottieView(animation: .named("share-extension"))
                    .looping()
                    .frame(width: 500, height: 600)
                    .accessibilityHidden(true)
                
                Text("Copy text and share")
                    .font(.system(.body, design: .default, weight: .regular))
                
                Text("Tap SLNG icon in the list of your apps")
                    .font(.system(.callout, design: .default, weight: .regular))
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .navigationTitle("Share Sheet Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Dismiss share sheet preview")
                    .accessibilityIdentifier("ShareSheetPreview.Close")
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

enum LayoutType: String, CaseIterable {
    case qwerty = "QWERTY"
    case qwertz = "QWERTZ"
    case azerty = "AZERTY"
}

#Preview {
    NavigationStack {
        KeyboardSettingView()
    }
}
