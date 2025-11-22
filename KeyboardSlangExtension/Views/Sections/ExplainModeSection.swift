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
    @Namespace private var textNamespace
    @State private var dynamicTextStyle: Font.TextStyle = .title
    @State private var showTranslated: Bool = false
    
    @Environment(\.colorScheme) private var scheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            backToKeyboardButton
            
            ZStack {
                if vm.isTranslating {
                    loadingView
                } else if vm.getClipboardText().isEmpty {
                    emptyClipboardView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        ExplainContentView(vm: vm, style: style, textNamespace: textNamespace, showTranslated: showTranslated)
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
        .onAppear {
            let length = vm.getClipboardText().count
            switch length {
            case 0...40: dynamicTextStyle = .largeTitle
            case 41...100: dynamicTextStyle = .title
            case 101...200: dynamicTextStyle = .title2
            case 201...340: dynamicTextStyle = .title3
            default: dynamicTextStyle = .headline
            }
        }
        .onChange(of: vm.translatedText) { _, newText in
            guard !newText.isEmpty else {
                showTranslated = false
                return
            }
            
            showTranslated = true
        }
        .onChange(of: vm.isTranslating) { _, translating in
            if translating {
                showTranslated = false
            }
        }
    }
    
    private var backToKeyboardButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                vm.changeDisplayMode(.normal)
            }
            let defaults = UserDefaults(suiteName: "group.prammmoe.SLNG")!
            let key = "analytics.feature_used.normal_mode.count"
            defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
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
        KeyboardTranslateLoadingSection(
            textNamespace: textNamespace,
            dynamicTextStyle: dynamicTextStyle,
            style: style
        )
    }

    private var emptyClipboardView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundStyle(.secondary)

            Text("No clipboard detected")
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Copy some text, paste, and it will appear here.")
                .font(.system(.footnote))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(style.keyboardBackground)
        .transition(.opacity)
    }
}


struct ExplainContentView: View {
    @ObservedObject var vm: SlangKeyboardViewModel
    let style: KeyStyle
    var textNamespace: Namespace.ID
    var showTranslated: Bool
    
    @Environment(\.colorScheme) private var scheme
    
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
            .matchedGeometryEffect(
                id: "originalText",
                in: textNamespace,
                properties: .position,
                anchor: .topLeading,
                isSource: true
            )
    }
        
    private var translatedTextSection: some View {
        let text = vm.translatedText
        return Text(text)
            .font(dynamicFont(for: text, baseSize: 20))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6)
            .padding(.bottom, 8)
            .opacity(showTranslated ? 1 : 0)
    }
        
    private var slangCountHeader: some View {
        Text("Slang detected (\(vm.detectedSlangs.count))")
            .foregroundColor(scheme == .dark ? .white : .black)
            .font(.system(.body, design: .default, weight: .regular))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
            .padding(.vertical, 8)
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

struct KeyboardTranslateLoadingSection: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("reduceMotionEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var reduceMotionEnabled: Bool = false
    var textNamespace: Namespace.ID
    var dynamicTextStyle: Font.TextStyle
    let style: KeyStyle
    @State private var currentMessage: String = ""
    @State private var dotCount: Int = 0
    @State private var timer: Timer?
    private let loadingMessages = [
        "Decoding what your slang really means",
        "Analyzing tone, context, and chaos",
        "Catching the real vibe behind your words",
        "Checking emotional damage levels",
        "Consulting the slang gods",
        "Making sense of this linguistic rollercoaster",
        "Translating chaos into meaning",
        "Detecting hidden sarcasm layers",
        "Running a full vibe analysis",
        "Reconstructing your emotional sentence structure",
        "Dissecting the energy behind that slang",
        "Searching the archives of Gen Z dictionary",
        "Cross-checking with Jakarta street linguistics",
        "Comparing with online war archives",
        "Still processing your linguistic masterpiece",
        "Wait—was that supposed to be friendly?",
        "Our translator just went 😵‍💫",
        "Slang so strong, even our AI is sweating",
        "Loading context… like your friend’s late reply",
        "Consulting urban dictionary and praying",
        "Running a vibe check on your sentence",
        "Checking how offended we should be",
        "The slang AI needs a breather",
        "Hold tight, decoding your chaos in 4K",
        "Making sure it’s not just capslock rage",
        "Rebooting brain cells...",
        "Polishing your words till they shine",
        "Verifying if that’s sarcasm or trauma",
        "Syncing with millennial emotions",
        "Assembling emotional context packets",
        "Extracting hidden meaning behind emojis",
        "Asking linguists for a second opinion",
        "Debugging cultural nuances",
        "Performing semantic autopsy",
        "Untangling your sentence spaghetti",
        "Almost got it",
        "Hold my bahasa",
        "Decoding on vibes only",
        "Finding meaning in the chaos",
        "Loading the dictionary of emotions",
        "Reconstructing what you *really* meant",
        "Translating the untranslatable",
        "Updating slang database v2.0",
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(currentMessage)\(String(repeating: ".", count: dotCount))")
                .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                .foregroundStyle(.secondary)
                .matchedGeometryEffect(
                    id: "originalText",
                    in: textNamespace,
                    properties: .position,
                    anchor: .topLeading,
                    isSource: false
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.horizontal)
                .padding(.top)
                .scaleEffect(1.02)
                .animation(.interpolatingSpring(stiffness: 180, damping: 12), value: currentMessage)
                .animation(.interpolatingSpring(stiffness: 150, damping: 14), value: dotCount)
        }
        .onAppear { startLoopingAnimation() }
        .onDisappear { timer?.invalidate() }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(style.keyboardBackground)
        .transition(.opacity)
    }
    private func startLoopingAnimation() {
        var availableMessages = loadingMessages.shuffled()
        currentMessage = availableMessages.popLast() ?? "Loading..."
        var tickCounter = 0
        if !(reduceMotion || reduceMotionEnabled) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation(.interpolatingSpring(stiffness: 150, damping: 14)) {
                    dotCount = (dotCount + 1) % 4
                }
                tickCounter += 1
                let randomThreshold = Int.random(in: 3...5)
                if tickCounter >= randomThreshold {
                    tickCounter = 0
                    if availableMessages.isEmpty {
                        availableMessages = loadingMessages.shuffled()
                    }
                    withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
                        currentMessage = availableMessages.popLast() ?? currentMessage
                    }
                }
            }
        } else {
            currentMessage = "\(availableMessages.popLast() ?? "Loading")..."
        }
    }
}
