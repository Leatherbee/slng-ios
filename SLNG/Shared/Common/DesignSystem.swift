//
//  DesignSystem.swift
//  SlangTranslator
//
//  Centralized design system constants for animations, spacing, and layout.
//  Replaces scattered magic numbers throughout the codebase.
//

import SwiftUI

// MARK: - Animation Constants

enum DSAnimation {
    // MARK: - Duration Constants
    enum Duration {
        static let instant: Double = 0.08
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let medium: Double = 0.4
        static let slow: Double = 0.5
        static let slower: Double = 0.6
        static let long: Double = 1.2
    }

    // MARK: - Spring Response Constants
    enum Spring {
        static let snappy: Double = 0.25
        static let normal: Double = 0.35
        static let gentle: Double = 0.42
        static let relaxed: Double = 0.5
        static let soft: Double = 0.55
        static let slow: Double = 0.6
    }

    // MARK: - Damping Constants
    enum Damping {
        static let bouncy: Double = 0.5
        static let slight: Double = 0.6
        static let normal: Double = 0.7
        static let firm: Double = 0.8
        static let stiff: Double = 0.82
        static let rigid: Double = 0.85
    }

    // MARK: - Pre-built Animations
    static let quickSpring = Animation.interactiveSpring(response: Spring.snappy, dampingFraction: Damping.stiff)
    static let normalSpring = Animation.interactiveSpring(response: Spring.normal, dampingFraction: Damping.firm)
    static let gentleSpring = Animation.interactiveSpring(response: Spring.gentle, dampingFraction: Damping.firm)
    static let softSpring = Animation.interactiveSpring(response: Spring.soft, dampingFraction: Damping.firm)
    static let relaxedSpring = Animation.interactiveSpring(response: Spring.relaxed, dampingFraction: Damping.bouncy)
    static let slowSpring = Animation.interactiveSpring(response: Spring.slow, dampingFraction: Damping.normal)

    static let fastEaseInOut = Animation.easeInOut(duration: Duration.fast)
    static let normalEaseInOut = Animation.easeInOut(duration: Duration.normal)
    static let mediumEaseInOut = Animation.easeInOut(duration: Duration.medium)
    static let slowEaseInOut = Animation.easeInOut(duration: Duration.slow)

    static let fastEaseOut = Animation.easeOut(duration: Duration.fast)
    static let normalEaseOut = Animation.easeOut(duration: Duration.normal)
    static let slowEaseOut = Animation.easeOut(duration: Duration.slow)
    static let slowerEaseOut = Animation.easeOut(duration: Duration.slower)

    static let fastEaseIn = Animation.easeIn(duration: Duration.fast)
    static let normalEaseIn = Animation.easeIn(duration: Duration.normal)
    static let slowEaseIn = Animation.easeIn(duration: Duration.slow)

    // Theme selection animation
    static let themeSelection = Animation.spring(response: Spring.slow, dampingFraction: Damping.slight, blendDuration: 0)

    // Card toggle animation
    static let cardToggle = Animation.spring(response: Spring.normal, dampingFraction: Damping.firm, blendDuration: Duration.fast)

    // Loading animation
    static func loadingSpring(stiffness: Double = 180, damping: Double = 12) -> Animation {
        .interpolatingSpring(stiffness: stiffness, damping: damping)
    }
}

// MARK: - Spacing Constants

enum DSSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    static let huge: CGFloat = 48
}

// MARK: - Corner Radius Constants

enum DSRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Layout Constants

enum DSLayout {
    // Settings overlay
    static let settingsOverlayStart: CGFloat = 800
    static let settingsOverlayVisibleThreshold: CGFloat = 120
    static let settingsOverlayDismissThreshold: CGFloat = 420

    // Drag thresholds
    static let dragThresholdSmall: CGFloat = 50
    static let dragThresholdMedium: CGFloat = 100
    static let dragThresholdLarge: CGFloat = 150

    // Button sizes
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightMedium: CGFloat = 44
    static let buttonHeightLarge: CGFloat = 52

    // Icon sizes
    static let iconSizeSmall: CGFloat = 16
    static let iconSizeMedium: CGFloat = 24
    static let iconSizeLarge: CGFloat = 32
}

// MARK: - Opacity Constants

enum DSOpacity {
    static let invisible: Double = 0
    static let faint: Double = 0.1
    static let light: Double = 0.3
    static let medium: Double = 0.5
    static let strong: Double = 0.7
    static let heavy: Double = 0.85
    static let full: Double = 1.0
}

// MARK: - Font Size Constants

enum DSFontSize {
    static let caption2: CGFloat = 10
    static let caption: CGFloat = 12
    static let footnote: CGFloat = 13
    static let subheadline: CGFloat = 15
    static let body: CGFloat = 17
    static let headline: CGFloat = 17
    static let title3: CGFloat = 20
    static let title2: CGFloat = 22
    static let title: CGFloat = 28
    static let largeTitle: CGFloat = 34
}

// MARK: - Haptic Intensity Constants

enum DSHaptic {
    static let light: CGFloat = 0.3
    static let medium: CGFloat = 0.5
    static let strong: CGFloat = 0.7
    static let heavy: CGFloat = 1.0
}

// MARK: - Audio Constants

enum DSAudio {
    static let volumeLow: Float = 0.25
    static let volumeMedium: Float = 0.5
    static let volumeHigh: Float = 0.75
    static let volumeFull: Float = 1.0

    static let silenceThreshold: Float = -160
}

// MARK: - Timing Constants

enum DSTiming {
    static let debounceShort: Double = 0.1
    static let debounceNormal: Double = 0.2
    static let debounceLong: Double = 0.3
    static let throttleInterval: Double = 0.3
    static let autoHideDelay: Double = 2.0
    static let toastDuration: Double = 3.0
}
