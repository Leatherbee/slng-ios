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
    
    private var useCase: TranslateSentenceUseCase?
    
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
        let useCase = TranslateSentenceUseCaseImpl(translationRepository: translationRepository, slangRepository: slangRepository)

        await MainActor.run {
            self.useCase = useCase
            self.isInitializing = false
        }
    }
    
    func translate(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let useCase = useCase else {
            errorMessage = "Translation engine not ready yet. Please wait a moment."
            return
        }
        
        inputText = text
        isLoading = true
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

