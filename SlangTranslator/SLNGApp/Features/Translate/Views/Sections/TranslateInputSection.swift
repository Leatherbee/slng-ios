//
//  TranslateInputSection.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 05/11/25.
//

import SwiftUI

struct TranslateInputSection: View {
    @ObservedObject var viewModel: TranslateViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    var textNamespace: Namespace.ID
    var adjustFontSizeDebounced: () -> Void
    
    @FocusState private var isKeyboardActive: Bool
    @Binding var shouldPlaySequentialAnimation: Bool
    @Binding var dynamicTextStyle: Font.TextStyle
    @State private var pulse = false
    @State private var dragTranslation: CGSize = .zero
    @State private var isCancelling: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.inputText)
                    .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                    .foregroundColor(.secondary)
                    .matchedGeometryEffect(
                        id: "originalText",
                        in: textNamespace,
                        properties: .position,
                        anchor: .topLeading,
                        isSource: !viewModel.isTranslated
                    )
                    .frame(minHeight: 100, maxHeight: 300)
                    .scrollContentBackground(.hidden)
                    .autocorrectionDisabled(true)
                    .onChange(of: viewModel.inputText) { _, _ in
                        adjustFontSizeDebounced()
                    }
                    .focused($isKeyboardActive)
                    .accessibilityLabel("Input text to translate")
                    .accessibilityInputLabels(["Input text"])
                    .accessibilityAddTraits(.allowsDirectInteraction)
                    .opacity((viewModel.isRecording || viewModel.isTranscribing) ? 0 : 1)
                    .allowsHitTesting(!(viewModel.isRecording || viewModel.isTranscribing))
                
                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isRecording || viewModel.isTranscribing {
                    Text(viewModel.isTranscribing ? "Catching the meaning…" : (viewModel.isRecording ? "I’m catching every word…" : "Confused by a slang? Drop it here"))
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        .foregroundColor(Color.textDisable)
                        .padding(.horizontal, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                        .accessibilityLabel("Input field for slang to translate")
                        .accessibilityHint("Type a slang word you want to translate")
                        .accessibilityHidden(false)
                    
                    if !isKeyboardActive && !reduceMotion && !viewModel.isRecording && !viewModel.isTranscribing {
                        BlinkingCursor()
                            .padding(.horizontal, -3)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button {
                UIApplication.shared.dismissKeyboard()
                shouldPlaySequentialAnimation = true
                viewModel.translate(text: viewModel.inputText)
            } label: {
                HStack {
                    Text("Translate")
                    Image(systemName: "arrow.right")
                }
                .padding(.vertical, 18)
                .font(Font.body.bold())
                .frame(maxWidth: 314, minHeight: 60)
                .foregroundColor(
                    (colorScheme == .dark && !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    ? AppColor.Button.Text.primary : .white
                )
                .background(
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? AppColor.Button.secondary
                    : AppColor.Button.primary
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isRecording || viewModel.isLoading)
            .accessibilityLabel("Translate button")
            .accessibilityInputLabels(["Translate button"])
            .accessibilityHidden(false)
        }
        .overlay(alignment: .bottom) {
            ZStack {
                if viewModel.isRecording {
                    SunburstImplosionView(color: AppColor.Button.primary, animated: !reduceMotion)
                        .frame(width: 180, height: 180)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }

                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppColor.Button.primary)
                                .frame(width: 44, height: 44)
                            Circle()
                                .stroke(AppColor.Button.primary.opacity(0.7), lineWidth: 3)
                                .frame(width: 64, height: 64)
                                .scaleEffect(pulse ? 1.3 : 0.9)
                                .opacity(pulse ? 0.2 : 0.8)
                        }
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(Color.textDisable)
                    }
                }

                Circle()
                    .fill(Color.clear)
                    .frame(width: 280, height: 280)
                    .contentShape(Circle())
                    .opacity(0.001)
                    .onLongPressGesture(minimumDuration: 0.6, maximumDistance: 50, pressing: { _ in }, perform: {
                        if !viewModel.isRecording {
                            viewModel.startRecording()
                        }
                    })
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                dragTranslation = value.translation
                                if viewModel.isRecording {
                                    isCancelling = dragTranslation.width > 80
                                }
                            }
                            .onEnded { _ in
                                if viewModel.isRecording {
                                    if isCancelling {
                                        viewModel.stopRecording()
                                    } else {
                                        viewModel.stopRecordingAndTranscribe()
                                    }
                                }
                                dragTranslation = .zero
                                isCancelling = false
                            }
                    )

                

                if viewModel.isRecording {
                    HStack {
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(isCancelling ? .red : Color.textDisable)
                            .font(.title3)
                            .scaleEffect(isCancelling ? 1.1 : 1.0)
                            .padding(.trailing, 24)
                            .opacity(1)
                    }
                }
            }
            .accessibilityLabel("Hold to speak")
            .padding(.bottom, 100)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }
}

struct SunburstImplosionView: View {
    var color: Color
    var animated: Bool = true
    @State private var progress: CGFloat = 1
    @State private var shrink: CGFloat = 0
    @State private var layerScales: [CGFloat] = []
    @State private var layers: [RayLayer] = []
    @State private var loop = false
    var body: some View {
        ZStack {
            ForEach(Array(layers.enumerated()), id: \.element.id) { index, layer in
                VariableSunburstShape(
                    seed: layer.seed,
                    progress: progress,
                    shrink: shrink,
                    scale: index < layers.count ? layerScales[index] : layer.scale
                )
                .fill(color.opacity(layer.opacity))
            }
        }
        .onAppear {
            setupLayers()
            layerScales = layers.map { $0.scale }
            if animated {
                loop = true
                runCycle()
            } else {
                progress = 1
                shrink = 0
            }
        }
        .onDisappear { loop = false }
    }
    private func runCycle() {
        if !loop { return }
        progress = 1
        shrink = 0
        withAnimation(.easeInOut(duration: 3.0)) {
            progress = 0.12
            shrink = 0.6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if !loop { return }
            withAnimation(.easeOut(duration: 0.2)) {
                progress = 0.0
                shrink = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if loop { runCycle() }
            }
        }
    }
    private func setupLayers() {
        layers = [
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.3, opacity: 0.25, delay: 0.00),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.45, opacity: 0.4, delay: 0.01),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.6, opacity: 0.55, delay: 0.02),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.75, opacity: 0.7, delay: 0.03),
            RayLayer(seed: Int.random(in: 0...10_000), scale: 0.9, opacity: 0.85, delay: 0.04)
        ]
    }
}
