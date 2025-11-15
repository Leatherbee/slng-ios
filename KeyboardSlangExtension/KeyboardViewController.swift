//
//  KeyboardViewController.swift
//  KeyboardSlangExtension
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//

import UIKit
import SwiftUI
import SwiftData

class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<SlangKeyboardView>?
    private var keyboardHeight: CGFloat = 270
    private var viewModelRef: SlangKeyboardViewModel?
    private let textChecker = UITextChecker()
    private func recordExtEvent(_ name: String, params: [String: String]? = nil) {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
        let countKey = "analytics/.\(name)/.count"
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
        if let params {
            let dictKey = "analytics/.\(name)/.last_params"
            defaults.set(params, forKey: dictKey)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize vm
        let context = SharedModelContainer.shared.container.mainContext
        let apiKey = Bundle.main.infoDictionary?["APIKey"] as? String ?? ""
        
        let translationRepository = TranslationRepositoryImpl(apiKey: apiKey, context: context)
        let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
        
        let useCase = TranslateSentenceUseCaseImpl(translationRepository: translationRepository, slangRepository: slangRepository
        )
        let viewModel = SlangKeyboardViewModel(useCase: useCase)
        self.viewModelRef = viewModel
        
        // Read settings from App Group UserDefaults
        let settings = UserDefaults(suiteName: "group.prammmoe.SLNG")!
        // Register defaults so first run has expected values
        settings.register(defaults: [
            "settings.autoCorrect": true,
            "settings.autoCaps": true,
            "settings.keyboardLayout": "QWERTY"
        ])
        // Use object(forKey:) to distinguish missing keys (nil) from false
        let autoCorrect = (settings.object(forKey: "settings.autoCorrect") as? Bool) ?? true
        let autoCaps = (settings.object(forKey: "settings.autoCaps") as? Bool) ?? true
        let layoutRaw = settings.string(forKey: "settings.keyboardLayout") ?? "QWERTY"
        
        // Apply settings to VM
        viewModel.applySettings(autoCorrect: autoCorrect, autoCaps: autoCaps, layoutRaw: layoutRaw)
        if autoCaps {
            // Start shifted to capitalize first character
            viewModel.isShifted = true
        }
         
        let root = SlangKeyboardView(
            insertText: { [weak self] text in
                guard let self else { return }
                self.handleInsert(text)
            },
            deleteText: { [weak self] in
                guard let self else { return }
                self.handleDelete()
            },
            keyboardHeight: keyboardHeight,
            backgroundColor: .clear, needsInputModeSwitchKey: self.needsInputModeSwitchKey,
            nextKeyboardAction: #selector(self.handleInputModeList(from:with:)),
            vm: viewModel
        )
        
        let hosting = UIHostingController(rootView: root)
        hosting.view.backgroundColor = .clear
         
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
         
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.hostingController = hosting
         
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: keyboardHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        recordExtEvent("keyboard_open", params: [
            "locale": Locale.current.identifier
        ])
    }

    // MARK: - Auto Correct Handling
    private func handleInsert(_ text: String) {
        guard let vm = viewModelRef else {
            textDocumentProxy.insertText(text)
            return
        }
        if text == " " {
            textDocumentProxy.insertText(" ")
        } else if [".", ",", "!", "?", ";", ":"].contains(text) {
            textDocumentProxy.insertText(text)
            if vm.autoCapsEnabled {
                vm.isShifted = true
            }
        } else {
            textDocumentProxy.insertText(text)
        }

        // Recompute auto shift when needed (e.g., after newline)
        if vm.autoCapsEnabled, text == "\n" {
            updateAutoShiftFromContext()
        }
    }

    private func applyAutoCorrectOnSpace() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let components = before.split(whereSeparator: { $0.isWhitespace })
        guard let lastWordSub = components.last else {
            textDocumentProxy.insertText(" ")
            return
        }
        let lastWord = String(lastWordSub)
        guard !lastWord.isEmpty else {
            textDocumentProxy.insertText(" ")
            return
        }

        // Determine language code (prefer current input mode, fallback to en_US)
        let lang = (self.textInputMode?.primaryLanguage?.replacingOccurrences(of: "-", with: "_")) ?? "en_US"

        // Find range of the last word in the entire context
        if let range = before.range(of: lastWord, options: .backwards) {
            let nsRange = NSRange(range, in: before)

            // Try system corrections first (for misspellings)
            var replacement: String?

            // If misspelled, get guesses
            let missRange = textChecker.rangeOfMisspelledWord(in: before, range: nsRange, startingAt: nsRange.location, wrap: false, language: lang)
            if missRange.location != NSNotFound,
               let guesses = textChecker.guesses(forWordRange: nsRange, in: before, language: lang),
               let first = guesses.first {
                replacement = first
            }

            // If no guesses, try completions (for partial words)
            if replacement == nil,
               let completions = textChecker.completions(forPartialWordRange: nsRange, in: before, language: lang),
               let first = completions.first {
                replacement = first
            }

            // Simple capitalization for single-letter i
            if replacement == nil && lastWord == "i" {
                replacement = "I"
            }

            if let corrected = replacement, corrected != lastWord {
                for _ in 0..<lastWord.count { if textDocumentProxy.hasText { textDocumentProxy.deleteBackward() } }
                textDocumentProxy.insertText(corrected)
            }
        }

        textDocumentProxy.insertText(" ")
    }

    private func applyAutoCorrectOnPunctuation(_ punct: String) {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        if before.hasSuffix(" ") && textDocumentProxy.hasText {
            textDocumentProxy.deleteBackward()
        }
        textDocumentProxy.insertText(punct)
        if viewModelRef?.autoCapsEnabled == true {
            viewModelRef?.isShifted = true
        }
    }

    // MARK: - Backspace Handling with Auto Caps
    private func handleDelete() {
        guard textDocumentProxy.hasText else { return }
        textDocumentProxy.deleteBackward()
        updateAutoShiftFromContext()
    }

    private func updateAutoShiftFromContext() {
        guard let vm = viewModelRef else { return }
        // If caps lock is on, remain shifted
        if vm.isCapsLockOn { vm.isShifted = true; return }
        guard vm.autoCapsEnabled else { return }
        vm.isShifted = shouldEnableAutoShift()
    }

    private func shouldEnableAutoShift() -> Bool {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        // Start of field or only whitespace -> enable
        if before.isEmpty { return true }
        let trimmed = before.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        // Last non-whitespace char decides sentence boundary
        guard let last = trimmed.last else { return false }
        if ".!?".contains(last) { return true }
        // Also treat newline as boundary
        if before.hasSuffix("\n") { return true }
        return false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recordExtEvent("keyboard_close", params: nil)
    }
}

