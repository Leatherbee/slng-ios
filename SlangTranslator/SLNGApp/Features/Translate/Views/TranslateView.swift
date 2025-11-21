//
//  TranslateView.swift
//  SlangTranslator
//

import SwiftUI
import SwiftData
import AVFoundation
import UIKit

struct TranslateView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @StateObject private var viewModel = TranslateViewModel()
    @Namespace private var textNamespace
    
    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle
    @State private var shouldPlaySequentialAnimation = false
    @State private var hasShownTranslateResult: Bool = false
    @State private var fontSizeWorkItem: DispatchWorkItem?
    @AppStorage("hasRequestedSpeechMic", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var hasRequestedSpeechMic = false
    @AppStorage("reduceMotionEnabled", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var reduceMotionEnabled: Bool = false
    
    @FocusState private var isKeyboardActive: Bool
    
    @State private var showSettings: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var settingsRouter = Router()
    @State private var showDragHint: Bool = false
    @State private var dragHintTimer: Timer?
    
    private let settingsOverlayStart: CGFloat = 800
    private let settingsContentRevealThreshold: CGFloat = 120
    private let settingsOverlayYOffset: CGFloat = -60
    
    private var curtainEase: Animation {
        .timingCurve(0.22, 0.61, 0.36, 1.0, duration: 0.32)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                contentSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .offset(y: showSettings ? UIScreen.main.bounds.height * 0.9 : dragOffset * 0.45)
            .opacity(showSettings ? 0 : (1 - min(1.0, dragOffset / 420.0)))
            .animation(curtainEase, value: showSettings)
            .background(hasShownTranslateResult ? AppColor.Background.secondary : AppColor.Background.primary)
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 20)
                        .frame(width: 40, height: 4)
                        .foregroundStyle(AppColor.Button.primary)
                        .offset(y: showDragHint ? 6 : 0)
                        .scaleEffect(showDragHint ? 1.1 : 1.0)
                        .animation((reduceMotion || reduceMotionEnabled) ? nil : .spring(response: 0.55, dampingFraction: 0.7), value: showDragHint)
                    
                    Text("Settings")
                        .font(.system(.footnote, design: .default, weight: .bold))
                        .foregroundStyle(.secondary)
                        .opacity(showDragHint ? 0.9 : 1)
                        .offset(y: showDragHint ? 6 : 0)
                        .scaleEffect(showDragHint ? 0.9 : 1.0)
                        .animation((reduceMotion || reduceMotionEnabled) ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: showDragHint)
                }
                .allowsHitTesting(false)
                .offset(
                    y: showSettings
                        ? UIScreen.main.bounds.height - 60
                        : dragOffset * 1.05
                )
                .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.85), value: dragOffset)
            }
                        
            if (showSettings || dragOffset > 0) && !(viewModel.isRecording || viewModel.isTranscribing) {
                ZStack {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            Color.backgroundSecondary
                                .frame(
                                    height: showSettings
                                    ? geo.size.height
                                    : dragOffset * 1.05 + safeTop - 16
                                )
                            
                            Spacer()
                        }
                        .ignoresSafeArea()
                        .animation(.interactiveSpring(response: 0.28, dampingFraction: 0.85),
                                   value: dragOffset)
                    }
                    
                    RouterStack(router: settingsRouter) {
                        SettingsView(showSettings: $showSettings)
                    }
                    .transition(.move(edge: .top))
                    .offset(
                        y: showSettings
                        ? 0
                        : max(-settingsOverlayStart + dragOffset * 1.1,
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
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    guard !isKeyboardActive else { return }
                    guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
                    let raw = value.translation.height
                    if raw > 0 {
                        dragOffset = softened(raw)
                    }
                }
                .onEnded { value in
                    guard !isKeyboardActive else {
                        UIApplication.shared.dismissKeyboard()
                        return
                    }
                    guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
                    let passed = value.translation.height > 120.0
                    
                    if passed {
                        withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.78)) {
                            dragOffset = 240
                        }
                        withAnimation(curtainEase.delay(0.05)) {
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
            if dragHintTimer == nil {
                dragHintTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                    triggerDragHint()
                }
            }
        }
        .onDisappear {
            dragHintTimer?.invalidate()
            dragHintTimer = nil
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
                isKeyboardActive: $isKeyboardActive,
                shouldPlaySequentialAnimation: $shouldPlaySequentialAnimation,
                dynamicTextStyle: $dynamicTextStyle,
                dragOffset: dragOffset
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
                dynamicTextStyle: $dynamicTextStyle,
                dragOffset: dragOffset
            )
            .background(Color.backgroundSecondary)
            .onAppear {
                hasShownTranslateResult = true
            }
        }
    }
    
    var safeTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.safeAreaInsets.top ?? 60
    }
    
    private func softened(_ t: CGFloat) -> CGFloat {
        let v = max(0, t)
        return pow(v, 0.82)
    }
    
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

    private func triggerDragHint() {
        guard !showSettings else { return }
        guard !(viewModel.isRecording || viewModel.isTranscribing) else { return }
        guard !(reduceMotion || reduceMotionEnabled) else { return }
        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7)) {
            showDragHint = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.7)) {
                showDragHint = false
            }
        }
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
        sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

