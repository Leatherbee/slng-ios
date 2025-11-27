//
//  SlangTranslatorApp.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import UIKit
import SwiftData
import Firebase
import FirebaseAnalytics
import AppIntents
import UserNotifications
import FirebaseMessaging

@main
struct SlangTranslatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var router = Router()
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("selectedTheme", store: UserDefaults.shared) private var selectedThemeRaw: String = "system"
    let container = SharedModelContainer.shared.container
    
    init() {
        // FirebaseApp.configure()
        let container = SharedModelContainer.shared.container
        let repo = SlangRepositoryImpl(container: container)
        _ = repo.loadAll()
        if #available(iOS 16.0, *) {
            _ = MyAppShortcuts.appShortcuts
        }
        let defaults = UserDefaults.shared
        if defaults.object(forKey: "selectedTheme") == nil {
            defaults.set("system", forKey: "selectedTheme")
        }
        ReviewRequestManager.shared.recordAppOpenAndMaybePrompt()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded{
                    MainTabbedView()
                } else{
                    OnboardingView()
                }
            }
            .preferredColorScheme(selectedThemeRaw == "system" ? nil : (selectedThemeRaw == "dark" ? .dark : .light))
        }
        .modelContainer(container)
    }


    private func flushKeyboardAnalytics() {
        let defaults = UserDefaults.shared
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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let defaults = UserDefaults.shared
        defaults.set(fcmToken ?? "", forKey: "fcmToken")
    }
}
