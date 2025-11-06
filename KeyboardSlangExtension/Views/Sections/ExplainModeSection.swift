//
//  ExplainModeSection.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 05/11/25.
//

import SwiftUI
import UIKit

struct ExplainModeSection: View {
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            backToKeyboardButton
            
            ZStack {
                if vm.isTranslating {
                    loadingView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        ExplainContentView(vm: vm, style: style)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(style.keyboardBackground)
    }
    
    private var backToKeyboardButton: some View {
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
    }
    
    private var loadingView: some View {
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
    }
}

// MARK: - Explain Content

struct ExplainContentView: View {
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    
    @Environment(\.colorScheme) private var scheme
    
    // MARK: Dynamic Font Scaling
    private func dynamicFont(for text: String, baseSize: CGFloat = 22) -> Font {
        let length = text.count
        switch length {
        case 0..<50:
            return .system(size: baseSize + 4, weight: .bold, design: .serif)
        case 50..<100:
            return .system(size: baseSize + 2, weight: .bold, design: .serif)
        case 100..<200:
            return .system(size: baseSize, weight: .bold, design: .serif)
        case 200..<400:
            return .system(size: baseSize - 2, weight: .bold, design: .serif)
        default:
            return .system(size: baseSize - 4, weight: .bold, design: .serif)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            originalTextSection
            Divider()
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            translatedTextSection
            slangCountHeader
            slangListOrEmptyState
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: Original Text
    
    private var originalTextSection: some View {
        let text = vm.getClipboardText()
        return Text(text)
            .font(dynamicFont(for: text))
            .multilineTextAlignment(.leading)
            .foregroundStyle(.primary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
    }
    
    // MARK: Translated Text
    
    private var translatedTextSection: some View {
        let text = vm.translatedText
        return Group {
            if text.isEmpty {
                Text("No translation available")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
            } else {
                Text(text)
                    .font(dynamicFont(for: text, baseSize: 20))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: Slang Count
    
    private var slangCountHeader: some View {
        Text("Slang detected (\(vm.detectedSlangs.count))")
            .foregroundColor(scheme == .dark ? .white : .black)
            .font(.system(.body, design: .default, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
            .padding(.vertical, 8)
    }
    
    // MARK: Slang List or Empty
    
    @ViewBuilder
    private var slangListOrEmptyState: some View {
        if vm.detectedSlangs.isEmpty {
            emptySlangState
        } else {
            slangList
        }
    }
    
    private var emptySlangState: some View {
        VStack(spacing: 10) {
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.secondary)
            
            Text("No slang detected")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private var slangList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(vm.detectedSlangs, id: \.id) { slang in
                KeyboardSlangCardView(slangData: slang)
                Divider()
                    .padding(.horizontal, 10)
            }
        }
        .padding(.bottom, 10)
    }
}
