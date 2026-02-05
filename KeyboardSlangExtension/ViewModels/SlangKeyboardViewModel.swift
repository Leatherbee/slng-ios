//
//  SlangKeyboardViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//
import Foundation
internal import Combine
import Translation
import UIKit

enum KeyboardLayoutType: String, CaseIterable {
    case qwerty = "QWERTY"
    case qwertz = "QWERTZ"
    case azerty = "AZERTY"
}

enum KeyboardMode {
    case normal
    case explain
    case emoji
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class SlangKeyboardViewModel: ObservableObject {
    @Published var isShifted: Bool = false
    @Published var isCapsLockOn: Bool = false
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

    // Settings
    @Published var autoCorrectEnabled: Bool = true
    @Published var autoCapsEnabled: Bool = true
    private var layoutType: KeyboardLayoutType = .qwerty
    
    init(useCase: TranslateSentenceUseCase) {
        self.useCase = useCase
    }
    
    private var rowsAlphabetic: [[String]] {
        switch layoutType {
        case .qwerty:
            return [
                Array("qwertyuiop").map { String($0) },
                Array("asdfghjkl").map { String($0) },
                Array("zxcvbnm").map { String($0) }
            ]
        case .qwertz:
            return [
                Array("qwertzuiop").map { String($0) },
                Array("asdfghjkl").map { String($0) },
                Array("yxcvbnm").map { String($0) }
            ]
        case .azerty:
            return [
                Array("azertyuiop").map { String($0) },
                Array("qsdfghjklm").map { String($0) },
                Array("wxcvbn").map { String($0) }
            ]
        }
    }
    
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
            return rowsAlphabetic
        }
    }
    
    func toggleShift() {
        if showNumber {
            toggleSymbol()
        } else {
            if isCapsLockOn {
                // Single tap while caps lock is on disables caps lock and unshifts
                isCapsLockOn = false
                isShifted = false
            } else {
                isShifted.toggle()
            }
        }
    }

    func setCapsLock(on: Bool) {
        isCapsLockOn = on
        isShifted = on
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
        let hasCache = useCase.peekCache(clipboardText) != nil
        self.isTranslating = !hasCache
        
        do {
            let start = Date()
            let result = try await Task.detached(priority: .userInitiated) { [useCase] in
                try await useCase.execute(clipboardText)
            }.value
            
            self.result = result
            self.translatedText = result.translation.englishTranslation
            self.detectedSlangs = result.detectedSlangs
            self.isTranslating = false
            
            if result.detectedSlangs.isEmpty {
                self.translationError = "No slang detected."
            }
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let bucket = ms < 50 ? "<50ms" : ms < 100 ? "50-100ms" : ms < 250 ? "100-250ms" : ms < 500 ? "250-500ms" : ">=500ms"
            let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
            let key = "analytics.latency_bucket.clipboard_translation.\(bucket).count"
            defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
            let netKey = "analytics.network_status.online.count"
            defaults.set(defaults.integer(forKey: netKey) + 1, forKey: netKey)
        } catch {
            self.translationError = error.localizedDescription
            self.isTranslating = false
            let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
            let errKey = "analytics.extension_error.translation_error.count"
            defaults.set(defaults.integer(forKey: errKey) + 1, forKey: errKey)
            let netKey = "analytics.network_status.error.count"
            defaults.set(defaults.integer(forKey: netKey) + 1, forKey: netKey)
        }
    }

    func applySettings(autoCorrect: Bool, autoCaps: Bool, layoutRaw: String) {
        self.autoCorrectEnabled = autoCorrect
        self.autoCapsEnabled = autoCaps
        self.layoutType = KeyboardLayoutType(rawValue: layoutRaw) ?? .qwerty
    }
}
