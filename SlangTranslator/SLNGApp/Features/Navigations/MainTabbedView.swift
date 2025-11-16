//
//  MainTabbedView.swift
//  SlangTranslator
//
//  Fixed: Wrap each tab with NavigationStack
//

import SwiftUI

enum TabSelection: Hashable {
    case translate
    case keyboard
    case dictionary
    case search
}

struct MainTabbedView: View {
    @State private var selectedTab: TabSelection = .translate
    @State private var popupManager = PopupManager()
    @State private var searchText = ""
    
    var body: some View{
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Translate", systemImage: "bubbles.and.sparkles", value: .translate) {
                    NavigationStack {
                        TranslateView()
                    }
                }
                .accessibilityLabel("Translate tab")
                .accessibilityHint("Translate page is selected by default.")
                .accessibilityInputLabels(["Translate Tab"])
                
                Tab("Keyboard", systemImage: "keyboard", value: .keyboard) {
                    KeyboardView(onReturnFromSettings: {})
                }
                .accessibilityLabel("Keyboard tab")
                .accessibilityHint("Keyboard page")
                .accessibilityInputLabels(["Keyboard Tab"])
                
                Tab("Dictionary", systemImage: "text.book.closed", value: .dictionary) {
                    DictionaryView(searchText: $searchText)
                        .environment(popupManager)
                }
                .accessibilityLabel("Dictionary tab")
                .accessibilityHint("Dictionary page")
                .accessibilityInputLabels(["Dictionary Tab"])
                
                if selectedTab == .dictionary || selectedTab == .search {
                    Tab(value: .search, role: .search) {
                        NavigationStack {
                            DictionaryView(searchText: $searchText)
                                .environment(popupManager)
                        }
                        .searchable(text: $searchText)
                    }
                }
            }
            .tint(.primary)
            
            if popupManager.isPresented {
                DictionaryDetail()
                    .environment(popupManager)
                    .zIndex(1)
                    .transition(.revealFromCenter)
            }
        }
        .animation(.spring(response: 0.175, dampingFraction: 1.0), value: popupManager.isPresented)
    }
}

extension AnyTransition {
    static var revealFromCenter: AnyTransition {
        AnyTransition.modifier(
            active: ScaleAndClipModifier(scale: 0.0),
            identity: ScaleAndClipModifier(scale: 1.0)
        )
    }
}

struct ScaleAndClipModifier: ViewModifier {
    var scale: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(y: scale, anchor: .center)
                .opacity(scale > 0 ? 1 : 0)
        }
    }
}
