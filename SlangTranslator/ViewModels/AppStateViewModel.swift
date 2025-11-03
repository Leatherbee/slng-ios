//
//  AppStateViewModel.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 04/11/25.
//

import SwiftUI
internal import Combine

final class AppStateViewModel: ObservableObject {
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }

    init() {
        // Read the saved onboarding flag from UserDefaults
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }
}
