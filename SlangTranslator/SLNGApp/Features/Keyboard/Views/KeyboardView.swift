//
//  KeyboardView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI

struct KeyboardView: View {
    var onReturnFromSettings: () -> Void
    @AppStorage("hasSetupKeyboard") private var hasSetupKeyboard: Bool = false
    var body: some View {
        if hasSetupKeyboard {
            KeyboardSettingView()
        } else {
            SetupKeyboardView {
                onReturnFromSettings()
            }
        }
    }    
}
