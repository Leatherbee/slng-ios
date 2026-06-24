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
    var path: [Route] = []

    var root: Route = .mainTab

    func reset(to route: Route) {
        path.removeAll()
        if route != root {
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
