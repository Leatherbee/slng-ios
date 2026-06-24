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
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        updateKeyboardStatus()
        
        NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: UserDefaults.shared
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateKeyboardStatus()
        }
        .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    func updateKeyboardStatus() {
        let defaults = UserDefaults.shared
        let fullAccess = defaults.bool(forKey: "keyboardFullAccess")
        let hasSetup = defaults.bool(forKey: "hasSetupKeyboard")
        let hasOpened = defaults.integer(forKey: "analytics/.keyboard_open/.count") > 0
        DispatchQueue.main.async {
            self.isFullAccessEnabled = fullAccess
            self.isKeyboardEnabled = hasSetup || hasOpened || fullAccess
        }
    }
}
