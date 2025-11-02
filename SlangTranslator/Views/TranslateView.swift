//
//  TranslateView.swift
//  SlangTranslator
//

import SwiftUI
import SwiftData

struct TranslateView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = TranslateViewModel()
    @Namespace private var textNamespace
    
    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle
    @State private var showExpanded = false
    @State private var textHeight: CGFloat = 0
    @State private var alignToInputPosition: Bool = true
    
    @State private var stage: Int = 0
    @State private var showBurst = false
    @State private var showPulse = false
    @State private var moveUp = false
    @State private var dividerProgress: CGFloat = 0
    @State private var showTranslated = false
    @State private var showDetectedSlangButton = false
    @State private var showDetectedSlang = false
    
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
            else if !viewModel.isTranslated {
                inputSection
            }
            else {
                resultSection
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
                    .onChange(of: viewModel.inputText) { _, _ in adjustFontSizeDebounced() }
                
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
                    ? Color.textPrimary : Color.buttonTextPrimary
                )
                .background(
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? Color.btnSecondary
                    : Color.btnPrimary
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .padding()
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }
    
    private var resultSection: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.bgSecondary.ignoresSafeArea()
                
                GeometryReader { screenGeo in
                    SunburstView(trigger: $showBurst)  // ✅ Ganti dengan ini
                        .allowsHitTesting(false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .position(x: screenGeo.size.width / 2,
                                  y: screenGeo.size.height / 2 - 150)
                }
                .zIndex(2)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer()
                            .frame(height: alignToInputPosition ? 150 : 100)
                        
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Original text
                                Text(viewModel.inputText)
                                    .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .matchedGeometryEffect(
                                        id: "originalText",
                                        in: textNamespace,
                                        properties: .position,
                                        anchor: .topLeading,
                                        isSource: viewModel.isTranslated
                                    )
                                    .offset(y: moveUp ? -textHeight * 0.2 : 0) // kontrol naik-turun halus
                                    .animation(.easeInOut(duration: 1.4), value: moveUp)
                                    .textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)
//                                    .background(
//                                        GeometryReader { geo in
//                                            Color.clear
//                                                .onAppear { textHeight = geo.size.height }
//                                        }
//                                    )
//                                    .scaleEffect(showPulse ? 1.05 : 1.0)
                                
                                // Divider
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.strok)
                                        .frame(width: geo.size.width * dividerProgress, height: 0.8)
                                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                        .animation(.easeOut(duration: 0.6), value: dividerProgress)
                                }
                                
                                // Translated text fade-in
                                if showTranslated, let translatedText = viewModel.translatedText {
                                    Text(translatedText)
                                        .font(.system(dynamicTextStyle, design: .serif, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Buttons - fade in after translated text
                        if showDetectedSlangButton {
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
                                    .background(Color.btnPrimary)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 32)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Detected Slang Animation
                        if viewModel.isDetectedSlangShown {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Slang Detected (\(viewModel.slangDetected.count))")
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 14) {
                                    ForEach(viewModel.slangData, id: \.slang) { slangData in
                                        TranslateSlangCardView(
                                            slangData: slangData,
                                            backgroundColor: Color.bgSecondary
                                        )
                                        .opacity(showDetectedSlang ? 1 : 0)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .delay(Double(viewModel.slangData.firstIndex(where: { $0.slang == slangData.slang }) ?? 0) * 0.05),
                                            value: showDetectedSlang
                                        )
//                                        .offset(y: showDetectedSlang ? 0 : 20)
//                                        .animation(.spring(response: 0.6, dampingFraction: 0.7)
//                                            .delay(Double(viewModel.slangData.firstIndex(where: { $0.slang == slangData.slang }) ?? 0) * 0.05),
//                                                   value: showDetectedSlang)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
//                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .onAppear {
//                                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                                    showDetectedSlang = true
//                                }
                            }
                            .onDisappear {
                                showDetectedSlang = false
                            }
                        }
                        
                        Spacer(minLength: 120)
                    }
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
                
                Button {
                    viewModel.reset()
                    resetAnimation()
                } label: {
                    Label("Try Another", systemImage: "arrow.left")
                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: 314, minHeight: 60)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(Color.btnPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .padding(.bottom, 30)
            }
            .onAppear {
                // Keep text in the same position as input on appear,
                // then run the staged animation and introduce spacing.
//                alignToInputPosition = true
                playSequentialAnimation()
            }
        }
    }
    
    // MARK: Animation sequence
    private func resetAnimation() {
        stage = 0
        showBurst = false
        showPulse = false
        moveUp = false
        dividerProgress = 0
        showTranslated = false
        showDetectedSlangButton = false
        showDetectedSlang = false
        alignToInputPosition = true
    }
    
    private func playSequentialAnimation() {
        // Stage 1: Show burst and pulse simultaneously
        stage = 1
        showBurst = true
        
        withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
            showPulse = true
        }
        
        // Stage 2: Hide burst after 0.9s (sesuai durasi SunburstView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.3)) {
                showBurst = false
                showPulse = false
            }
            
            // Stage 3: Move text up SETELAH burst hilang
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    alignToInputPosition = false
                }
                withAnimation(.easeInOut(duration: 0.8)) {
                    moveUp = true
                }
                
                // Stage 4: Show divider after text moved up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    stage = 3
                    withAnimation(.easeOut(duration: 0.6)) {
                        dividerProgress = 1.0
                    }
                    
                    // Stage 5: Show translated text
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        stage = 4
                        withAnimation(.easeIn(duration: 0.8)) {
                            showTranslated = true
                        }
                        
                        // Stage 6: Show detected slang button
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            stage = 5
                            withAnimation(.easeIn(duration: 0.5)) {
                                showDetectedSlangButton = true
                            }
                            
                            // Stage 7: Show detected slang cards when button is pressed
                            if viewModel.isDetectedSlangShown {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        showDetectedSlang = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Dynamic Font
    @State private var fontSizeWorkItem: DispatchWorkItem?
    
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

struct ExpandedTranslationView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let text: String
    let onClose: () -> Void
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(Color.bgSecondary)
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

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
