//
//  ShareExtensionView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import SwiftData

struct ShareExtensionView: View {
    let sharedText: String
    let onDismiss: () -> Void
    @ObservedObject var viewModel: ShareTranslateViewModel
    @Namespace private var textNamespace
    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle
    
    
    @State private var detectedSlangs: [SlangData] = []
    @State private var translatedText: String = ""
    @State private var translationError: String?
    
    // Dynamic font size based on text length
    private func dynamicFontSize(for text: String) -> Font {
        let length = text.count
        if length < 50 {
            return .system(.largeTitle, design: .serif, weight: .bold)
        } else if length < 100 {
            return .system(.title, design: .serif, weight: .bold)
        } else if length < 200 {
            return .system(.title2, design: .serif, weight: .bold)
        } else {
            return .system(.title3, design: .serif, weight: .bold)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if !viewModel.isLoading {
                        Text(sharedText)
                            .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                            .padding(.top)
                            .matchedGeometryEffect(
                                id: "originalText",
                                in: textNamespace,
                                properties: .position,
                                anchor: .topLeading,
                                isSource: true
                            )
                    }
                    
                    if viewModel.isLoading {
                        ShareTranslateLoadingSection(
                            textNamespace: textNamespace,
                            dynamicTextStyle: dynamicTextStyle
                        )
                    }
                    
                    else if let error = translationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(error)
                                .foregroundColor(.red)
                                .padding(0.4)
                        }
                        .padding()
                    }
                    
                    else if !translatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                                .frame(height: 1)
                                .overlay(AppColor.Stroke.color)
                                .padding(.horizontal)
                            
                            Text(translatedText)
                                .font(dynamicFontSize(for: translatedText))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            if !detectedSlangs.isEmpty {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Slang Detected (\(detectedSlangs.count))")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    ForEach(detectedSlangs.indices, id: \.self) { index in
                                        TranslateSlangCardView(
                                            slangData: detectedSlangs[index],
                                            backgroundColor: .clear
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .textSelection(.enabled)
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.gray)
                                    Text("No slang detected")
                                        .font(.system(.headline, design: .serif, weight: .regular))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding()
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollIndicators(.visible)
        }
        .onAppear {
            Task {
                viewModel.inputText = sharedText
                await viewModel.translate()
                
                if let result = viewModel.result {
                    translatedText = result.translation.englishTranslation
                    detectedSlangs = result.detectedSlangs
                }
                
                if let vmError = viewModel.errorMessage, !vmError.isEmpty {
                    translationError = vmError
                }
            }
            dynamicTextStyle = {
                let length = sharedText.count
                switch length {
                case 0...40: return .largeTitle
                case 41...100: return .title
                case 101...200: return .title2
                case 201...340: return .title3
                default: return .headline
                }
            }()
        }
    }
}

struct ShareTranslateLoadingSection: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("reduceMotionEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var reduceMotionEnabled: Bool = false
    var textNamespace: Namespace.ID
    var dynamicTextStyle: Font.TextStyle
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
        .toolbar(.hidden, for: .tabBar)
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

