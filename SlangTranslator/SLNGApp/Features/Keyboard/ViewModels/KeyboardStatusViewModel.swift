//
//  KeyboardStatusViewModel.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 17/11/25.
//

import SwiftUI
internal import Combine

class KeyboardStatusViewModel: ObservableObject {
    @Published var isFullAccessEnabled: Bool = false
    @Published var isKeyboardEnabled: Bool = false
    
    init() {
        updateKeyboardStatus()
    }
    
    func updateKeyboardStatus() {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
        self.isFullAccessEnabled = defaults.bool(forKey: "keyboardFullAccess")
        let hasSetup = defaults.bool(forKey: "hasSetupKeyboard")
        let hasOpened = defaults.integer(forKey: "analytics/.keyboard_open/.count") > 0
        self.isKeyboardEnabled = hasSetup || hasOpened
    }
}
