//
//  KeyboardView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI

struct KeyboardView: View {
    @StateObject private var viewModel = KeyboardStatusViewModel()
    @AppStorage("hasSetupKeyboard", store: UserDefaults.shared) private var hasSetupKeyboard = false
    @Environment(\.scenePhase) private var scenePhase
    
    var isOnboarding: Bool = false
    var onSkipOnboarding: (() -> Void)? = nil
    var onReturnFromSettings: () -> Void
    var body: some View {
        Group{
            if (viewModel.isKeyboardEnabled || hasSetupKeyboard || viewModel.isFullAccessEnabled) && !isOnboarding {
                KeyboardSettingView()
                    .accessibilityLabel("Keyboard settings")
                    .accessibilityHint("Manage keyboard translator preferences and options")
                    .accessibilityIdentifier("KeyboardView.Settings")
            } else {
                SetupKeyboardView(viewModel: viewModel, onReturnFromSettings: {
                    viewModel.updateKeyboardStatus()
                    onReturnFromSettings()
                }, isOnboarding: isOnboarding, onSkipOnboarding: onSkipOnboarding)
                .accessibilityLabel("Keyboard setup")
                .accessibilityHint("Follow instructions to enable the slang translator keyboard")
                .accessibilityIdentifier("KeyboardView.Setup")
            }
        }
        .onAppear {
            viewModel.updateKeyboardStatus()
        }
        .onChange(of: hasSetupKeyboard) { _, _ in
            viewModel.updateKeyboardStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.updateKeyboardStatus()
            }
        }
        .trackScreen("KeyboardView")
    }
}
