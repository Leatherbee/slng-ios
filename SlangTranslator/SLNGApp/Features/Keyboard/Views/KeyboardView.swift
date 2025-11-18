//
//  KeyboardView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI

struct KeyboardView: View {
    @StateObject private var viewModel = KeyboardStatusViewModel()
    
    var onReturnFromSettings: () -> Void
    var body: some View {
        Group{
            if viewModel.isFullAccessEnabled {
                KeyboardSettingView()
                    .accessibilityLabel("Keyboard settings")
                    .accessibilityHint("Manage keyboard translator preferences and options")
                    .accessibilityIdentifier("KeyboardView.Settings")
            } else {
                SetupKeyboardView(viewModel: viewModel) {
                    onReturnFromSettings()
                }
                .accessibilityLabel("Keyboard setup")
                .accessibilityHint("Follow instructions to enable the slang translator keyboard")
                .accessibilityIdentifier("KeyboardView.Setup")
            }
        }
        .onAppear {
            viewModel.updateKeyboardStatus()
        }
    }
}
