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
    @AppStorage("hasRequestedSpeechMic", store: UserDefaults.shared) private var hasRequestedSpeechMic = false
    @AppStorage("reduceMotionEnabled", store: UserDefaults.shared) private var reduceMotionEnabled: Bool = false
    
    @FocusState private var isKeyboardActive: Bool
    
    @State private var showSettings: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var settingsRouter = Router()
    @State private var showDragHint: Bool = false
    @State private var dragHintTimer: Timer?
    @State private var resultScrollOffset: CGFloat = 0
    @State private var isDragPressed: Bool = false
    @State private var isDragHandleReady: Bool = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isDragHandleVisible: Bool = true
    @State private var resultContentTopY: CGFloat = 0
    
    private let settingsOverlayStart: CGFloat = 800
    private let settingsContentRevealThreshold: CGFloat = 120
    private let settingsOverlayYOffset: CGFloat = -60
    
    private var curtainEase: Animation {
        .timingCurve(0.22, 0.61, 0.36, 1.0, duration: 0.55)
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
            .background(viewModel.isTranslated ? AppColor.Background.secondary : AppColor.Background.primary)
            .overlay(alignment: .top) {
                if !viewModel.isLoading && isDragHandleReady && isDragHandleVisible {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: 40, height: 4)
                            .foregroundStyle(AppColor.Button.primary)
                            .offset(y: showDragHint ? 6 : 0)
                            .scaleEffect(showDragHint ? 1.1 : 1.0)
                            .scaleEffect(isDragPressed ? 1.08 : 1.0)
                            .animation(
                                (reduceMotion || reduceMotionEnabled) ? nil :
                                .interpolatingSpring(stiffness: 130, damping: 10),
                                value: showDragHint
                            )
                            .animation(
                                (reduceMotion || reduceMotionEnabled) ? nil :
                                .interpolatingSpring(stiffness: 180, damping: 14),
                                value: isDragPressed
                            )

                        Text("Settings")
                            .font(.system(.footnote, design: .default, weight: .bold))
                            .foregroundStyle(.secondary)
                            .opacity(showDragHint ? 0.9 : 1)
                            .offset(y: showDragHint ? 6 : 0)
                            .scaleEffect(showDragHint ? 0.9 : 1.0)
                            .scaleEffect(isDragPressed ? 0.95 : 1.0)
                            .animation(
                                (reduceMotion || reduceMotionEnabled) ? nil :
                                .interpolatingSpring(stiffness: 120, damping: 6),
                                value: showDragHint
                            )
                            .animation(
                                (reduceMotion || reduceMotionEnabled) ? nil :
                                .interpolatingSpring(stiffness: 180, damping: 14),
                                value: isDragPressed
                            )
                    }
                    .frame(maxWidth: .infinity)
//                    .frame(height: 96)
                    .allowsHitTesting(viewModel.isTranslated)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .onChanged(handleResultDragChanged)
                            .onEnded(handleResultDragEnded)
                    )
                    .offset(
                        y: showSettings
                            ? UIScreen.main.bounds.height
                            : dragOffset
                    )
                }
            }
                        
            if (showSettings || dragOffset > 0) && !(viewModel.isRecording || viewModel.isTranscribing) {
                ZStack {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            (viewModel.isTranslated ? AppColor.Background.secondary : AppColor.Background.primary)
                                .frame(
                                    height: showSettings
                                    ? geo.size.height
                                    : dragOffset
                                )
                            
                            Spacer()
                        }
                        .ignoresSafeArea()
                        .animation(.interactiveSpring(response: 0.50, dampingFraction: 0.85),
                                   value: dragOffset)
                    }
                    
                    RouterStack(router: settingsRouter) {
                        SettingsView(showSettings: $showSettings)
                    }
                    .transition(.move(edge: .top))
                    .offset(
                        y: showSettings
                        ? 0
                        : max(-settingsOverlayStart + dragOffset,
                              -settingsOverlayStart)
                    )
                    .opacity(
                        showSettings
                        ? 1
                        : (
                            dragOffset > settingsContentRevealThreshold
                            ? min(1.0,
                                  (dragOffset - settingsContentRevealThreshold) / 600)
                            : 0
                        )
                    )
                    .animation(curtainEase, value: showSettings)
                }
                .zIndex(1)
            }
        }
        // No global gesture here - each section handles its own

        
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
        .onChange(of: viewModel.isTranslated) { _, isRes in
            if isRes {
                isDragHandleReady = false
            } else {
                isDragHandleReady = true
            }
        }
        .onChange(of: showSettings) { _, isShowing in
            if !isShowing {
                withAnimation(.interactiveSpring(response: 0.42,
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
        .onPreferenceChange(ScrollOffsetKey.self) { currentOffset in
            resultScrollOffset = currentOffset
        }
        .onChange(of: viewModel.isTranslated) { _, isRes in
            if isRes {
                isDragHandleReady = false
                isDragHandleVisible = true  // ← Reset to visible
            } else {
                isDragHandleReady = true
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
                dragOffset: dragOffset,
                onDragChanged: handleInputDragChanged,
                onDragEnded: handleInputDragEnded
            )
            .background(AppColor.Background.primary)
            
            
        } else {
            TranslateResultSection(
                viewModel: viewModel,
                textNamespace: textNamespace,
                adjustFontSizeDebounced: adjustFontSizeDebounced,
                shouldPlaySequentialAnimation: $shouldPlaySequentialAnimation,
                dynamicTextStyle: $dynamicTextStyle,
                dragOffset: $dragOffset,
                showSettings: $showSettings,
                dragHandleReady: $isDragHandleReady,
                dragHandleVisible: $isDragHandleVisible,
                resultScrollOffset: $resultScrollOffset,
                onDragChanged: handleResultDragChanged,
                onDragEnded: handleResultDragEnded
            )
            .background(AppColor.Onboarding.background)
            
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
    
    // MARK: - Input Section Drag Handlers (Light sensitivity)
    private func handleInputDragChanged(_ value: DragGesture.Value) {
        guard !isKeyboardActive else { return }
        guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
        guard value.translation.height > 0 else { return }
        
        isDragPressed = true
        dragOffset = softened(value.translation.height)
    }
    
    private func handleInputDragEnded(_ value: DragGesture.Value) {
        guard !isKeyboardActive else {
            UIApplication.shared.dismissKeyboard()
            return
        }
        guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
        guard value.translation.height > 0 else { return }
        
        isDragPressed = false
        
        // Light threshold for input section (80pt)
        let shouldOpen = value.translation.height > 20
        if shouldOpen {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                showSettings = true
                dragOffset = 10
            }
        } else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                dragOffset = 0
            }
        }
    }
    
    // MARK: - Result Section Drag Handlers (Medium sensitivity)
    private func handleResultDragChanged(_ value: DragGesture.Value) {
        guard !isKeyboardActive else { return }
        guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
        
        // Prevent drag when scrolled down (conflict with ScrollView)
        guard resultScrollOffset >= 0 else { return }
        guard value.translation.height > 0 else { return }
        
        isDragPressed = true
        dragOffset = softened(value.translation.height)
    }
    
    private func handleResultDragEnded(_ value: DragGesture.Value) {
        guard !isKeyboardActive else {
            UIApplication.shared.dismissKeyboard()
            return
        }
        guard !viewModel.isRecording && !viewModel.isTranscribing else { return }
        guard resultScrollOffset >= 0 else { return }
        guard value.translation.height > 0 else { return }
        
        isDragPressed = false
        
        // Medium threshold for result section (150pt)
        let shouldOpen = value.translation.height > 120
        if shouldOpen {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                showSettings = true
                dragOffset = 10
            }
        } else {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.85)) {
                dragOffset = 0
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
