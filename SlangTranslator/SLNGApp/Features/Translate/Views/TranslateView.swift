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
    @State private var fontSizeWorkItem: DispatchWorkItem?
    @AppStorage("hasRequestedSpeechMic", store: UserDefaults.shared) private var hasRequestedSpeechMic = false
    
    var body: some View {
        ZStack {
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
                .ignoresSafeArea()
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
            } else {
                TranslateResultSection(
                    viewModel: viewModel,
                    textNamespace: textNamespace,
                    adjustFontSizeDebounced: adjustFontSizeDebounced,
                    shouldPlaySequentialAnimation: $shouldPlaySequentialAnimation,
                    dynamicTextStyle: $dynamicTextStyle
                )
            }
        }
        .background(Color.backgroundPrimary)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isTranslated)
        .onAppear {
            if !hasRequestedSpeechMic {
                viewModel.prewarmPermissions()
                hasRequestedSpeechMic = true
            }
        }
        .onAppear {
            if !hasRequestedSpeechMic {
                viewModel.prewarmPermissions()
                hasRequestedSpeechMic = true
            }
        }
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
}

struct BlinkingCursor: View {
    @State private var isVisible: Bool = true
    
    var body: some View {
        Text("|")
            .font(.system(size: 46, weight: .regular, design: .serif))
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isVisible)
        .onAppear {
            isVisible.toggle()
        }
    }
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
