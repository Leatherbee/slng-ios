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
    let container = SharedModelContainer.shared.container
    
    
    init() {
        let container = SharedModelContainer.shared.container
        let repo = SlangRepositoryImpl(container: container)
        _ = repo.loadAll()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                NavigationStack(path: $router.path) {
                    router.destination(for: router.root)
                        .navigationDestination(for: Route.self) { route in
                            router.destination(for: route)
                        }
                        .onAppear {
                            // Decide initial route based on onboarding flag
                            router.root = hasOnboarded ? .mainTab : .onboarding
                        }
                        .onChange(of: hasOnboarded) { oldValue, newValue in
                            // When onboarding completes, switch root to main tab
                            router.root = newValue ? .mainTab : .onboarding
                        }
                }
            }
        }
        .modelContainer(container)
    }
}

