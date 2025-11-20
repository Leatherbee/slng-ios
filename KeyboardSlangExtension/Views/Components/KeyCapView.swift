//
//  KeyCap.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 05/11/25.
//

import SwiftUI

struct KeyCapView: View {
    let label: String
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    let action: () -> Void
    
    @GestureState private var isTouching = false
    @State private var showBubble = false
    @State private var pressed = false
    
    @Environment(\.colorScheme) private var scheme
    private var style: KeyStyle { KeyStyle(isDark: scheme == .dark) }
    
    var body: some View {
        ZStack {
            if showBubble {
                keyPopupBubble
            }
            keyButton
        }
        .frame(width: width, height: height)
        .scaleEffect(pressed ? 0.92 : 1.0)
        .contentShape(Rectangle())
        .gesture(dragGesture)
    }
    
    private var keyPopupBubble: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(style.popupFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(style.popupStroke, lineWidth: 0.6)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 2.5, y: 2.5)
                
                Text(label)
                    .font(.system(size: max(fontSize + 6, 24), weight: .medium))
                    .foregroundColor(scheme == .dark ? .white : .black)
                    .padding(.vertical, 2)
            }
            .frame(width: width + 14, height: height + 16)
            .offset(y: -height - 18)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var keyButton: some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(style.keyFill)
            .overlay(
                RoundedRectangle(cornerRadius: 9 )
                    .stroke(style.keyStroke, lineWidth: 0.4)
            )
            .shadow(color: style.keyShadow, radius: 0.4, y: 0.5)
            .overlay(
                Text(label)
                    .font(.system(size: fontSize, weight: .regular))
                    .kerning(0.2)
                    .foregroundColor(style.keyText)
            )
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { _ in
                guard !pressed else { return }
                pressed = true
                withAnimation(.easeOut(duration: 0.08)) { showBubble = true }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    pressed = false
                    showBubble = false
                }
                action()
            }
    }
}
