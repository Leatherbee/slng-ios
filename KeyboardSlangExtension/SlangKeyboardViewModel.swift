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
    @Published var translationSession: TranslationSession.Configuration?
    @Published var isTranslating: Bool = false
    @Published var translationError: String?
    
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
    
    // MARK: - Computed keyboard rows
    func getRows() -> [[String]] {
        if showNumbersShifted {
            return rowsNumbersShifted
        } else if showNumber {
            return rowsNumbers
        } else {
            return defaultRows
        }
    }
    
    // MARK: - Actions
    func toggleShift() {
        if showNumber {
            // Jika sedang mode angka → toggle simbol
            toggleSymbol()
        } else {
            // Jika huruf → toggle kapital
            isShifted.toggle()
        }
    }
    
    func toggleNumber() {
        if showNumber || showNumbersShifted {
            // Kembali ke huruf
            showNumber = false
            showNumbersShifted = false
        } else {
            // Masuk ke mode angka
            showNumber = true
            showNumbersShifted = false
        }
    }
    
    func toggleSymbol() {
        // Toggle antara angka dan simbol
        showNumbersShifted.toggle()
    }
    
    func changeDisplayMode(_ mode: KeyboardMode) {
        self.mode = mode
    }
    
    func translateFromClipboard() {
        guard let clipboardText = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboardText.isEmpty else {
            translationError = "Clipboard is empty."
            return
        }
        
        // Reset state
        translatedText = clipboardText
        detectedSlangs.removeAll()
        isTranslating = true
        translationError = nil
        
        // Cari slang dalam teks
        let found = SlangDictionary.shared.findSlang(in: clipboardText)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isTranslating = false
            self.detectedSlangs = found
            
            guard !found.isEmpty else {
                self.translationError = "No slang detected."
                self.translatedText = clipboardText
                self.showTranslationPopup = false
                return
            }
            
            // Gabungkan semua data yang ditemukan
            self.translatedText = found
                .map { "\($0.slang) → \($0.translationEN)" }
                .joined(separator: "\n")
            
            self.slangText = found
                .map { "\($0.slang)" }
                .joined(separator: "\n")
            
            self.translationEN = found
                .map { "\($0.translationEN)" }
                .joined(separator: "\n")
            
            // Gabungan konteks dan contoh (jika ada lebih dari satu slang)
            self.contextEn = found
                .map { "\($0.contextEN)" }
                .joined(separator: "\n\n")
            
            self.exampleID = found
                .map { "\($0.exampleID)" }
                .joined(separator: "\n\n")
            
            self.exampleEN = found
                .map { "\($0.exampleEN)" }
                .joined(separator: "\n\n")
            
            // Mode popup aktif
            self.showTranslationPopup = true
            
            // Debug
            print("Detected slangs:", found)
            print("Translated text:\n\(self.translatedText)")
        }
    }

}

