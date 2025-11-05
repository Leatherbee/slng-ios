//
//  SlangKeyboardView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//

import SwiftUI
import SwiftData
import UIKit

struct KeyStyle {
    var isDark: Bool
    
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
                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(style.popupFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
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
            
            RoundedRectangle(cornerRadius: 6)
                .fill(style.keyFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
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
        .frame(width: width, height: height)
        .scaleEffect(pressed ? 0.92 : 1.0)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isTouching) { _, state, _ in state = true }
                .onChanged { _ in
                    if !pressed {
                        pressed = true
                        withAnimation(.easeOut(duration: 0.08)) { showBubble = true }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        pressed = false
                        showBubble = false
                    }
                    action()
                }
        )
    }
}

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
                
                if let label = label {
                    Text(label)
                        .font(.system(size: fontSize))
                        .foregroundColor(style.keyText)
                } else if let systemName = systemName {
                    Image(systemName: systemName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(style.keyText)
                }
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
    }
}

struct SlangKeyboardView: View {
    init(
        insertText: @escaping (String) -> Void,
        deleteText: @escaping () -> Void,
        keyboardHeight: CGFloat,
        backgroundColor: Color,
        needsInputModeSwitchKey: Bool = false,
        nextKeyboardAction: Selector? = nil,
        vm: SlangKeyboardViewModel
    ) {
        self.insertText = insertText
        self.deleteText = deleteText
        self.keyboardHeight = keyboardHeight
        self.backgroundColor = backgroundColor
        self.needsInputModeSwitchKey = needsInputModeSwitchKey
        self.nextKeyboardAction = nextKeyboardAction
        self._vm = ObservedObject(initialValue: vm)
    }
    
    var insertText: (String) -> Void
    var deleteText: () -> Void
    
    let keyboardHeight: CGFloat
    var backgroundColor: Color
    var needsInputModeSwitchKey: Bool = false
    var nextKeyboardAction: Selector? = nil
    
    @ObservedObject var vm: SlangKeyboardViewModel
    
    @Environment(\.colorScheme) private var scheme
    private var style: KeyStyle { KeyStyle(isDark: scheme == .dark) }
    
