//
//  ShareTranslateViewModel.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 24/10/25.
//

import Foundation
import Combine
import SwiftUI
import SwiftData

@MainActor
final class ShareTranslateViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var result: TranslationResult?
    @Published var detectedSlang: [SlangData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let useCase: TranslateSentenceUseCase

    init(useCase: TranslateSentenceUseCase) {
        self.useCase = useCase
    }

    func translate() async {
        guard !inputText.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            let result = try await useCase.execute(inputText)
            self.result = result
            self.detectedSlang = result.detectedSlangs
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}


