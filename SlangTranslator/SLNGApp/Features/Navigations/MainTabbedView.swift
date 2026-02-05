//
//  MainTabbedView.swift
//  SlangTranslator
//
//  Fixed: Wrap each tab with NavigationStack
//

import SwiftUI
import SwiftData

enum TabSelection: Hashable {
    case translate
    case keyboard
    case dictionary
}

struct MainTabbedView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: TabSelection = .translate
    @State private var popupManager = PopupManager()
    @State private var searchText = ""
    @AppStorage("hasSetupKeyboard", store: UserDefaults.shared) private var hasSetupKeyboard = false

    var initialTab: TabSelection?

    init(initialTab: TabSelection? = nil) {
        self.initialTab = initialTab
        if let tab = initialTab {
            _selectedTab = State(initialValue: tab)
        }
    }

    var body: some View {
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
                    KeyboardView(onReturnFromSettings: {
                        hasSetupKeyboard = true
                    })
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
            }
            .tint(.primary)

            // Floating Search Bar - only shown on Dictionary tab
            if selectedTab == .dictionary && !popupManager.isPresented {
                KeyboardAwareFloatingSearchBar(
                    text: $searchText,
                    placeholder: "Type a slang you don't know",
                    bottomPadding: 60
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            }

            if popupManager.isPresented {
                DictionaryDetail()
                    .environment(popupManager)
                    .zIndex(1)
                    .transition(.revealFromCenter)
            }
        }
        .animation(.spring(response: 0.175, dampingFraction: 1.0), value: popupManager.isPresented)
        .onReceive(NotificationCenter.default.publisher(for: .slangNotificationTapped)) { notification in
            handleSlangNotificationTap(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkTabChange)) { notification in
            if let tab = notification.userInfo?["tab"] as? TabSelection {
                selectedTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .widgetSlangTapped)) { notification in
            handleWidgetSlangTap(notification)
        }
    }

    /// Handle deep link from slang notification tap
    private func handleSlangNotificationTap(_ notification: Notification) {
        guard let slangIDString = notification.userInfo?[SlangNotificationManager.slangIDKey] as? String,
              let slangID = UUID(uuidString: slangIDString) else {
            return
        }

        // Find the slang by ID
        let descriptor = FetchDescriptor<SlangModel>(
            predicate: #Predicate<SlangModel> { $0.id == slangID }
        )

        guard let slang = try? modelContext.fetch(descriptor).first else {
            logWarning("Slang not found for notification deep link: \(slangIDString)", category: .notifications)
            return
        }

        // Find all variants with the same canonical form using existing implementation
        let slangRepo = SlangSwiftDataImpl(context: modelContext)
        let variants = slangRepo.fetchByCanonicalForm(slang.canonicalForm)

        // Switch to dictionary tab
        selectedTab = .dictionary

        // Set up popup manager and show detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            popupManager.setSlangData(slang)
            popupManager.setCanonicalForm(slang.canonicalForm)
            popupManager.setVariants(variants.isEmpty ? [slang] : variants)
            popupManager.isPresented = true
        }
    }

    /// Handle deep link from widget tap
    private func handleWidgetSlangTap(_ notification: Notification) {
        guard let slangWord = notification.userInfo?["slang"] as? String else {
            return
        }

        // Use SlangSwiftDataImpl to search by slang word
        let slangRepo = SlangSwiftDataImpl(context: modelContext)
        let results = slangRepo.fetch(offset: 0, keyword: slangWord)

        // Find exact match first, or first partial match
        let exactMatch = results.first { $0.slang.lowercased() == slangWord.lowercased() }
        guard let slang = exactMatch ?? results.first else {
            logWarning("Slang not found for widget deep link: \(slangWord)", category: .ui)
            // Still switch to dictionary and set search text
            selectedTab = .dictionary
            searchText = slangWord
            return
        }

        // Find all variants with the same canonical form
        let variants = slangRepo.fetchByCanonicalForm(slang.canonicalForm)

        // Switch to dictionary tab
        selectedTab = .dictionary

        // Set up popup manager and show detail
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            popupManager.setSlangData(slang)
            popupManager.setCanonicalForm(slang.canonicalForm)
            popupManager.setVariants(variants.isEmpty ? [slang] : variants)
            popupManager.isPresented = true
        }
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
