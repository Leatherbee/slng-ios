//
//  MyAppShortcuts.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 26/11/25.
//
import AppIntents

struct MyAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExplainSlangIntent(),
            phrases: [
                "Translate slang using \(.applicationName)",
                "Translate with \(.applicationName)",
                "Explain slang in \(.applicationName)"
            ],
            shortTitle: "Translate Slang",
            systemImageName: "translate"
        )
        AppShortcut(
            intent: QuickTranslateIntent(),
            phrases: [
                "Translate text with \(.applicationName)",
                "Translate to English with \(.applicationName)",
                "Quick translate using \(.applicationName)"
            ],
            shortTitle: "Quick Translate",
            systemImageName: "text.quote"
        )
        AppShortcut(
            intent: TranslateClipboardIntent(),
            phrases: [
                "Translate clipboard with \(.applicationName)",
                "Translate clipboard text with \(.applicationName)",
                "Use \(.applicationName) for clipboard"
            ],
            shortTitle: "Translate Clipboard",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: ExplainSingleSlangIntent(),
            phrases: [
                "Explain slang in \(.applicationName)",
                "Find slang with \(.applicationName)",
                "Explain slang using \(.applicationName)"
            ],
            shortTitle: "Explain Slang Term",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: RandomSlangOfTheDayIntent(),
            phrases: [
                "Slang of the day in \(.applicationName)",
                "Show today's slang in \(.applicationName)",
                "Random slang using \(.applicationName)"
            ],
            shortTitle: "Slang of the Day",
            systemImageName: "sun.max"
        )
    }
}
