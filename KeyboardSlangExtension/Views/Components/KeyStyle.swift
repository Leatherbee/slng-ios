//
//  KeyStyle.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 05/11/25.
//

import SwiftUI

struct KeyStyle {
    let isDark: Bool
    
    var keyboardBackground: some ShapeStyle {
        isDark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray5)
    }
    
    var keyFill: some ShapeStyle {
        isDark ? Color(.systemGray5) : Color.white
    }
    
    var keyStroke: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    
    var keyShadow: Color {
        isDark ? Color.black.opacity(0.35) : Color.black.opacity(0.08)
    }
    
    var topBarFill: Color {
        isDark ? Color(.systemGray5).opacity(0.35) : Color(.systemGray6).opacity(0.6)
    }
    
    var popupFill: Color {
        isDark ? Color(.systemGray6) : .white
    }
    
    var popupStroke: Color {
        isDark ? Color.white.opacity(0.10) : Color(.systemGray4)
    }
    
    var keyText: Color { isDark ? .white : .primary }
    var labelText: Color { isDark ? Color.white.opacity(0.8) : .secondary }
}
