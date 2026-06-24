//
//  TranslateViewModel.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 27/10/25.
//

import Foundation
import SwiftUI
import AVFoundation
internal import Combine
import SwiftData
import Observation
import FirebasePerformance
import ActivityKit

@MainActor
@Observable
final class TranslateViewModel {
    var inputText: String = ""
    var translatedText: String? = nil
    var isTranslated: Bool = false
    var isExpanded: Bool = false
    var copiedToKeyboardAlert: Bool = false
    var isDetectedSlangShown: Bool = false
    var slangDetected: [String] = []
    var slangData: [SlangData] = []
    
    var isLoading: Bool = false
    var isInitializing: Bool = true
    var errorMessage: String? = nil
    
    var result: TranslationResult? = nil
    var isRecording: Bool = false
    var isTranscribing: Bool = false
    var sttPlaceholder: String? = nil
    var audioLevel: Float = -160
    var isRecorderUIVisible: Bool = false

    private let audioRecorder = AudioRecorderManager()
    private let speechStreamingManager = SpeechStreamingManager()

    private var translateSentenceUseCase: TranslateSentenceUseCase?
    private var speechUseCase: TranscribeSpeechUseCase?
    private var currentTranscriptionTask: Task<Void, Never>?

    private let analytics = AnalyticsService.shared
    private var recordingStartTime: Date?

    func prewarmPermissions() {
        analytics.logPermissionPrompt(type: "microphone")
        audioRecorder.requestPermission { [analytics] granted in
            analytics.logPermissionResponse(type: "microphone", granted: granted)
        }
        analytics.logPermissionPrompt(type: "speech_recognition")
        speechStreamingManager.requestAuthorization { [analytics] granted in
            analytics.logPermissionResponse(type: "speech_recognition", granted: granted)
        }
    }
    
    init() {
        Task {
            await self.initializeDependencies()
        }
    }
    
    private func initializeDependencies() async {
        let context = SharedModelContainer.shared.container.mainContext
        let baseURLString = Bundle.main.infoDictionary?["BackendBaseURL"] as? String ?? "https://api.slng.space"
        guard let url = URL(string: baseURLString) else {
            await MainActor.run { self.errorMessage = "Backend base URL invalid." }
            return
        }
        let client = BackendClient(baseURL: url)

        let translationRepository = TranslationRepositoryImpl(client: client, context: context)
        let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
        let translateSentenceUseCase = TranslateSentenceUseCaseImpl(
            translationRepository: translationRepository,
            slangRepository: slangRepository
        )

        let sttRepo = SpeechToTextRepositoryImpl(client: client)
        let sttUseCase = TranscribeSpeechUseCaseImpl(repository: sttRepo)

        await MainActor.run {
            self.translateSentenceUseCase = translateSentenceUseCase
            self.speechUseCase = sttUseCase
            self.isInitializing = false
        }
    }
    
