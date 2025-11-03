//
//  TranslateView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 20/10/25.
//

import SwiftUI
import SwiftData

struct TranslateView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = TranslateViewModel()

    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle
    @State private var showExpanded = false

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
            }
            else if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView("Translating...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .font(.headline)
                    Text("Please wait while we decode the slang...")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                .ignoresSafeArea()
            }
            else if !viewModel.isTranslated {
                inputSection
                    .transition(.opacity.combined(with: .scale))
            }
            else {
                resultSection
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .background(Color.backgroundPrimary)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isTranslated)
    }

    private var inputSection: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.inputText)
                    .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(minHeight: 100, maxHeight: 300)
                    .scrollContentBackground(.hidden)
                    .autocorrectionDisabled(true)
                    .onChange(of: viewModel.inputText) { oldValue, newValue in
                        adjustFontSizeDebounced()
                    }
                
                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Heard a slang you don't get? Type here")
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        .foregroundColor(Color.textDisable)
                        .padding(.horizontal, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal)

            Spacer()

            Button {
                UIApplication.shared.dismissKeyboard()
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
                    ? AppColor.Button.Text.primary : AppColor.Text.primary
                )
                .background(
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? AppColor.Button.secondary
                    : AppColor.Button.primary
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .padding()
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.dismissKeyboard()
        }
    }

    private var resultSection: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer()
                            .frame(height: 80)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(viewModel.inputText)
                                .foregroundColor(Color.textPrimary)
                                .textSelection(.enabled)

                            Divider()
                                .overlay(AppColor.Stroke.color)

                            if let translatedText = viewModel.translatedText {
                                Text(translatedText.capitalized)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        .padding(.horizontal, 24)

                        // MARK: Action Buttons
                        HStack {
                            HStack(spacing: 10) {
                                Button {
                                    viewModel.expandedView()
                                    showExpanded = true
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                }

                                Button { viewModel.copyToClipboard() } label: {
                                    Image(systemName: "doc.on.doc")
                                }
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
                                .background(
                                    AppColor.Button.primary
                                )
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)

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
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 120)
                    }
                    .alert("Copied!", isPresented: $viewModel.copiedToKeyboardAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("The translated text has been copied to the clipboard.")
                    }
                    .fullScreenCover(isPresented: $showExpanded) {
                        ExpandedTranslationView(text: viewModel.translatedText?.capitalized ?? "", onClose: { showExpanded = false })
                            .toolbar(.hidden, for: .tabBar)
                    }
                }

                Button {
                    viewModel.reset()
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
                .padding(.bottom, 30)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.clear, for: .navigationBar)
            .background(
                AppColor.Background.secondary
            )
        }
    }

    @State private var fontSizeWorkItem: DispatchWorkItem?
    
    private func adjustFontSizeDebounced() {
        fontSizeWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [inputText = viewModel.inputText] in
            let length = inputText.count
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

struct ExpandedTranslationView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let text: String
    let onClose: () -> Void
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(AppColor.Background.secondary)
                .ignoresSafeArea()

            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: true){
                    VStack {
                        Spacer(minLength: geo.size.height / 4)
                        Text(text)
                            .font(.system(size: 64, weight: .bold, design: .serif))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                        Spacer(minLength: geo.size.height / 4)
                    }
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
            
            Button {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                dismiss()
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .padding()
            }
        }
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
    }
}

#Preview {
    TranslateView()
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
