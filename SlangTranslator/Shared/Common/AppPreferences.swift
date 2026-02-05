//
//  AppPreferences.swift
//  SlangTranslator
//
//  Centralized UserDefaults manager for all app preferences.
//  This consolidates 110+ scattered UserDefaults accesses into a single source of truth.
//

import Foundation
internal import Combine

final class AppPreferences {
    static let shared = AppPreferences()

    private let defaults: UserDefaults

    private init() {
        self.defaults = UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
    }

    // MARK: - Keys

    enum Key {
        // UI & Theme
        static let hasOnboarded = "hasOnboarded"
        static let selectedTheme = "selectedTheme"
        static let hapticEnabled = "hapticEnabled"
        static let reduceMotionEnabled = "reduceMotionEnabled"
        static let soundEffectEnabled = "soundEffectEnabled"

        // Keyboard Setup
        static let hasSetupKeyboard = "hasSetupKeyboard"
        static let hasOpenKeyboardSetting = "hasOpenKeyboardSetting"
        static let didOpenKeyboardSettings = "didOpenKeyboardSettings"
        static let keyboardFullAccess = "keyboardFullAccess"

        // Keyboard Settings
        static let settingsAutoCorrect = "settings.autoCorrect"
        static let settingsAutoCaps = "settings.autoCaps"
        static let settingsKeyboardLayout = "settings.keyboardLayout"

        // Permissions
        static let hasRequestedSpeechMic = "hasRequestedSpeechMic"
        static let notificationsRequested = "notificationsRequested"

        // Slang Notifications
        static let slangNotificationsEnabled = "notifications.slangEnabled"
        static let notificationsShownSlangIDs = "notifications.shownSlangIDs"
        static let notificationsLastScheduledDate = "notifications.lastScheduledDate"

        // System
        static let fcmToken = "fcmToken"
        static let slngJsonHash = "slng_json_hash"

        // Review Tracking
        static let reviewTranslationCount = "review.translationCount"
        static let reviewSTTCount = "review.sttCount"
        static let reviewFirstOpenDate = "review.firstOpenDate"
        static let reviewActiveDaysCount = "review.activeDaysCount"
        static let reviewLastActiveDay = "review.lastActiveDay"
        static let reviewRequestCount = "review.requestCount"
        static let reviewFirstRequestDate = "review.firstRequestDate"
        static let reviewActiveDaysAtFirstRequest = "review.activeDaysAtFirstRequest"
        static let reviewFinalChanceShown = "review.finalChanceShown"

        // Analytics Prefix
        static let analyticsPrefix = "analytics."
    }

    // MARK: - UI & Theme Preferences

    var hasOnboarded: Bool {
        get { defaults.bool(forKey: Key.hasOnboarded) }
        set { defaults.set(newValue, forKey: Key.hasOnboarded) }
    }

    var selectedTheme: String {
        get { defaults.string(forKey: Key.selectedTheme) ?? "system" }
        set { defaults.set(newValue, forKey: Key.selectedTheme) }
    }

    var hapticEnabled: Bool {
        get { defaults.object(forKey: Key.hapticEnabled) == nil ? true : defaults.bool(forKey: Key.hapticEnabled) }
        set { defaults.set(newValue, forKey: Key.hapticEnabled) }
    }

    var reduceMotionEnabled: Bool {
        get { defaults.bool(forKey: Key.reduceMotionEnabled) }
        set { defaults.set(newValue, forKey: Key.reduceMotionEnabled) }
    }

    var soundEffectEnabled: Bool {
        get { defaults.object(forKey: Key.soundEffectEnabled) == nil ? true : defaults.bool(forKey: Key.soundEffectEnabled) }
        set { defaults.set(newValue, forKey: Key.soundEffectEnabled) }
    }

    // MARK: - Keyboard Setup

    var hasSetupKeyboard: Bool {
        get { defaults.bool(forKey: Key.hasSetupKeyboard) }
        set { defaults.set(newValue, forKey: Key.hasSetupKeyboard) }
    }

    var hasOpenKeyboardSetting: Bool {
        get { defaults.bool(forKey: Key.hasOpenKeyboardSetting) }
        set { defaults.set(newValue, forKey: Key.hasOpenKeyboardSetting) }
    }

    var didOpenKeyboardSettings: Bool {
        get { defaults.bool(forKey: Key.didOpenKeyboardSettings) }
        set { defaults.set(newValue, forKey: Key.didOpenKeyboardSettings) }
    }

    var keyboardFullAccess: Bool {
        get { defaults.bool(forKey: Key.keyboardFullAccess) }
        set { defaults.set(newValue, forKey: Key.keyboardFullAccess) }
    }

    // MARK: - Keyboard Settings

    var settingsAutoCorrect: Bool {
        get { defaults.object(forKey: Key.settingsAutoCorrect) == nil ? true : defaults.bool(forKey: Key.settingsAutoCorrect) }
        set { defaults.set(newValue, forKey: Key.settingsAutoCorrect) }
    }

