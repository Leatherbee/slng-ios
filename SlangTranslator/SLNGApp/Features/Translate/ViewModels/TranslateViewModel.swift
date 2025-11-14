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
    
    private let audioRecorder = AudioRecorderManager()
    private let speechStreamingManager = SpeechStreamingManager()
    
    private var translateSentenceUseCase: TranslateSentenceUseCase?
    private var speechUseCase: TranscribeSpeechUseCase?

    func prewarmPermissions() {
        audioRecorder.requestPermission { _ in }
        speechStreamingManager.requestAuthorization { _ in }
    }
    
    init() {
        Task {
            await self.initializeDependencies()
        }
    }
    
    private func initializeDependencies() async {
        let context = SharedModelContainer.shared.container.mainContext
        let apiKey = Bundle.main.infoDictionary?[("APIKey")] as? String ?? ""
        let translationRepository = TranslationRepositoryImpl(apiKey: apiKey, context: context)
        let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
        let translateSentenceUseCase = TranslateSentenceUseCaseImpl(
            translationRepository: translationRepository,
            slangRepository: slangRepository
        )

        await MainActor.run {
            self.translateSentenceUseCase = translateSentenceUseCase
            self.isInitializing = false
        }

        let baseURLString = "https://slng-backend.vercel.app"
        if let url = URL(string: baseURLString) {
            let sttRepo = SpeechToTextRepositoryImpl(baseURL: url)
            let sttUseCase = TranscribeSpeechUseCaseImpl(repository: sttRepo)
            await MainActor.run {
                self.speechUseCase = sttUseCase
                print("Speech use case initialized with \(url)")
            }
        } else {
            await MainActor.run {
                self.errorMessage = "STT base URL invalid."
            }
        }
    }
    
    func startRecording() {
        audioRecorder.requestPermission { micGranted in
            if !micGranted {
                Task { @MainActor in self.errorMessage = "Microphone access denied" }
                return
            }
            do {
                try self.audioRecorder.start()
                Task { @MainActor in self.isRecording = true }
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
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
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

