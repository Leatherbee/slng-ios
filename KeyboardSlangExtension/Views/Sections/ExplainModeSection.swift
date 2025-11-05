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
                    ScrollView {
                        ExplainContentView(vm: vm, style: style)
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

struct ExplainContentView: View {
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            originalTextSection
            Divider()
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            translatedTextSection
            slangCountHeader
            slangListOrEmptyState
            Spacer()
        }
    }
    
    private var originalTextSection: some View {
        Text(vm.getClipboardText())
            .font(.system(.title, design: .serif, weight: .bold))
            .lineLimit(4)
            .minimumScaleFactor(0.6)
            .allowsTightening(true)
            .multilineTextAlignment(.leading)
            .foregroundStyle(.primary)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var translatedTextSection: some View {
        Text(vm.translatedText)
            .font(.system(.title, design: .serif, weight: .bold))
            .foregroundStyle(.secondary)
            .lineLimit(4)
            .minimumScaleFactor(0.6)
            .allowsTightening(true)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var slangCountHeader: some View {
        Text("Slang detected (\(vm.detectedSlangs.count))")
            .foregroundColor(scheme == .dark ? .white : .black)
            .font(.system(.body, design: .default, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
            .padding(.vertical, 14)
    }
    
    @ViewBuilder
    private var slangListOrEmptyState: some View {
        if vm.detectedSlangs.isEmpty {
            emptySlangState
        } else {
            slangList
        }
    }
    
    private var emptySlangState: some View {
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
    }
    
    private var slangList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(vm.detectedSlangs, id: \.id) { slang in
                KeyboardSlangCardView(slangData: slang)
                Divider()
                    .padding(.horizontal, 10)
            }
        }
        .padding(.bottom, 10)
    }
}
