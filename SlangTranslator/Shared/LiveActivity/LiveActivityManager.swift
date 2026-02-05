//
//  LiveActivityManager.swift
//  SlangTranslator
//
//  Central manager for starting, updating, and ending Live Activities.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var recordingActivity: Activity<RecordingActivityAttributes>?
    private var translationActivity: Activity<TranslationActivityAttributes>?
    private var elapsedTimer: Timer?
    private var recordingStartTime: Date?

    private init() {}

    // MARK: - Recording Activity

    /// Start a recording Live Activity
    func startRecordingActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logDebug("Live Activities not enabled", category: .liveActivity)
            return
        }

        // End any existing recording activity
        endRecordingActivity(cancelled: true)

        let attributes = RecordingActivityAttributes(startTime: Date())
        let initialState = RecordingActivityAttributes.ContentState.initial

        do {
            recordingActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            recordingStartTime = Date()
            startElapsedTimer()
            logDebug("Recording Live Activity started", category: .liveActivity)
        } catch {
            logError("Failed to start recording activity: \(error)", category: .liveActivity)
        }
    }

    /// Update recording activity with current state
    func updateRecordingActivity(elapsed: Int, audioLevel: Float) {
        guard let activity = recordingActivity else { return }

        let state = RecordingActivityAttributes.ContentState(
            isRecording: true,
            isTranscribing: false,
            elapsedSeconds: elapsed,
            audioLevel: audioLevel,
            previewText: nil,
            hasError: false
        )

        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    /// Transition to transcribing state
    func updateRecordingToTranscribing(elapsed: Int) {
        guard let activity = recordingActivity else { return }

        stopElapsedTimer()

        let state = RecordingActivityAttributes.ContentState(
            isRecording: false,
            isTranscribing: true,
            elapsedSeconds: elapsed,
            audioLevel: -160,
            previewText: nil,
            hasError: false
        )

        Task {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    /// End recording activity with result
    func endRecordingActivity(text: String? = nil, cancelled: Bool = false, error: Bool = false) {
        guard let activity = recordingActivity else { return }

        stopElapsedTimer()

        let elapsed = recordingStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0

        let finalState = RecordingActivityAttributes.ContentState(
            isRecording: false,
            isTranscribing: false,
            elapsedSeconds: elapsed,
            audioLevel: -160,
            previewText: text.map { String($0.prefix(50)) },
            hasError: error
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }

        recordingActivity = nil
        recordingStartTime = nil
    }

    private func startElapsedTimer() {
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self,
                      let startTime = self.recordingStartTime else { return }
                let elapsed = Int(Date().timeIntervalSince(startTime))
                // Audio level will be updated separately by the caller
                self.updateRecordingActivity(elapsed: elapsed, audioLevel: -160)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    // MARK: - Translation Activity

    /// Start a translation Live Activity
    func startTranslationActivity(input: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logDebug("Live Activities not enabled", category: .liveActivity)
            return
        }

        // End any existing translation activity
        endTranslationActivity()

        let attributes = TranslationActivityAttributes(
            startTime: Date(),
            fullInputText: input
        )
        let initialState = TranslationActivityAttributes.ContentState.initial(inputPreview: input)

        do {
            translationActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
            logDebug("Translation Live Activity started", category: .liveActivity)
        } catch {
            logError("Failed to start translation activity: \(error)", category: .liveActivity)
        }
    }

    /// End translation activity with result
    func endTranslationActivity(result: String? = nil, slangsCount: Int = 0, error: Bool = false) {
        guard let activity = translationActivity else { return }

        let inputPreview = String(activity.attributes.fullInputText.prefix(50))

        let finalState = TranslationActivityAttributes.ContentState(
            isTranslating: false,
            inputPreview: inputPreview,
            resultPreview: result.map { String($0.prefix(80)) },
            slangsCount: slangsCount,
            hasError: error
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }

        translationActivity = nil
    }

    // MARK: - Cleanup

    /// End all active Live Activities
    func endAllActivities() {
        endRecordingActivity(cancelled: true)
        endTranslationActivity()
    }
}
