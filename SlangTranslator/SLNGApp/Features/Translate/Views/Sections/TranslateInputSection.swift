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
                    Text(viewModel.isTranscribing ? "Decoding what you mean ..." : (viewModel.isRecording ? "Still yapping? I'm hearing..." : "Heard a slang you don't get? Type here"))
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
            
            HStack(spacing: 12) {
                Button {
                    if viewModel.isRecording {
                        viewModel.stopRecordingAndTranscribe()
                    } else {
                        viewModel.startRecording()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.isRecording ? "stop.circle" : "mic")
                        Text(viewModel.isRecording ? "Stop & Transcribe" : "Speak")
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: 314, minHeight: 60)
                }
                .foregroundColor((colorScheme == .dark) ? AppColor.Button.Text.primary : .white)
                .background(viewModel.isRecording ? AppColor.Button.secondary : AppColor.Button.primary)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .accessibilityLabel(viewModel.isRecording ? "Stop recording and transcribe" : "Start recording")
            }
            
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
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }
}
