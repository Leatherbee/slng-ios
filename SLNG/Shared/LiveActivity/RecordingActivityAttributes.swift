//
//  RecordingActivityAttributes.swift
//  SlangTranslator
//
//  Live Activity attributes for speech-to-text recording.
//

import ActivityKit
import Foundation

struct RecordingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Whether recording is currently active
        var isRecording: Bool
        /// Whether transcription is in progress
        var isTranscribing: Bool
        /// Elapsed recording time in seconds
        var elapsedSeconds: Int
        /// Current audio level (-160 to 0 dB)
        var audioLevel: Float
        /// Preview of transcribed text (if available)
        var previewText: String?
        /// Whether an error occurred
        var hasError: Bool

        static var initial: ContentState {
            ContentState(
                isRecording: true,
                isTranscribing: false,
                elapsedSeconds: 0,
                audioLevel: -160,
                previewText: nil,
                hasError: false
            )
        }
    }

    /// When the recording started
    let startTime: Date
}