    var settingsAutoCaps: Bool {
        get { defaults.object(forKey: Key.settingsAutoCaps) == nil ? true : defaults.bool(forKey: Key.settingsAutoCaps) }
        set { defaults.set(newValue, forKey: Key.settingsAutoCaps) }
    }

    var settingsKeyboardLayout: String {
        get { defaults.string(forKey: Key.settingsKeyboardLayout) ?? "QWERTY" }
        set { defaults.set(newValue, forKey: Key.settingsKeyboardLayout) }
    }

    // MARK: - Permissions

    var hasRequestedSpeechMic: Bool {
        get { defaults.bool(forKey: Key.hasRequestedSpeechMic) }
        set { defaults.set(newValue, forKey: Key.hasRequestedSpeechMic) }
    }

    var notificationsRequested: Bool {
        get { defaults.bool(forKey: Key.notificationsRequested) }
        set { defaults.set(newValue, forKey: Key.notificationsRequested) }
    }

    // MARK: - Slang Notifications

    var slangNotificationsEnabled: Bool {
        get { defaults.bool(forKey: Key.slangNotificationsEnabled) }
        set { defaults.set(newValue, forKey: Key.slangNotificationsEnabled) }
    }

    var notificationsShownSlangIDs: [String] {
        get { defaults.stringArray(forKey: Key.notificationsShownSlangIDs) ?? [] }
        set { defaults.set(newValue, forKey: Key.notificationsShownSlangIDs) }
    }

    var notificationsLastScheduledDate: Date? {
        get { defaults.object(forKey: Key.notificationsLastScheduledDate) as? Date }
        set { defaults.set(newValue, forKey: Key.notificationsLastScheduledDate) }
    }

    // MARK: - System

    var fcmToken: String? {
        get { defaults.string(forKey: Key.fcmToken) }
        set { defaults.set(newValue, forKey: Key.fcmToken) }
    }

    var slngJsonHash: String? {
        get { defaults.string(forKey: Key.slngJsonHash) }
        set { defaults.set(newValue, forKey: Key.slngJsonHash) }
    }

    // MARK: - Review Tracking

    var reviewTranslationCount: Int {
        get { defaults.integer(forKey: Key.reviewTranslationCount) }
        set { defaults.set(newValue, forKey: Key.reviewTranslationCount) }
    }

    var reviewSTTCount: Int {
        get { defaults.integer(forKey: Key.reviewSTTCount) }
        set { defaults.set(newValue, forKey: Key.reviewSTTCount) }
    }

    var reviewFirstOpenDate: Double {
        get { defaults.double(forKey: Key.reviewFirstOpenDate) }
        set { defaults.set(newValue, forKey: Key.reviewFirstOpenDate) }
    }

    var reviewActiveDaysCount: Int {
        get { defaults.integer(forKey: Key.reviewActiveDaysCount) }
        set { defaults.set(newValue, forKey: Key.reviewActiveDaysCount) }
    }

    var reviewLastActiveDay: String? {
        get { defaults.string(forKey: Key.reviewLastActiveDay) }
        set { defaults.set(newValue, forKey: Key.reviewLastActiveDay) }
    }

    var reviewRequestCount: Int {
        get { defaults.integer(forKey: Key.reviewRequestCount) }
        set { defaults.set(newValue, forKey: Key.reviewRequestCount) }
    }

    var reviewFirstRequestDate: Double {
        get { defaults.double(forKey: Key.reviewFirstRequestDate) }
        set { defaults.set(newValue, forKey: Key.reviewFirstRequestDate) }
    }

    var reviewActiveDaysAtFirstRequest: Int {
        get { defaults.integer(forKey: Key.reviewActiveDaysAtFirstRequest) }
        set { defaults.set(newValue, forKey: Key.reviewActiveDaysAtFirstRequest) }
    }

    var reviewFinalChanceShown: Bool {
        get { defaults.bool(forKey: Key.reviewFinalChanceShown) }
        set { defaults.set(newValue, forKey: Key.reviewFinalChanceShown) }
    }

    // MARK: - Analytics Helpers

    func incrementAnalyticsCount(for event: String) {
        let key = "\(Key.analyticsPrefix)\(event).count"
        let count = defaults.integer(forKey: key) + 1
        defaults.set(count, forKey: key)
    }

    func analyticsCount(for event: String) -> Int {
        let key = "\(Key.analyticsPrefix)\(event).count"
        return defaults.integer(forKey: key)
    }

    func setAnalyticsParams(for event: String, params: [String: Any]) {
        let key = "\(Key.analyticsPrefix)\(event).last_params"
        defaults.set(params, forKey: key)
    }

    func analyticsParams(for event: String) -> [String: Any]? {
        let key = "\(Key.analyticsPrefix)\(event).last_params"
        return defaults.dictionary(forKey: key)
    }

    // MARK: - Generic Access (for custom keys)

    func value<T>(forKey key: String) -> T? {
        return defaults.object(forKey: key) as? T
    }

    func setValue<T>(_ value: T?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Synchronization

    func synchronize() {
        defaults.synchronize()
    }
}

// MARK: - SwiftUI @AppStorage Compatibility

extension AppPreferences {
    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
    }
}
