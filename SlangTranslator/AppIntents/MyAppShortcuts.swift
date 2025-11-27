//
//  MyAppShortcuts.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 26/11/25.
//
import AppIntents

struct MyAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ExplainSlangIntent(),
            phrases: [
                "Translate slang using \(.applicationName)",
                "Translate with \(.applicationName)",
                "Arti kata di \(.applicationName)"
            ],
            shortTitle: "translate",
            systemImageName: "character.book.closed"
        )
    }
}
