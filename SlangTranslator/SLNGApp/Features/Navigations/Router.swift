//
//  Router.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//
import SwiftUI
import Observation

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

    func go(_ name: String) {
        let key = name.lowercased()
        switch key {
        case "languagesettingview", "language":
            path.append(.settingsLanguage)
        case "themesettingview", "theme":
            path.append(.settingsTheme)
        case "aboutview", "about":
            path.append(.settingsAbout)
        default:
            break
        }
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

struct RouterStack<Content: View>: View {
    @State private var router: Router
    private let content: () -> Content

    init(router: Router = Router(), @ViewBuilder content: @escaping () -> Content) {
        _router = State(initialValue: router)
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            content()
                .environment(router)
        }
        .navigationDestination(for: Route.self) { route in
            router.destination(for: route)
        }
    }
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
        case .settingsLanguage:
            LanguageSettingView()
        case .settingsTheme:
            ThemeSettingsView()
        case .settingsAbout:
            AboutView()
        }
    }
}

// MARK: - Routing abstraction for testability
@MainActor
protocol NavigationRouting: AnyObject {
    func goToMainTab()
}

extension Router: NavigationRouting {}

public enum Route: Hashable {
    case onboarding
    case mainTab
    case settingsLanguage
    case settingsTheme
    case settingsAbout
}
