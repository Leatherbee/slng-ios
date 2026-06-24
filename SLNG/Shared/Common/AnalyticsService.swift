//
//  AnalyticsService.swift
//  SlangTranslator
//
//  Centralized analytics service to replace scattered Analytics.logEvent calls.
//  Provides type-safe event logging and easy provider switching.
//

import Foundation
import FirebaseAnalytics

// MARK: - Analytics Event Types

enum AnalyticsEvent {
    // Settings Events
    case settingsClosePressed
    case settingsThemeOpenPressed
    case settingsAboutOpen
    case settingsRateOpen
    case settingsChanged(setting: String, value: String)
    case settingsThemeSelected(theme: String)

    // Language Events
    case languageSelected(language: String)

    // Permission Events
    case permissionsPrompt(type: String)
    case permissionsResponse(type: String, result: String)

    // Translation Events
    case translateButtonPressed(inputLength: Int)
    case expandTranslationPressed(isExpanded: Bool)
    case copyTranslationPressed
    case detectedSlangToggle(isShown: Bool)
    case tryAnotherButtonPressed
    case expandedTranslationClose
    case slangCardToggle(slang: String, isExpanded: Bool)

    // Network Events
    case networkStatus(status: String)
    case extensionError(code: String)
    case latencyBucket(feature: String, bucket: String)

    // Dictionary Events
    case dictionaryJumpLetter(letter: String)

    // Keyboard Events
    case keyboardOpen
    case keyboardClose
    case keyboardLanguageSwitch
    case keyboardThemeSwitch(theme: String)
    case keyboardFeatureUsed(mode: String)

    // Custom Event
    case custom(name: String, parameters: [String: Any]?)

    var name: String {
        switch self {
        case .settingsClosePressed: return "settings_close_pressed"
        case .settingsThemeOpenPressed: return "settings_theme_open_pressed"
        case .settingsAboutOpen: return "settings_about_open"
        case .settingsRateOpen: return "settings_rate_open"
        case .settingsChanged: return "settings_changed"
        case .settingsThemeSelected: return "settings_theme_selected"
        case .languageSelected: return "language_selected"
        case .permissionsPrompt: return "permissions_prompt"
        case .permissionsResponse: return "permissions_response"
        case .translateButtonPressed: return "translate_button_pressed"
        case .expandTranslationPressed: return "expand_translation_pressed"
        case .copyTranslationPressed: return "copy_translation_pressed"
        case .detectedSlangToggle: return "detected_slang_toggle"
        case .tryAnotherButtonPressed: return "try_another_button_pressed"
        case .expandedTranslationClose: return "expanded_translation_close"
        case .slangCardToggle: return "slang_card_toggle"
        case .networkStatus: return "network_status"
        case .extensionError: return "extension_error"
        case .latencyBucket: return "latency_bucket"
        case .dictionaryJumpLetter: return "dictionary_jump_letter"
        case .keyboardOpen: return "keyboard_open"
        case .keyboardClose: return "keyboard_close"
        case .keyboardLanguageSwitch: return "language_switch"
        case .keyboardThemeSwitch: return "theme_switch"
        case .keyboardFeatureUsed: return "feature_used"
        case .custom(let name, _): return name
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .settingsClosePressed,
             .settingsThemeOpenPressed,
             .settingsAboutOpen,
             .settingsRateOpen,
             .copyTranslationPressed,
             .tryAnotherButtonPressed,
             .expandedTranslationClose,
             .keyboardOpen,
             .keyboardClose,
             .keyboardLanguageSwitch:
            return nil

        case .settingsChanged(let setting, let value):
            return ["setting": setting, "value": value]

        case .settingsThemeSelected(let theme):
            return ["theme": theme]

        case .languageSelected(let language):
            return ["language": language]

        case .permissionsPrompt(let type):
            return ["permission_type": type]

        case .permissionsResponse(let type, let result):
            return ["permission_type": type, "result": result]

        case .translateButtonPressed(let inputLength):
            return ["input_length": inputLength]

        case .expandTranslationPressed(let isExpanded):
            return ["is_expanded": isExpanded]

        case .detectedSlangToggle(let isShown):
            return ["is_shown": isShown]

        case .slangCardToggle(let slang, let isExpanded):
            return ["slang": slang, "is_expanded": isExpanded]

        case .networkStatus(let status):
            return ["status": status]

        case .extensionError(let code):
            return ["code": code]

        case .latencyBucket(let feature, let bucket):
            return ["feature_name": feature, "bucket": bucket]

        case .dictionaryJumpLetter(let letter):
            return ["letter": letter]

        case .keyboardThemeSwitch(let theme):
            return ["theme": theme]

        case .keyboardFeatureUsed(let mode):
            return ["mode": mode]

        case .custom(_, let params):
            return params
        }
    }
}

// MARK: - Analytics Service

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    func log(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
        logDebug("Analytics: \(event.name) \(event.parameters ?? [:])", category: .analytics)
    }

    func log(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
        logDebug("Analytics: \(name) \(parameters ?? [:])", category: .analytics)
    }

    // MARK: - Convenience Methods

    func logPermissionPrompt(type: String) {
        log(.permissionsPrompt(type: type))
    }

    func logPermissionResponse(type: String, granted: Bool) {
        log(.permissionsResponse(type: type, result: granted ? "authorized" : "denied"))
    }

    func logTranslation(inputLength: Int) {
        log(.translateButtonPressed(inputLength: inputLength))
    }

    func logNetworkSuccess() {
        log(.networkStatus(status: "online"))
    }

    func logNetworkError() {
        log(.networkStatus(status: "error"))
    }

    func logLatency(feature: String, milliseconds: Int) {
        let bucket: String
        switch milliseconds {
        case ..<50: bucket = "<50ms"
        case 50..<100: bucket = "50-100ms"
        case 100..<250: bucket = "100-250ms"
        case 250..<500: bucket = "250-500ms"
        default: bucket = ">=500ms"
        }
        log(.latencyBucket(feature: feature, bucket: bucket))
    }
}

// MARK: - Global Convenience Function

func logAnalytics(_ event: AnalyticsEvent) {
    AnalyticsService.shared.log(event)
}
