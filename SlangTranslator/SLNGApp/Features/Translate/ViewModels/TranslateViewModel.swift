//
//  TranslateViewModel.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 27/10/25.
//

import Foundation
import SwiftUI
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
                Task { @MainActor in self.errorMessage = "Microphone access denied" }
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
                Task { @MainActor in self.isRecording = true }
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
                        self.inputText = text
                        self.isTranscribing = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
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
                    self.errorMessage = error.localizedDescription
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
}

