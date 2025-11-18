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
    
    init() {
        updateKeyboardStatus()
    }
    
    func updateKeyboardStatus() {
        let defaults = UserDefaults(suiteName: "group.canquinee.SLNG")!
        self.isFullAccessEnabled = defaults.bool(forKey: "keyboardFullAccess")
    }
}