    func startRecording() {
        // Cancel any pending transcription
        currentTranscriptionTask?.cancel()
        currentTranscriptionTask = nil

        audioRecorder.requestPermission { [weak self, analytics] micGranted in
            guard let self else { return }

            if !micGranted {
                DispatchQueue.main.async {
                    self.errorMessage = "Mic's locked. Open Settings and free it"
                }
                analytics.logPermissionResponse(type: "microphone", granted: false)
                return
            }

            do {
                self.audioRecorder.setLevelUpdateHandler { [weak self] level in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        self.audioLevel = level
                        // Update Live Activity with audio level
                        if let startTime = self.recordingStartTime {
                            let elapsed = Int(Date().timeIntervalSince(startTime))
                            LiveActivityManager.shared.updateRecordingActivity(elapsed: elapsed, audioLevel: level)
                        }
                    }
                }
                try self.audioRecorder.start()
                DispatchQueue.main.async {
                    self.sttPlaceholder = nil
                    self.isRecording = true
                    self.recordingStartTime = Date()
                    // Start Live Activity
                    LiveActivityManager.shared.startRecordingActivity()
                }
                analytics.logPermissionResponse(type: "microphone", granted: true)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func stopRecordingAndTranscribe() {
        // Hard gate: if mic not active or permission not granted, avoid backend calls
        let perm = AVAudioApplication.shared.recordPermission
        if perm != .granted {
            errorMessage = "Your mic said no. Respectfully, fix that in Settings"
            isRecording = false
            isTranscribing = false
            audioLevel = -160
            LiveActivityManager.shared.endRecordingActivity(error: true)
            recordingStartTime = nil
            return
        }

        speechStreamingManager.stop()

        do {
            let result = try audioRecorder.stopAndFetchData()

            // Calculate elapsed time before clearing
            let elapsed = recordingStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0

            // Batch state updates
            isRecording = false
            audioLevel = -160

            guard let speechUseCase else {
                LiveActivityManager.shared.endRecordingActivity(cancelled: true)
                recordingStartTime = nil
                return
            }
            isTranscribing = true

            // Update Live Activity to transcribing state
            LiveActivityManager.shared.updateRecordingToTranscribing(elapsed: elapsed)

            // Cancel previous transcription if any
            currentTranscriptionTask?.cancel()

            currentTranscriptionTask = Task { [weak self] in
                guard let self else { return }

                let trace = PerformanceTracker.shared.startOperationTrace(
                    name: "stt_transcription_flow",
                    attributes: [
                        "audio_size": String(result.data.count),
                        "mime_type": result.mimeType
                    ]
                )

                do {
                    // Check for cancellation before network call
                    try Task.checkCancellation()

                    let text = try await speechUseCase.execute(
                        audioData: result.data,
                        fileName: result.fileName,
                        mimeType: result.mimeType
                    )

                    // Check for cancellation after network call
                    try Task.checkCancellation()

                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        self.sttPlaceholder = self.emptySTTMessages.randomElement() ?? "Seems like you didn't say anything"
                        trace?.setValue("empty", forAttribute: "result_type")
                        // End Live Activity with no text
                        LiveActivityManager.shared.endRecordingActivity()
                    } else {
                        self.sttPlaceholder = nil
                        self.inputText = text
                        trace?.setValue("success", forAttribute: "result_type")
                        trace?.setValue(String(text.count), forAttribute: "transcription_length")
                        // End Live Activity with transcribed text
                        LiveActivityManager.shared.endRecordingActivity(text: text)
                    }
                    self.isTranscribing = false
                    self.recordingStartTime = nil

                    ReviewRequestManager.shared.recordSTTAndMaybePrompt()
                    PerformanceTracker.shared.stopOperationTrace(trace, attributes: ["status": "success"])
                } catch is CancellationError {
                    // Task was cancelled, don't update UI
                    PerformanceTracker.shared.stopOperationTrace(trace, attributes: ["status": "cancelled"])
                    LiveActivityManager.shared.endRecordingActivity(cancelled: true)
                    self.recordingStartTime = nil
                    return
                } catch {
                    let ns = error as NSError
                    let status = (ns.userInfo["status"] as? Int) ?? ns.code

                    switch status {
                    case 429:
                        self.errorMessage = "You're tapping faster than my brain can think… chill for a sec"
                    case 500:
                        self.errorMessage = "Yeah that's on me, not you. Fixing the chaos"
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                    self.isTranscribing = false
                    self.recordingStartTime = nil
                    // End Live Activity with error
                    LiveActivityManager.shared.endRecordingActivity(error: true)
                    PerformanceTracker.shared.stopOperationTrace(trace, attributes: [
                        "status": "error",
                        "error_code": String(status)
                    ])
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            LiveActivityManager.shared.endRecordingActivity(error: true)
            recordingStartTime = nil
        }
    }
    
    func stopRecording() {
        currentTranscriptionTask?.cancel()
        currentTranscriptionTask = nil
        speechStreamingManager.stop()
        audioRecorder.stop()
        isRecording = false
        isTranscribing = false
        audioLevel = -160
        recordingStartTime = nil
        // End Live Activity (cancelled)
        LiveActivityManager.shared.endRecordingActivity(cancelled: true)
    }
    
    func translate(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let useCase = translateSentenceUseCase else {
            errorMessage = "Translation engine not ready yet. Please wait a moment."
            return
        }

        sttPlaceholder = nil
        inputText = text

        let normalized = text.lowercased()
        let hasCache = useCase.peekCache(normalized) != nil
        isLoading = !hasCache
        isTranslated = false
        translatedText = nil
        slangDetected.removeAll()
        slangData.removeAll()
        errorMessage = nil

        // Start Translation Live Activity (only if not cached)
        if !hasCache {
            LiveActivityManager.shared.startTranslationActivity(input: text)
        }

        let startTime = Date()
        let trace = PerformanceTracker.shared.startOperationTrace(
            name: "translation_flow",
            attributes: [
                "input_length": String(text.count),
                "has_cache": String(hasCache)
            ]
        )

        Task {
            do {
                let result = try await useCase.execute(inputText)

                await MainActor.run {
                    self.result = result
                    self.translatedText = result.translation.englishTranslation
                    self.isTranslated = true
                    self.slangData = result.detectedSlangs
                    self.slangDetected = result.detectedSlangs.map { $0.slang }
                    self.isLoading = false

                    switch result.translation.source {
                    case .localDB:
                        logDebug("Loaded from SwiftData cache", category: .translation)
                        trace?.setValue("cache", forAttribute: "source")
                    case .openAI:
                        logDebug("Loaded from OpenAI", category: .translation)
                        trace?.setValue("api", forAttribute: "source")
                    default:
                        logDebug("Unknown source", category: .translation)
                        trace?.setValue("unknown", forAttribute: "source")
                    }

                    // End Translation Live Activity with result
                    LiveActivityManager.shared.endTranslationActivity(
                        result: result.translation.englishTranslation,
                        slangsCount: result.detectedSlangs.count
                    )
                }
                ReviewRequestManager.shared.recordTranslationAndMaybePrompt()
                let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
                self.analytics.logLatency(feature: "translation_execute", milliseconds: elapsedMs)
                self.analytics.logNetworkSuccess()

                trace?.setValue(String(result.detectedSlangs.count), forAttribute: "slangs_detected")
                PerformanceTracker.shared.stopOperationTrace(trace, attributes: ["status": "success"])
            } catch {
                await MainActor.run {
                    let ns = error as NSError
                    let code = ns.code
                    let status = (ns.userInfo["status"] as? Int) ?? code
                    if status == 429 {
                        self.errorMessage = "Whoaa wait... you're not that special... please wait..."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false

                    // End Translation Live Activity with error
                    LiveActivityManager.shared.endTranslationActivity(error: true)
                }
                self.analytics.logNetworkError()
                self.analytics.log(.extensionError(code: "translation_execute_error"))
                PerformanceTracker.shared.stopOperationTrace(trace, attributes: ["status": "error"])
            }
        }
    }

    func reset() {
        // Cancel any pending tasks
        currentTranscriptionTask?.cancel()
        currentTranscriptionTask = nil

        inputText = ""
        translatedText = nil
        isTranslated = false
        isDetectedSlangShown = false
        isExpanded = false
        slangDetected.removeAll()
        slangData.removeAll()
        result = nil
        isLoading = false
        isTranscribing = false
        errorMessage = nil
        sttPlaceholder = nil
    }
    
    func editText(text: String) {
        inputText = text
        translatedText = nil
        isTranslated = false
        isDetectedSlangShown = false
        isExpanded = false
        slangDetected.removeAll()
        slangData.removeAll()
        result = nil
        isLoading = false
        errorMessage = nil
        sttPlaceholder = nil
    }
    
    func copyToClipboard() {
        guard let text = translatedText else { return }
        UIPasteboard.general.string = text
        copiedToKeyboardAlert = true
    }

    func expandedView() {
        withAnimation {
            isExpanded.toggle()
        }
    }
    
    func showDetectedSlang() {
        withAnimation {
            isDetectedSlangShown.toggle()
        }
    }
    
    private let emptySTTMessages = [
        "Transcribing the void… still void, try again or just type, your call.",
        "If silence was a language, you nailed it, wanna retry or just type it?",
        "Silence level: legendary, try again or just type, whatever works.",
        "That was spiritual, but I need sound, wanna try again or just type?",
        "Bro said… literally nothing, retry or just type, no pressure.",
        "Seems like you didn’t say anything, try again or just type, up to you.",
        
        "Your mic just heard pure emptiness, try again or type it out.",
        "Nothing but silence detected, wanna give it another shot or type?",
        "You summoned zero decibels, retry or just type if that’s easier.",
        "Absolute quiet, iconic, try again or type your thoughts instead.",
        "You spoke in telepathy again, retry or just type for real.",
        "The mic caught air vibes only, try again or type something.",
        "That was deep silence, impressive, now retry or type it.",
        "Empty audio received, wanna try again or just type it in?",
        "You whispered to the void, and the void whispered back nothing, try again or type.",
        "Silence detected, aesthetic choice, retry or type, whatever vibes.",
        "Not a single sound wave survived, try again or just type.",
        "Your silence was loud, but not helpful, try again or type.",
        "Mic picked up existential nothingness, retry or type, go for it.",
        "Zero words given, zero words returned, try again or type instead.",
        "The universe heard you say absolutely nothing, try again or type.",
        "Bold silence move, retry or type, your decision.",
        "Void energy strong today, try again or type something.",
        "Your audio said *nothing but vibes*, retry or type it below.",
        "Silence mastery unlocked, try again or just type."
    ]
}