    var body: some View {
        ZStack {
            if vm.mode == .normal {
                keyboardView(vm: vm)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                explainModeView(vm: vm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.mode)
    }
    
    func explainModeView(vm: SlangKeyboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    vm.changeDisplayMode(.normal)
                }
            } label: {
                Image(systemName: "keyboard")
                    .font(.system(size: 17))
                    .foregroundColor(style.keyText)
                    .frame(width: 34, height: 34)
                    .background(style.popupFill)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.15), radius: 0.5, y: 0.5)
            }
            .padding(.leading, 12)
            .padding(.top, 4)
            
            ZStack {
                if vm.isTranslating {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                        
                        Text("Translating...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(style.keyText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(style.keyboardBackground)
                    .transition(.opacity)
                } else {
                    ScrollView {
                        explainContentView(vm: vm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                    }
                    .transition(.opacity)
                    
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(style.keyboardBackground)
    }
    
    private func explainContentView(vm: SlangKeyboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(vm.getClipboardText())
                .font(.system(.title, design: .serif, weight: .bold))
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            
            Text(vm.translatedText)
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Slang detected (\(vm.detectedSlangs.count))")
                .foregroundColor(scheme == .dark ? .white : .black)
                .font(.system(.body, design: .default, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .padding(.vertical, 14)
            
            if vm.slangText.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.secondary)
                    
                    Text("No slang detected")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeInOut(duration: 0.4), value: vm.slangText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.detectedSlangs, id: \.id) { slang in
                        KeyboardSlangCardView(slangData: slang)
                        Divider()
                            .padding(.horizontal, 10)
                    }
                }
                .padding(.bottom, 10)
            }
            Spacer()
        }
    }
    
    private func keyboardView(vm: SlangKeyboardViewModel) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "document.on.document")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray)
                    .frame(width: 34, height: 34)
                    .background(style.popupFill)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.10), radius: 1, y: 0.5)
                
                Text("Paste your copied slang here")
                    .foregroundStyle(style.labelText)
                    .font(.system(.subheadline, design: .default, weight: .regular))
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(style.keyboardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .onTapGesture {
                Task {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.changeDisplayMode(.explain)
                        vm.isTranslating = true
                    }
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    await vm.translateFromClipboard()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        vm.isTranslating = false
                    }
                }
            }
            
            ForEach(0..<vm.getRows().count, id: \.self) { rowIndex in
                HStack(spacing: 5) {
                    if rowIndex == 2 {
                        let label = vm.showNumbersShifted ? "123"
                        : vm.showNumber ? "#+="
                        : "⇧"
                        
                        PlainKeyButton(label: label, systemName: nil, width: 44, height: 44, fontSize: vm.showNumber ? 14 : 22) {
                            if vm.showNumbersShifted {
                                vm.showNumbersShifted.toggle()
                            } else if vm.showNumber {
                                vm.showNumbersShifted.toggle()
                            } else {
                                vm.toggleShift()
                            }
                        }
                    }
                    
                    ForEach(vm.getRows()[rowIndex], id: \.self) { key in
                        let label = displayLabel(for: key)
                        KeyCapView(label: label, width: (rowIndex == 2 && vm.showNumber) ? 46 : 34, height: 44, fontSize: 22) {
                            insertText(label)
                            if vm.isShifted && !vm.showNumber { vm.isShifted = false }
                        }
                    }
                    
                    if rowIndex == 2 {
                        PlainKeyButton(label: nil, systemName: "delete.left", width: 44, height: 44, fontSize: 18) {
                            deleteText()
                        }
                    }
                }
                .padding(.horizontal, rowIndex == 1 ? 12 : 6)
            }
            
            HStack(spacing: 6) {
                if needsInputModeSwitchKey, let nextKeyboardAction {
                    NextKeyboardButtonOverlay(action: nextKeyboardAction)
                        .frame(width: 40, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(style.keyFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(style.keyStroke, lineWidth: 0.4)
                                )
                                .shadow(color: style.keyShadow, radius: 0.8, y: 0.6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                
                PlainKeyButton(label: vm.showNumber ? "ABC" : "123", systemName: nil, width: 48, height: 44, fontSize: 18) {
                    if vm.showNumber {
                        vm.showNumber.toggle()
                        vm.showNumbersShifted = false
                    } else {
                        vm.showNumber.toggle()
                    }
                }
                
                PlainKeyButton(label: nil, systemName: "face.smiling", width: 48, height: 44, fontSize: 18) {}
                
                PlainKeyButton(label: "space", systemName: nil, width: 150, height: 44, fontSize: 17) {
                    insertText(" ")
                }
                
                PlainKeyButton(label: "return", systemName: nil, width: 76, height: 44, fontSize: 17) {
                    insertText("\n")
                }
            }
            .padding(.horizontal, 6)
        }
        .padding(.vertical, 8)
        .background(
            scheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            VStack(spacing: 0) { Divider().opacity(0.6) }, alignment: .top
        )
        .frame(height: keyboardHeight)
    }
    
    private func displayLabel(for key: String) -> String {
        vm.isShifted ? key.uppercased() : key.lowercased()
    }
    
    struct NextKeyboardButtonOverlay: UIViewRepresentable {
        let action: Selector
        func makeUIView(context: Context) -> UIButton {
            let btn = UIButton(type: .system)
            btn.setImage(UIImage(systemName: "globe"), for: .normal)
            btn.tintColor = .label
            btn.addTarget(nil, action: action, for: .allTouchEvents)
            return btn
        }
        func updateUIView(_ uiView: UIButton, context: Context) {}
    }
}

