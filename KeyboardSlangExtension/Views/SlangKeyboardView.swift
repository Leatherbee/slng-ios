//
//  SlangKeyboardView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 22/10/25.
//

import SwiftUI
import SwiftData
import UIKit
struct SlangKeyboardView: View {
    // MARK: Properties
    let insertText: (String) -> Void
    let deleteText: () -> Void
    let keyboardHeight: CGFloat
    let backgroundColor: Color
    let needsInputModeSwitchKey: Bool
    let nextKeyboardAction: Selector?
    
    @ObservedObject var vm: SlangKeyboardViewModel
    @Environment(\.colorScheme) private var scheme
    
    private var style: KeyStyle { KeyStyle(isDark: scheme == .dark) }
    
    // MARK: Initialization
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
    
    // MARK: Body
    var body: some View {
        ZStack {
            if vm.mode == .normal {
                NormalKeyboardSection(
                    vm: vm,
                    style: style,
                    keyboardHeight: keyboardHeight,
                    needsInputModeSwitchKey: needsInputModeSwitchKey,
                    nextKeyboardAction: nextKeyboardAction,
                    insertText: insertText,
                    deleteText: deleteText
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                ExplainModeSection(vm: vm, style: style)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vm.mode)
    }
}


