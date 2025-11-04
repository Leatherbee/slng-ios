//
//  SlangTranslatorApp.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import SwiftData

@main
struct SlangTranslatorApp: App {
    @State private var router = Router()
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                ZStack{
                    NavigationStack(path: $router.path) {
                        router.destination(for: router.root)
                            .navigationDestination(for: Route.self) { route in
                                router.destination(for: route)
                            }
                    }
                }
            } else {
                OnboardingView()
            }
        }
        .modelContainer(SharedModelContainer.shared.container)
    }
}
 
