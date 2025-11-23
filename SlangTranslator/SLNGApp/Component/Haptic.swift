//
//  Haptic.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 18/11/25.
//

import UIKit

public enum Haptics {
    public static var isEnabled: Bool {
        let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
        if defaults.object(forKey: "hapticEnabled") == nil { return true }
        return defaults.bool(forKey: "hapticEnabled")
    }
    // MARK: - Private Properties
    private static var lastFiredAt: [String: TimeInterval] = [:]
    private static let throttleInterval: TimeInterval = 0.3 // 300ms
    
    // MARK: - Notification Feedback
    public static func success() {
        fireThrottled("success") {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
    
    public static func warning() {
        fireThrottled("warning") {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        }
    }
    
    public static func error() {
        fireThrottled("error") {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }
    
    // MARK: - Selection Feedback
    public static func selection() {
        fireThrottled("selection") {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
    
    // MARK: - Impact Feedback
    public static func impactLight() {
        fireThrottled("impactLight") {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    public static func impactMedium() {
        fireThrottled("impactMedium") {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    public static func impactHeavy() {
        fireThrottled("impactHeavy") {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    public static func primaryButtonTap() {
        impactLight()
    }
    
    public static func lightImpact() {
        impactLight()
    }
    
    public static func locationPermissionTap() {
        impactMedium()
    }
    
    // MARK: - Private Methods
    private static func fireThrottled(_ key: String, action: @escaping () -> Void) {
        guard isEnabled else { return }
        DispatchQueue.main.async {
            let now = Date().timeIntervalSince1970
            let lastFired = lastFiredAt[key] ?? 0
            
            if now - lastFired >= throttleInterval {
                lastFiredAt[key] = now
                
                #if targetEnvironment(simulator)
                // No-op on simulator, optionally log
                #if DEBUG
                print("[Haptics] \(key) would fire on device")
                #endif
                #else
                action()
                #endif
            }
        }
    }
}
