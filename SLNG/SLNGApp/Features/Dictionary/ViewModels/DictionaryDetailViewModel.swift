//
//  DictionaryDetailViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 03/11/25.
//
import Foundation
import AVFoundation
internal import Combine
@MainActor
final class DictionaryDetailViewModel: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String, language: String = "id-ID") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.2
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
}
