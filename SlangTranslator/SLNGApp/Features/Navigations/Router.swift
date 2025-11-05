//
//  Router.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI
import Observation

@MainActor
@Observable
final class Router {
    // MARK: Navigation state
    var path: [Route] = []

    // MARK: Entry
    /// The initial route for the app. Adjust as needed (e.g., gate by auth state).
    var root: Route = .mainTab

    // MARK: Navigation helpers
    func reset(to route: Route) {
        path.removeAll()
        if route != root {
            // The stack shows root as the first screen, then pushes route if different
            path = [route]
        }
    }

    func go(to route: Route) {
        path.append(route)
    }

    func goBack() {
        _ = path.popLast()
    }

    func goBackToRoot() {
        path.removeAll()
    }

    // Semantic, intention-revealing helpers
    func goToMainTab() { reset(to: .mainTab) }
}

// MARK: - Destination builder
extension Router {
    @ViewBuilder
    func destination(for route: Route) -> some View {
        switch route {
        case .mainTab:
            MainTabbedView()
        case .onboarding:
            OnboardingView()
        }
    }
}

// MARK: - Routing abstraction for testability
@MainActor
protocol NavigationRouting: AnyObject {
    func goToMainTab()
}

extension Router: NavigationRouting {}




