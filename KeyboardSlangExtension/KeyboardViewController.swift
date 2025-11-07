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
        let settings = UserDefaults(suiteName: "group.prammmoe.SLNG")
        let autoCorrect = settings?.bool(forKey: "settings.autoCorrect") ?? true
        let autoCaps = settings?.bool(forKey: "settings.autoCaps") ?? true
        let layoutRaw = settings?.string(forKey: "settings.keyboardLayout") ?? "QWERTY"
        
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
                guard let self, self.textDocumentProxy.hasText else { return }
                self.textDocumentProxy.deleteBackward()
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
    }

    // MARK: - Auto Correct Handling
    private func handleInsert(_ text: String) {
        guard let vm = viewModelRef else {
            textDocumentProxy.insertText(text)
            return
        }
        if vm.autoCorrectEnabled {
            if text == " " {
                applyAutoCorrectOnSpace()
            } else if [".", ",", "!", "?", ";", ":"].contains(text) {
                applyAutoCorrectOnPunctuation(text)
            } else {
                textDocumentProxy.insertText(text)
            }
        } else {
            textDocumentProxy.insertText(text)
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

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
}

