//
//  SlangKeyboardViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//
import Foundation
import Combine
import Translation
import UIKit

enum KeyboardMode {
    case normal
    case explain
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class SlangKeyboardViewModel: ObservableObject {
    @Published var isShifted: Bool = false
    @Published var showTranslationPopup: Bool = false
    @Published var showNumber: Bool = false
    @Published var showNumbersShifted: Bool = false
    @Published var translatedText = ""
    @Published var mode: KeyboardMode = .normal
    @Published var contextEn: String = ""
    @Published var slangText: String = ""
    @Published var translationEN: String = ""
    @Published var exampleID: String = ""
    @Published var exampleEN: String = ""
    
    @Published var detectedSlangs: [SlangData] = []
    @Published var isTranslating: Bool = false
    @Published var translationError: String?
    @Published var result: TranslationResult?
    
    private let useCase: TranslateSentenceUseCase
    
    init(useCase: TranslateSentenceUseCase) {
        self.useCase = useCase
    }
    
    private let defaultRows: [[String]] = [
        Array("qwertyuiop").map { String($0) },
        Array("asdfghjkl").map { String($0) },
        Array("zxcvbnm").map { String($0) }
    ]
    
    private let rowsNumbers: [[String]] = [
        Array("1234567890").map { String($0) },
        Array("-/:;()$&@\"").map { String($0) },
        Array(".,?!'").map { String($0) }
    ]
    
    private let rowsNumbersShifted: [[String]] = [
        Array("[]{}#%^*+=").map { String($0) },
        Array("_\\|~<>€£¥•").map { String($0) },
        Array(".,?!'").map { String($0) }
    ]
    
    func getRows() -> [[String]] {
        if showNumbersShifted {
            return rowsNumbersShifted
        } else if showNumber {
            return rowsNumbers
        } else {
            return defaultRows
        }
    }
    
    func toggleShift() {
        if showNumber {
            toggleSymbol()
        } else {
            isShifted.toggle()
        }
    }
    
    func toggleNumber() {
        if showNumber || showNumbersShifted {
            showNumber = false
            showNumbersShifted = false
        } else {
            showNumber = true
            showNumbersShifted = false
        }
    }
    
    func toggleSymbol() {
        showNumbersShifted.toggle()
    }
    
    func changeDisplayMode(_ mode: KeyboardMode) {
        self.mode = mode
    }
    
    func getClipboardText() -> String {
        guard let pasteboardString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) else { return "" }
        return pasteboardString
    }
    
    func translateFromClipboard() async {
        guard let clipboardText = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardText.isEmpty else {
            self.translationError = "Clipboard is empty."
            return
        }
        
        self.translationError = nil
        self.translatedText = ""
        self.detectedSlangs.removeAll()
        
        do {
            let result = try await Task.detached(priority: .userInitiated) { [useCase] in
                try await useCase.execute(clipboardText)
            }.value
            
            self.result = result
            self.translatedText = result.translation.englishTranslation
            self.detectedSlangs = result.detectedSlangs
            
            if result.detectedSlangs.isEmpty {
                self.translationError = "No slang detected."
            }
        } catch {
            self.translationError = error.localizedDescription
        }
    }
}
