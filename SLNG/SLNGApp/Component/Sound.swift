//
//  Sound.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 18/11/25.
//

import AVFoundation

enum SoundPlayer {
    static var player: AVAudioPlayer?
    private static var isEnabled: Bool {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
        if defaults.object(forKey: "soundEffectEnabled") == nil { return true }
        return defaults.bool(forKey: "soundEffectEnabled")
    }

    /// Play sound by filename string (auto detect extension)
    static func play(_ filename: String) {
        guard isEnabled else { return }
        let components = filename.split(separator: ".")
        guard let name = components.first else {
            #if DEBUG
            print("Invalid sound filename:", filename)
            #endif
            return
        }

        // Ambil ekstensi: jika tidak ada → default "wav"
        let ext = components.count > 1 ? String(components.last!) : "wav"

        guard let url = Bundle.main.url(forResource: String(name), withExtension: ext) else {
            #if DEBUG
            print("Sound not found:", filename)
            #endif
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            #if DEBUG
            print("Error playing sound:", error)
            #endif
        }
    }
}
