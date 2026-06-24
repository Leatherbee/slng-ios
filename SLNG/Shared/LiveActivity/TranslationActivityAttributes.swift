//
//  TranslationActivityAttributes.swift
//  SlangTranslator
//
//  Live Activity attributes for translation processing.
//

import ActivityKit
import Foundation

struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Whether translation is currently in progress
        var isTranslating: Bool
        /// Preview of input text (max 50 chars)
        var inputPreview: String
        /// Preview of result text (max 80 chars)
        var resultPreview: String?
        /// Number of slangs detected
        var slangsCount: Int
        /// Whether an error occurred
        var hasError: Bool

        static func initial(inputPreview: String) -> ContentState {
            ContentState(
                isTranslating: true,
                inputPreview: String(inputPreview.prefix(50)),
                resultPreview: nil,
                slangsCount: 0,
                hasError: false
            )
        }
    }

    /// When the translation started
    let startTime: Date
    /// Full input text for reference
    let fullInputText: String
}
