//
//  DictionaryViewModel.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import Foundation
internal import Combine
import AVFoundation
import SwiftUI

final class DictionaryViewModel: ObservableObject {
    // MARK: - Published States
    @Published var searchText: String = ""
    @Published var selectedIndex: Int = 0
    @Published var dragActiveLetter: String? = nil
    @Published var currentIndexLetter: String? = nil
    @Published var filteredSlangs: [SlangData] = []
    
    // MARK: - Private Data
    private var allSlangs: [SlangData] = []
    private var cancellables = Set<AnyCancellable>()
    private let letters = (97...122).compactMap { String(UnicodeScalar($0)) } // a-z
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Dependencies
    private let slangRepository: SlangRepository
    
    // MARK: - Init
    init(slangRepository: SlangRepository = SlangRepositoryImpl()) {
        self.slangRepository = slangRepository
        loadAllSlangs()
        setupSearchListener()
        prepareSound()
    }
    
    // MARK: - Refresh after search
    func refreshAfterSearch() {
        if searchText.isEmpty {
            filteredSlangs = allSlangs
        } else {
            filteredSlangs = allSlangs.filter {
                $0.slang.localizedCaseInsensitiveContains(searchText) ||
                $0.translationEN.localizedCaseInsensitiveContains(searchText) ||
                $0.translationID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedIndex >= filteredSlangs.count {
            selectedIndex = max(0, filteredSlangs.count - 1)
        }
    }

    // MARK: - Data Load
    private func loadAllSlangs() {
        allSlangs = slangRepository
            .loadAll()
            .sorted { $0.slang.lowercased() < $1.slang.lowercased() }
        filteredSlangs = allSlangs
    }
    
    // MARK: - Search Filtering
    private func setupSearchListener() {
        $searchText
            .debounce(for: .milliseconds(120), scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                
                if text.isEmpty {
                    self.filteredSlangs = self.allSlangs
                } else {
                    self.filteredSlangs = self.allSlangs.filter {
                        $0.slang.localizedCaseInsensitiveContains(text) ||
                        $0.translationEN.localizedCaseInsensitiveContains(text) ||
                        $0.translationID.localizedCaseInsensitiveContains(text)
                    }
                }
                
                if self.selectedIndex >= self.filteredSlangs.count {
                    self.selectedIndex = max(0, self.filteredSlangs.count - 1)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Interaction (untuk DictionaryView)
    func handleLetterDrag(_ letter: String) {
        dragActiveLetter = letter
        
        if let newIndex = filteredSlangs.firstIndex(where: {
            $0.slang.lowercased().hasPrefix(letter.lowercased())
        }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIndex = newIndex
            }
            playClickSound()
        }
    }
    
    func handleLetterDragEnd() {
        dragActiveLetter = nil
    }
    
    func handleLetterTap(_ letter: String) {
        guard !filteredSlangs.isEmpty else { return }
        currentIndexLetter = letter
        
        if let index = filteredSlangs.firstIndex(where: {
            $0.slang.lowercased().hasPrefix(letter.lowercased())
        }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedIndex = index
            }
            playClickSound()
        }
    }
    
    func isLetterActive(_ letter: String) -> Bool {
        guard filteredSlangs.indices.contains(selectedIndex) else { return false }
        let current = filteredSlangs[selectedIndex].slang.lowercased()
        return current.first?.description == letter || dragActiveLetter == letter
    }
    
    func getSlang(at index: Int) -> SlangData? {
        guard index < filteredSlangs.count else { return nil }
        return filteredSlangs[index]
    }
    
    // MARK: - Sound
    private func prepareSound() {
        guard let soundURL = Bundle.main.url(forResource: "wheel_click", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.volume = 1.0
        } catch {
            print("Failed to load sound: \(error.localizedDescription)")
        }
    }
    
    func playClickSound() {
        guard let player = audioPlayer else { return }
        player.currentTime = 0
        player.play()
    }
}
