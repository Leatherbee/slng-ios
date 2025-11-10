//
//  TranslateResultSection.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 05/11/25.
//

import SwiftUI
import AVFoundation

struct TranslateResultSection: View {
    @ObservedObject var viewModel: TranslateViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var textNamespace: Namespace.ID
    var adjustFontSizeDebounced: () -> Void
    
    @Binding var shouldPlaySequentialAnimation: Bool
    @Binding var dynamicTextStyle: Font.TextStyle
    
    @State private var alignToInputPosition: Bool = true
    @State private var textHeight: CGFloat = 0
    @State private var showExpanded = false
    @State private var stage: Int = 0
    @State private var showBurst = false
    @State private var showPulse = false
    @State private var dividerProgress: CGFloat = 0
    @State private var showTranslated = false
    @State private var showDetectedSlangButton = false
    @State private var showDetectedSlang = false
    @State private var showBottomUI = false
    @State private var moveUp: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.backgroundSecondary.ignoresSafeArea()
                
                GeometryReader { screenGeo in
                    SunburstView(trigger: $showBurst)
                        .allowsHitTesting(false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .position(x: screenGeo.size.width / 2,
                                  y: screenGeo.size.height / 2 - 150)
                }
                .zIndex(2)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer().frame(height: alignToInputPosition ? 150 : 100)
                        
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                
                                // Original text (pulse only)
                                Text(viewModel.inputText)
                                    .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .matchedGeometryEffect(
                                        id: "originalText",
                                        in: textNamespace,
                                        properties: .frame,
                                        anchor: .topLeading
                                    )
                                    .scaleEffect(showPulse ? 0.80 : 1.0)
                                    .offset(y: moveUp ? -textHeight * 0.2 : 0)
                                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: showPulse)
                                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: moveUp)
                                    .textSelection(.enabled)
                                    .onTapGesture {
                                        viewModel.editText(text: viewModel.inputText)
                                    }
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                
                                // Divider
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.stroke)
                                        .frame(width: geo.size.width * dividerProgress, height: 0.8)
                                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                        .animation(reduceMotion ? nil : .easeOut(duration: 0.6), value: dividerProgress)
                                }
                                .frame(height: 1)
                                
                                // Translated text
                                if let translatedText = viewModel.translatedText {
                                    Text(translatedText)
                                        .font(.system(dynamicTextStyle, design: .serif, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .opacity(showTranslated ? 1 : 0)
                                        .scaleEffect(y: showTranslated ? 1.0 : 0.8, anchor: .top)
                                        .offset(y: showTranslated ? 0 : -10)
                                        .clipped(antialiased: true)
                                        .mask(
                                            Rectangle()
                                                .frame(height: showTranslated ? 2000 : 0)
                                                .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: showTranslated)
                                        )
                                        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8), value: showTranslated)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Buttons
                        if showDetectedSlangButton {
                            if viewModel.slangDetected.isEmpty {
                                HStack(spacing: 10) {
                                    Button {
                                        viewModel.expandedView()
                                        showExpanded = true
                                    } label: {
                                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    }
                                    .accessibilityLabel("Expand translation")
                                    .accessibilityHint("Open fullscreen translation view")
                                    
                                    Button { viewModel.copyToClipboard() } label: {
                                        Image(systemName: "doc.on.doc")
                                    }
                                    .accessibilityLabel("Copy translation")
                                    .accessibilityHint("Copy translated text to clipboard")
                                }
                                .padding(.horizontal, 32)
                                
                                VStack {
                                    Spacer()
                                    Image(systemName: "questionmark.circle")
                                        .resizable()
                                        .frame(width: 42, height: 42)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("No slang detected")
                                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .padding(.bottom, 120)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: viewModel.slangDetected)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                HStack {
                                    HStack(spacing: 10) {
                                        Button {
                                            viewModel.expandedView()
                                            showExpanded = true
                                        } label: {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        }
                                        .accessibilityLabel("Expand translation")
                                        .accessibilityHint("Open fullscreen translation view")
                                        
                                        Button { viewModel.copyToClipboard() } label: {
                                            Image(systemName: "doc.on.doc")
                                        }
                                        .accessibilityLabel("Copy translation")
                                        .accessibilityHint("Copy translated text to clipboard")
                                    }
                                    Spacer()
                                    Button {
                                        viewModel.showDetectedSlang()
                                    } label: {
                                        Text(viewModel.isDetectedSlangShown
                                             ? "Close Detected Slang (\(viewModel.slangDetected.count))"
                                             : "Show Detected Slang (\(viewModel.slangDetected.count))")
                                        .padding(.vertical, 16)
                                        .padding(.horizontal, 16)
                                        .foregroundColor(colorScheme == .dark ? .black : .white)
                                        .background(AppColor.Button.primary)
                                        .clipShape(Capsule())
                                    }
                                    .accessibilityLabel(viewModel.isDetectedSlangShown ? "Close detected slang" : "Show detected slang")
                                    .accessibilityHint("Toggle the detected slang list")
                                }
                                .padding(.horizontal, 32)
                            }
                        }
                        
                        // Detected slang
                        if viewModel.isDetectedSlangShown {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Slang Detected (\(viewModel.slangDetected.count))")
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 14) {
                                    ForEach(viewModel.slangData, id: \.slang) { slangData in
                                        TranslateSlangCardView(
                                            slangData: slangData,
                                            backgroundColor: AppColor.Background.secondary
                                        )
                                        .opacity(showDetectedSlang ? 1 : 0)
                                        .animation(
                                            reduceMotion ? nil : .easeInOut(duration: 0.6)
                                            .delay(Double(viewModel.slangData.firstIndex(where: { $0.slang == slangData.slang }) ?? 0) * 0.05),
                                            value: showDetectedSlang
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                            .onAppear { showDetectedSlang = true }
                            .onDisappear { showDetectedSlang = false }
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .tint(Color.textPrimary)
                    .alert("Copied!", isPresented: $viewModel.copiedToKeyboardAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("The translated text has been copied to the clipboard.")
                    }
                    .fullScreenCover(isPresented: $showExpanded) {
                        ExpandedTranslationView(text: viewModel.translatedText ?? "", onClose: { showExpanded = false })
                            .toolbar(.hidden, for: .tabBar)
                    }
                    .padding(.top, 1)
                }
                .safeAreaPadding(.top)
                .scrollIndicators(.hidden)
                
                Button {
                    viewModel.reset()
                    resetAnimation()
                } label: {
                    Label("Try Another", systemImage: "arrow.left")
                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: 314, minHeight: 60)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(
                            AppColor.Button.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .accessibilityLabel("Try another translation")
                .accessibilityHint("Go back to input to translate another text")
                .padding(.bottom, 16)
                .opacity(showBottomUI ? 1 : 0)
                .animation(reduceMotion ? nil : .easeIn(duration: 0.5), value: showBottomUI)
            }
            .onAppear {
                if shouldPlaySequentialAnimation {
                    if reduceMotion {
                        stage = 1
                        triggerBurstHaptic()
                        showBurst = true
                        showPulse = false
                        dividerProgress = 1.0
                        showTranslated = true
                        showDetectedSlangButton = true
                        showBottomUI = true
                        alignToInputPosition = false
                        moveUp = true
                    } else {
                        playSequentialAnimation()
                    }
                    shouldPlaySequentialAnimation = false
                }
            }
            .toolbar(showBottomUI ? .visible : .hidden, for: .tabBar)
        }
    }
    
    // MARK: Animation Logic
    private func resetAnimation() {
        stage = 0
        showBurst = false
        showPulse = false
        dividerProgress = 0
        showTranslated = false
        showDetectedSlangButton = false
        showDetectedSlang = false
        alignToInputPosition = true
        showBottomUI = false
    }
    
    private func playSequentialAnimation() {
        stage = 1
        showBurst = true
        triggerBurstHaptic()
        
        // Stage 1: Mulai burst dan pulse bersamaan
        withAnimation(.easeInOut(duration: 0.2)) {
            showPulse = true
        }
        
        // Stage 2: Burst & pulse selesai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                showBurst = false
            }
            withAnimation(.easeInOut(duration: 0.08)) {
                showPulse = false
            }
            
            // Stage 3: Teks naik setelah burst & pulse selesai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    alignToInputPosition = false
                    moveUp = true
                }
                
                // Stage 4: Divider muncul
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        dividerProgress = 1.0
                    }
                    
                    // Stage 5: Translated text
                    // di playSequentialAnimation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                            showTranslated = true
                        }
                        
                        // Stage 6: Detected slang button
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeIn(duration: 0.25)) {
                                showDetectedSlangButton = true
                            }
                            
                            // Stage 7: Bottom UI
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    showBottomUI = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func playBurstSound() {
        guard let url = Bundle.main.url(forResource: "whoosh", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.9
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            fatalError()
        }
    }
    
    func triggerBurstHaptic() {
        playBurstSound()
        
        HapticManager.shared.playExplosionHaptic()
    }
}
