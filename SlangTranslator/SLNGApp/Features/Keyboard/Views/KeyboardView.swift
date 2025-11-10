//
//  KeyboardView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI

struct KeyboardView: View {
    var onReturnFromSettings: () -> Void
    @AppStorage("hasSetupKeyboard", store: UserDefaults.shared) private var hasSetupKeyboard = false
    var body: some View {
        if hasSetupKeyboard {
            KeyboardSettingView()
                .accessibilityLabel("Keyboard settings")
                .accessibilityHint("Manage keyboard translator preferences and options")
                .accessibilityIdentifier("KeyboardView.Settings")
        } else {
            SetupKeyboardView {
                onReturnFromSettings()
            }
            .accessibilityLabel("Keyboard setup")
            .accessibilityHint("Follow instructions to enable the slang translator keyboard")
            .accessibilityIdentifier("KeyboardView.Setup")
        }
    }    
}
