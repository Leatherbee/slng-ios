//
//  SlangTranslatorApp.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseAnalytics

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
                if hasOnboarded{
                    MainTabbedView()
                } else{
                    OnboardingView()
                }
        }
        .modelContainer(container)
    }


    private func flushKeyboardAnalytics() {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
        let simpleEvents = [
            ("keyboard_open", "analytics.keyboard_open.count"),
            ("keyboard_close", "analytics.keyboard_close.count"),
            ("language_switch", "analytics.language_switch.count"),
            ("theme_switch", "analytics.theme_switch.count")
        ]
        for (event, key) in simpleEvents {
            let count = defaults.integer(forKey: key)
            if count > 0 {
                Analytics.logEvent(event, parameters: ["count": count])
                defaults.removeObject(forKey: key)
            }
        }
        let featureEvents = [
            ("emoji_mode", "analytics.feature_used.emoji_mode.count"),
            ("explain_mode", "analytics.feature_used.explain_mode.count"),
            ("normal_mode", "analytics.feature_used.normal_mode.count")
        ]
        for (feature, key) in featureEvents {
            let count = defaults.integer(forKey: key)
            if count > 0 {
                Analytics.logEvent("feature_used", parameters: [
                    "feature_name": feature,
                    "count": count
                ])
                defaults.removeObject(forKey: key)
            }
        }
        let networkEvents = [
            ("online", "analytics.network_status.online.count"),
            ("error", "analytics.network_status.error.count")
        ]
        for (status, key) in networkEvents {
            let count = defaults.integer(forKey: key)
            if count > 0 {
                Analytics.logEvent("network_status", parameters: [
                    "status": status,
                    "count": count
                ])
                defaults.removeObject(forKey: key)
            }
        }
        let errKey = "analytics.extension_error.translation_error.count"
        let errCount = defaults.integer(forKey: errKey)
        if errCount > 0 {
            Analytics.logEvent("extension_error", parameters: [
                "code": "translation_error",
                "count": errCount
            ])
            defaults.removeObject(forKey: errKey)
        }
        let buckets = ["<50ms", "50-100ms", "100-250ms", "250-500ms", ">=500ms"]
        for b in buckets {
            let key = "analytics.latency_bucket.clipboard_translation.\(b).count"
            let count = defaults.integer(forKey: key)
            if count > 0 {
                Analytics.logEvent("latency_bucket", parameters: [
                    "feature_name": "clipboard_translation",
                    "bucket": b,
                    "count": count
                ])
                defaults.removeObject(forKey: key)
            }
        }
    }
}

