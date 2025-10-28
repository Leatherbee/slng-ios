//
//  TranslateViewModel.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 27/10/25.
//

import SwiftUI
internal import Combine

class TranslateViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var translatedText: String? = nil
    @Published var isTranslated: Bool = false
    @Published var isExpanded: Bool = false
    @Published var copiedToKeyboardAlert: Bool = false
    @Published var isDetectedSlangShown: Bool = false
    @Published var slangDetected: [String] = ["gw", "udh", "males"]
    
    func translate(text:String) {
        inputText = text
        translatedText = text
        isTranslated = true
    }
    
    func reset() {
        inputText = ""
        translatedText = nil
        isTranslated = false
        isDetectedSlangShown.toggle()
        isExpanded.toggle()
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = translatedText
        copiedToKeyboardAlert = true
    }

    func expandedView() {
        isExpanded.toggle()
    }
    
    func showDetectedSlang(){
        isDetectedSlangShown.toggle()
    }
}
