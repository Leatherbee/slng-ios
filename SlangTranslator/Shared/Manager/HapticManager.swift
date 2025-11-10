//
//  HapticManager.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 09/11/25.
//

import CoreHaptics
import AVFoundation

class HapticManager {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    func playBurstHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness1], relativeTime: 0)
        events.append(event1)
        
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness2], relativeTime: 0.05)
        events.append(event2)
        
        let intensityContinuous = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpnessContinuous = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        let eventContinuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityContinuous, sharpnessContinuous],
            relativeTime: 0.08,
            duration: 0.15
        )
        events.append(eventContinuous)
        
        let intensity4 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness4 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event4 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity4, sharpness4], relativeTime: 0.23)
        events.append(event4)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    func playExplosionHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        for i in 0..<3 {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.4 + (0.2 * Double(i))))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: Double(i) * 0.03
            )
            events.append(event)
        }
        
        let explosionIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let explosionSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        let explosion = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [explosionIntensity, explosionSharpness],
            relativeTime: 0.09
        )
        events.append(explosion)
        
        let rumbleIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let rumbleSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let rumble = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [rumbleIntensity, rumbleSharpness],
            relativeTime: 0.1,
            duration: 0.2
        )
        events.append(rumble)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play explosion haptic: \(error)")
        }
    }
}
