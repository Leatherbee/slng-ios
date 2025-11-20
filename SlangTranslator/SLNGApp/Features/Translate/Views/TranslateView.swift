//
//  TranslateView.swift
//  SlangTranslator
//

import SwiftUI
import SwiftData
import AVFoundation

struct TranslateView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = TranslateViewModel()
    @Namespace private var textNamespace
    
    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle
    @State private var shouldPlaySequentialAnimation = false
    @State private var hasShownTranslateResult: Bool = false
    @State private var fontSizeWorkItem: DispatchWorkItem?
    @AppStorage("hasRequestedSpeechMic", store: UserDefaults.shared) private var hasRequestedSpeechMic = false
    
    @State private var showSettings: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    private let settingsOverlayStart: CGFloat = 800
    private let settingsContentRevealThreshold: CGFloat = 120
    private let settingsOverlayYOffset: CGFloat = -60
    
    // MARK: - Magic sauce: Apple-style easing
    private var curtainEase: Animation {
        .timingCurve(0.22, 0.61, 0.36, 1.0, duration: 0.32)
    }
    
    var body: some View {
        ZStack {
            contentSection
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: showSettings ? 55.0 : dragOffset * 0.12)
                .opacity(showSettings ? 0 : (1 - min(1.0, dragOffset / 220.0)))
                .animation(curtainEase, value: showSettings)

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 20)
                    .frame(width: 40, height: 4)
                    .foregroundStyle(AppColor.Button.primary)
                
                Text("Settings")
                    .font(.system(.footnote, design: .default, weight: .bold))
                    .foregroundStyle(.secondary)
                    .opacity((showSettings || dragOffset > 0) ? 0 : 1)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
                        
            if (showSettings || dragOffset > 0) && !(viewModel.isRecording || viewModel.isTranscribing) {
                ZStack {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            // Dynamic curtain height
                            Color.backgroundSecondary
                                .frame(
                                    height: showSettings
                                    ? geo.size.height
                                    : dragOffset * 1.05 + 80
                                )
                            
                            Spacer()
                        }
                        .ignoresSafeArea()
                        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.85),
                                   value: dragOffset)
                    }
                    
                    NavigationStack {
                        SettingsView(showSettings: $showSettings)
                    }
                    .transition(.move(edge: .top))
                    .offset(
                        y: showSettings
                        ? 0
                        : max(-settingsOverlayStart + dragOffset * 0.85,
                              -settingsOverlayStart)
                    )
                    .opacity(
                        showSettings
                        ? 1
                        : (
                            dragOffset > settingsContentRevealThreshold
                            ? min(1.0,
                                  (dragOffset - settingsContentRevealThreshold) / 90.0)
                            : 0
                        )
                    )
                    .animation(curtainEase, value: showSettings)
                }
                .zIndex(1)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
                    let raw = value.translation.height
                    if raw > 0 {
                        dragOffset = softened(raw)
                    }
                }
                .onEnded { value in
                    guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
                    let passed = value.translation.height > 120.0
                    
                    if passed {
                        withAnimation(.interactiveSpring(response: 0.26, dampingFraction: 0.88)) {
                            dragOffset = 140
                        }
                        withAnimation(curtainEase.delay(0.02)) {
                            showSettings = true
                        }
                    } else {
                        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.82)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        
        .animation(.easeInOut(duration: 0.25), value: viewModel.isTranslated)
        .onAppear {
            if !hasRequestedSpeechMic {
                viewModel.prewarmPermissions()
                hasRequestedSpeechMic = true
            }
        }
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing {
                withAnimation(.interactiveSpring(response: 0.32,
                                                 dampingFraction: 0.82)) {
                    dragOffset = 0
                }
            }
        }
        .onChange(of: viewModel.isRecording) { _, isRec in
            if isRec {
                dragOffset = 0
            }
        }
        .onChange(of: viewModel.isTranscribing) { _, isTr in
            if isTr {
                dragOffset = 0
            }
        }
    }
    
    @ViewBuilder
    var contentSection: some View {
        if viewModel.isInitializing {
            VStack(spacing: 12) {
                ProgressView("Preparing translator...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .font(.headline)
                
                Text("Warming up dictionary & translation engine…")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.1))
            
        } else if viewModel.isLoading && !viewModel.isTranscribing {
            TranslateLoadingSection(
                viewModel: viewModel,
                textNamespace: textNamespace,
                dynamicTextStyle: dynamicTextStyle
            )
            
        } else if !viewModel.isTranslated {
            TranslateInputSection(
                viewModel: viewModel,
                textNamespace: textNamespace,
                adjustFontSizeDebounced: adjustFontSizeDebounced,
                shouldPlaySequentialAnimation: $shouldPlaySequentialAnimation,
                dynamicTextStyle: $dynamicTextStyle
            )
            .background(Color.backgroundPrimary)
            .onAppear {
                hasShownTranslateResult = false
            }
            
        } else {
            TranslateResultSection(
                viewModel: viewModel,
                textNamespace: textNamespace,
                adjustFontSizeDebounced: adjustFontSizeDebounced,
                shouldPlaySequentialAnimation: $shouldPlaySequentialAnimation,
                dynamicTextStyle: $dynamicTextStyle
            )
            .background(Color.backgroundSecondary)
            .onAppear {
                hasShownTranslateResult = true
            }
        }
    }
    
    // MARK: - Drag Smoothing
    private func softened(_ t: CGFloat) -> CGFloat {
        let v = max(0, t)
        return pow(v, 0.82)   // smoothest curve
    }
    
    // MARK: - Debounced Font
    private func adjustFontSizeDebounced() {
        fontSizeWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            let length = viewModel.inputText.count
            let newStyle: Font.TextStyle = {
                switch length {
                case 0...40: return .largeTitle
                case 41...100: return .title
                case 101...200: return .title2
                case 201...340: return .title3
                default: return .headline
                }
            }()
            
            if newStyle != dynamicTextStyle {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dynamicTextStyle = newStyle
                }
            }
        }
        
        fontSizeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
}

struct BlinkingCursor: View {
    @State private var isVisible: Bool = true
    
    var body: some View {
        Text("|")
            .font(.system(size: 46, weight: .regular, design: .serif))
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                       value: isVisible)
            .onAppear { isVisible.toggle() }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil,
                   from: nil,
                   for: nil)
    }
}

