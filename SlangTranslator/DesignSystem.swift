//
//  Untitled.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 26/10/25.
//
import SwiftUI

struct DesignSystem {
    struct Colors {
        static let textPrimary = Color(hex: "#131212")
        static let textPrimaryDark = Color(hex: "#FEFBF7")
        static let textSecondary = Color(hex: "#808080")
        static let textDisable = Color(hex: "#CCCCCC")
        static let textDisableDark = Color(hex: "#4D4D4D")
        static let buttonDisable = Color(hex:"#B2B2B2")
        static let buttonPrimary = Color(hex: "#1A1A1A")
        static let backgroundSecondary = Color(hex: "#FCF6EA")
        static let backgroundSecondaryDark = Color(hex: "#131212")
    }

}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

