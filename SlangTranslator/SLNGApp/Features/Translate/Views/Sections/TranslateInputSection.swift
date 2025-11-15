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
                    Text(viewModel.isTranscribing ? "Okay… I’m piecing that together..." : (viewModel.isRecording ? "Alright, I'm all ears..." : "Heard a slang you don't get? Type here"))
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
            .zIndex(10)
        }
        .overlay(alignment: .bottom) {
            ZStack {
                if viewModel.isRecording {
                    Circle()
                        .stroke(AppColor.Button.primary.opacity(0.7), lineWidth: 3)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulse ? 1.4 : 1.0)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }

                Circle()
                    .fill(Color.clear)
                    .frame(width: 280, height: 280)
                    .contentShape(.circle)
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
                    VStack(spacing: 6) {
                        Circle()
                            .fill(AppColor.Button.primary)
                            .frame(width: 14, height: 14)
                            .shadow(color: AppColor.Button.primary.opacity(0.3), radius: 6)
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(Color.textDisable)
                    }
                }

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
            .padding(.bottom, 40)
            .zIndex(1)
        }
        .overlay(alignment: .bottom) {
            ZStack {
                if viewModel.isRecording {
                    Circle()
                        .stroke(AppColor.Button.primary.opacity(0.7), lineWidth: 3)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulse ? 1.4 : 1.0)
                        .opacity(pulse ? 0 : 1)
                        .animation(.easeOut(duration: 1).repeatForever(autoreverses: false), value: pulse)
                        .onAppear { pulse = true }
                        .onDisappear { pulse = false }
                }

                Circle()
                    .fill(Color.clear)
                    .frame(width: 340, height: 340)
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
                    VStack(spacing: 6) {
                        Circle()
                            .fill(AppColor.Button.primary)
                            .frame(width: 14, height: 14)
                            .shadow(color: AppColor.Button.primary.opacity(0.3), radius: 6)
                        Text("Recording")
                            .font(.caption)
                            .foregroundColor(Color.textDisable)
                    }
                }

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
            .padding(.bottom, 0)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }
}
