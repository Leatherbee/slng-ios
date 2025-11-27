//
//  TranslateInputSection.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 05/11/25.
//

import SwiftUI
import FirebaseAnalytics

struct TranslateInputSection: View {
    @ObservedObject var viewModel: TranslateViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @AppStorage("reduceMotionEnabled", store: UserDefaults.shared) private var reduceMotionEnabled: Bool = false
    var textNamespace: Namespace.ID
    var adjustFontSizeDebounced: () -> Void
    
    @FocusState.Binding var isKeyboardActive: Bool
    @Binding var shouldPlaySequentialAnimation: Bool
    @Binding var dynamicTextStyle: Font.TextStyle
    var dragOffset: CGFloat
    
    var onDragChanged: (DragGesture.Value) -> Void
    var onDragEnded: (DragGesture.Value) -> Void
        
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
                    Text(viewModel.isTranscribing ? "Okay… I’m piecing that together..." : (viewModel.isRecording ? "Alright, I'm all ears..." : (viewModel.sttPlaceholder ?? "Heard a slang you don't get? Type here or hold below to say it")))
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        .foregroundColor(Color.textDisable)
                        .padding(.horizontal, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                        .accessibilityLabel("Input field for slang to translate")
                        .accessibilityHint("Type a slang word you want to translate")
                        .accessibilityHidden(false)
                
                    if !isKeyboardActive && !(reduceMotion || reduceMotionEnabled) && !viewModel.isRecording && !viewModel.isTranscribing {
                        BlinkingCursor()
                            .padding(.horizontal, -3)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            if !viewModel.isRecording {
                PrimaryButton(buttonColor: (
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? AppColor.Button.secondary
                    : AppColor.Button.primary
                ), textColor: (
                    (colorScheme == .dark && !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    ? AppColor.Button.Text.primary : .white
                ), accessibilityLabel: "Translate button"){
                    UIApplication.shared.dismissKeyboard()
                    shouldPlaySequentialAnimation = true
                    Analytics.logEvent("translate_button_pressed", parameters: [
                        "input_length": viewModel.inputText.count
                    ])
                    viewModel.translate(text: viewModel.inputText)
                } label : {
                    HStack {
                        Text("Translate")
                        Image(systemName: "arrow.right")
                    }
                    .padding(.vertical, 18)
                    .font(Font.body.bold())
                    .frame(maxWidth: 314, minHeight: 60)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .accessibilityInputLabels(["Translate button"])
                .zIndex(10)
            }
        }
        .overlay(alignment: .bottom) {
            if !isKeyboardActive {
                RecordButton(
                    isRecording: $viewModel.isRecording,
                    onStart: { viewModel.startRecording() },
                    onStopAndTranscribe: { viewModel.stopRecordingAndTranscribe() },
                    onCancel: { viewModel.stopRecording() },
                    audioLevel: viewModel.audioLevel
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 40)
                .zIndex(1)
                .accessibilityLabel("Hold to speak")
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
        .background(
            AppColor.Background.secondary
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.dismissKeyboard()
                }
        )
        .offset(y: dragOffset * 0.65)
        .opacity(CGFloat(max(0.0, 1.0 - (Double(dragOffset) / 260.0))))
        .scaleEffect(CGFloat(max(0.0, 1.0 - (Double(dragOffset) / 900.0))), anchor: .top)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.82), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 5) // Light sensitivity - easy to trigger
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }
}

extension View {
    func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
