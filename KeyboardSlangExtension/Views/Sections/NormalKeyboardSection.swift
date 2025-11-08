//
//  NormalKeyboardSection.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 05/11/25.
//

import SwiftUI
import UIKit

struct NormalKeyboardSection: View {
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    let keyboardHeight: CGFloat
    let needsInputModeSwitchKey: Bool
    let nextKeyboardAction: Selector?
    let insertText: (String) -> Void
    let deleteText: () -> Void
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(spacing: 10) {
            pasteSlangPrompt
            keyRows
            bottomRow
        }
        .padding(.vertical, 8)
        .background(style.keyboardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(VStack(spacing: 0) { Divider().opacity(0.6) }, alignment: .top)
        .frame(height: keyboardHeight)
        .animation(nil, value: vm.showNumber)
    }
    
    private var pasteSlangPrompt: some View {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(style.keyboardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onTapGesture {
            handlePasteAction()
        }
    }
    
    private var keyRows: some View {
        ForEach(0..<vm.getRows().count, id: \.self) { rowIndex in
            KeyRowView(
                rowIndex: rowIndex,
                vm: vm,
                style: style,
                insertText: insertText,
                deleteText: deleteText
            )
        }
    }
    
    private var bottomRow: some View {
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
            
            PlainKeyButton(
                label: vm.showNumber ? "ABC" : "123",
                systemName: nil,
                width: 48,
                height: 44,
                fontSize: 18
            ) {
                withTransaction(Transaction(animation: nil)) {
                    vm.showNumber.toggle()
                    if !vm.showNumber { vm.showNumbersShifted = false }
                }
            }
            
            PlainKeyButton(label: nil, systemName: "face.smiling", width: 48, height: 44, fontSize: 18) {
                vm.changeDisplayMode(.emoji)
            }
            PlainKeyButton(label: "space", systemName: nil, width: 150, height: 44, fontSize: 17) { insertText(" ") }
            PlainKeyButton(label: "return", systemName: nil, width: 76, height: 44, fontSize: 17) { insertText("\n") }
        }
        .padding(.horizontal, 12)
    }
    
    private func handlePasteAction() {
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
}

// MARK: - Key Row View

struct KeyRowView: View {
    let rowIndex: Int
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    let insertText: (String) -> Void
    let deleteText: () -> Void
    
    var body: some View {
        HStack(spacing: 5) {
            if rowIndex == 2 {
                leftModifierKey
            }
            
            ForEach(vm.getRows()[rowIndex], id: \.self) { key in
                let label = displayLabel(for: key)
                KeyCapView(
                    label: label,
                    width: keyWidth(for: rowIndex),
                    height: 44,
                    fontSize: 22
                ) {
                    insertText(label)
                    if vm.isShifted && !vm.showNumber && !vm.isCapsLockOn { vm.isShifted = false }
                }
            }
            
            if rowIndex == 2 {
                PlainKeyButton(
                    label: nil,
                    systemName: "delete.left",
                    width: 44,
                    height: 44,
                    fontSize: 18
                ) {
                    deleteText()
                }
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var leftModifierKey: some View {
        let label = vm.showNumbersShifted ? "123" : vm.showNumber ? "#+=" : (vm.isCapsLockOn ? "⇪" : "⇧")

        return PlainKeyButton(
            label: label,
            systemName: nil,
            width: 44,
            height: 44,
            fontSize: vm.showNumber ? 14 : 22
        ) {
            // Disable animations when toggling symbol/shift state
            withTransaction(Transaction(animation: nil)) {
                if vm.showNumbersShifted || vm.showNumber {
                    vm.showNumbersShifted.toggle()
                } else {
                    vm.toggleShift()
                }
            }
        }
        .highPriorityGesture(TapGesture(count: 2).onEnded {
            // Also disable animations for caps lock toggle
            withTransaction(Transaction(animation: nil)) {
                if !(vm.showNumbersShifted || vm.showNumber) {
                    vm.setCapsLock(on: !vm.isCapsLockOn)
                }
            }
        })
    }
    
    private func keyWidth(for rowIndex: Int) -> CGFloat {
        (rowIndex == 2 && vm.showNumber) ? 46 : 34
    }
    
    private func displayLabel(for key: String) -> String {
        (vm.isShifted || vm.isCapsLockOn) ? key.uppercased() : key.lowercased()
    }
}

// MARK: - UIKit Bridge

struct NextKeyboardButtonOverlay: UIViewRepresentable {
    let action: Selector
    
    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = .label
        button.addTarget(nil, action: action, for: .allTouchEvents)
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {}
}
