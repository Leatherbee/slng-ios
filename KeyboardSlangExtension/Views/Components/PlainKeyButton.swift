//
//  PlainKeyButton.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 05/11/25.
//

import SwiftUI

struct PlainKeyButton: View {
    let label: String?
    let systemName: String?
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    let action: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    private var style: KeyStyle { KeyStyle(isDark: scheme == .dark) }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(style.keyFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(style.keyStroke, lineWidth: 0.4)
                    )
                    .shadow(color: style.keyShadow, radius: 0.4, y: 0.4)
                
                Group {
                    if let label = label {
                        Text(label)
                            .font(.system(size: fontSize))
                    }
                    if let systemName = systemName {
                        Image(systemName: systemName)
                            .font(.system(size: 18, weight: .medium))
                    }
                }
                .foregroundColor(style.keyText)
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
    }
}
