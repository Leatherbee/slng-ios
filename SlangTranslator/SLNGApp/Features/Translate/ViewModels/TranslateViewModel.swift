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
import FirebaseAnalytics

@MainActor
final class TranslateViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var translatedText: String? = nil
    @Published var isTranslated: Bool = false
    @Published var isExpanded: Bool = false
    @Published var copiedToKeyboardAlert: Bool = false
    @Published var isDetectedSlangShown: Bool = false
    @Published var slangDetected: [String] = []
    @Published var slangData: [SlangData] = []
    
    @Published var isLoading: Bool = false
    @Published var isInitializing: Bool = true
    @Published var errorMessage: String? = nil
    
    @Published var result: TranslationResult? = nil
    @Published var isRecording: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var sttPlaceholder: String? = nil
    @Published var audioLevel: Float = -160
    @Published var isRecorderUIVisible: Bool = false
    
    private let audioRecorder = AudioRecorderManager()
    private let speechStreamingManager = SpeechStreamingManager()
    
    private var translateSentenceUseCase: TranslateSentenceUseCase?
    private var speechUseCase: TranscribeSpeechUseCase?

    func prewarmPermissions() {
        Analytics.logEvent("permissions_prompt", parameters: [
            "permission_type": "microphone"
        ])
        audioRecorder.requestPermission { granted in
            Analytics.logEvent("permissions_response", parameters: [
                "permission_type": "microphone",
                "result": granted ? "authorized" : "denied"
            ])
        }
        Analytics.logEvent("permissions_prompt", parameters: [
            "permission_type": "speech_recognition"
        ])
        speechStreamingManager.requestAuthorization { granted in
            Analytics.logEvent("permissions_response", parameters: [
                "permission_type": "speech_recognition",
                "result": granted ? "authorized" : "denied"
            ])
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
        audioRecorder.requestPermission { micGranted in
            if !micGranted {
                Task { @MainActor in self.errorMessage = "Mic’s locked. Open Settings and free it" }
                Analytics.logEvent("permissions_response", parameters: [
                    "permission_type": "microphone",
                    "result": "denied"
                ])
                return
            }
            do {
                self.audioRecorder.setLevelUpdateHandler { level in
                    Task { @MainActor in
                        self.audioLevel = level
                    }
                }
                try self.audioRecorder.start()
                Task { @MainActor in
                    self.sttPlaceholder = nil
                    self.isRecording = true
                }
                Analytics.logEvent("permissions_response", parameters: [
                    "permission_type": "microphone",
                    "result": "authorized"
                ])
            } catch {
                Task { @MainActor in self.errorMessage = error.localizedDescription }
            }
        }
    }
    
    func stopRecordingAndTranscribe() {
        // Hard gate: if mic not active or permission not granted, avoid backend calls
        let perm = AVAudioApplication.shared.recordPermission
        if perm != .granted {
            Task { @MainActor in
                self.errorMessage = "Your mic said no. Respectfully, fix that in Settings"
                self.isRecording = false
                self.isTranscribing = false
                self.audioLevel = -160
            }
            return
        }
        speechStreamingManager.stop()
        do {
            let result = try audioRecorder.stopAndFetchData()
            isRecording = false
            audioLevel = -160
            guard let speechUseCase else { return }
            isTranscribing = true
            Task {
                do {
                    let text = try await speechUseCase.execute(audioData: result.data, fileName: result.fileName, mimeType: result.mimeType)
                    await MainActor.run {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            let randomFallback = emptySTTMessages.randomElement() ?? "Seems like you didn’t say anything"
                            self.sttPlaceholder = randomFallback
                            self.isTranscribing = false
                        } else {
                            self.sttPlaceholder = nil
                            self.inputText = text
                            self.isTranscribing = false
                        }
                    }
                    ReviewRequestManager.shared.recordSTTAndMaybePrompt()
                } catch {
                    await MainActor.run {
                        let ns = error as NSError
                        let code = ns.code
                        let status = (ns.userInfo["status"] as? Int) ?? code
                        if status == 429 {
                            self.errorMessage = "You’re tapping faster than my brain can think… chill for a sec"
                        } else if status == 500 {
                            self.errorMessage = "Yeah that’s on me, not you. Fixing the chaos"
                        } else {
                            self.errorMessage = error.localizedDescription
                        }
                        self.isTranscribing = false
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRecording() {
        speechStreamingManager.stop()
        audioRecorder.stop()
        isRecording = false
        audioLevel = -160
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
        
        let startTime = Date()
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
                        print("Loaded from SwiftData cache")
                    case .openAI:
                        print("Loaded from OpenAI")
                    default:
                        print("Unknown source")
                    }
                }
                ReviewRequestManager.shared.recordTranslationAndMaybePrompt()
                let elapsedMs = Int(Date().timeIntervalSince(startTime) * 1000)
                let bucket: String = elapsedMs < 50 ? "<50ms" : elapsedMs < 100 ? "50-100ms" : elapsedMs < 250 ? "100-250ms" : elapsedMs < 500 ? "250-500ms" : ">=500ms"
                Analytics.logEvent("latency_bucket", parameters: [
                    "feature_name": "translation_execute",
                    "bucket": bucket
                ])
                Analytics.logEvent("network_status", parameters: [
                    "status": "online"
                ])
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
                }
                Analytics.logEvent("network_status", parameters: [
                    "status": "error"
                ])
                Analytics.logEvent("extension_error", parameters: [
                    "code": "translation_execute_error"
                ])
            }
        }
    }

    func reset() {
        inputText = ""
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
