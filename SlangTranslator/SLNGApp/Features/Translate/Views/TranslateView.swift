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
    @State private var showExpanded = false
    @State private var textHeight: CGFloat = 0
    @State private var alignToInputPosition: Bool = true
    
    @State private var stage: Int = 0
    @State private var showBurst = false
    @State private var showPulse = false
    @State private var dividerProgress: CGFloat = 0
    @State private var showTranslated = false
    @State private var showDetectedSlangButton = false
    @State private var showDetectedSlang = false
    @State private var showBottomUI = false
    @State private var shouldPlaySequentialAnimation = false
    @State private var moveUp: Bool = false
    
    @State private var audioPlayer: AVAudioPlayer?
    
    @FocusState private var isKeyboardActive: Bool
    
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
    
    // MARK: Input Section
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
                    .onChange(of: viewModel.inputText) { _, _ in
                        adjustFontSizeDebounced()
                    }
                    .focused($isKeyboardActive)
                
                if viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Heard a slang you don't get? Type here")
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        .foregroundColor(Color.textDisable)
                        .padding(.horizontal, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                    
                    if !isKeyboardActive {
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
            .padding()
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { UIApplication.shared.dismissKeyboard() }
    }
    
    // MARK: Result Section
    private var resultSection: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.backgroundSecondary.ignoresSafeArea()
                
                GeometryReader { screenGeo in
                    SunburstView(trigger: $showBurst)
                        .allowsHitTesting(false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .position(x: screenGeo.size.width / 2,
                                  y: screenGeo.size.height / 2 - 150)
                }
                .zIndex(2)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Spacer().frame(height: alignToInputPosition ? 150 : 100)
                        
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                
                                // Original text (pulse only)
                                Text(viewModel.inputText)
                                    .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                                    .foregroundColor(Color.textPrimary)
                                    .multilineTextAlignment(.leading)
                                    .matchedGeometryEffect(
                                        id: "originalText",
                                        in: textNamespace,
                                        properties: .frame,
                                        anchor: .topLeading
                                    )
                                    .scaleEffect(showPulse ? 0.80 : 1.0)
                                    .offset(y: moveUp ? -textHeight * 0.2 : 0)
                                    .animation(.easeInOut(duration: 0.25), value: showPulse)
                                    .animation(.easeInOut(duration: 0.5), value: moveUp)
                                    .textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                
                                // Divider
                                GeometryReader { geo in
                                    Rectangle()
                                        .fill(Color.stroke)
                                        .frame(width: geo.size.width * dividerProgress, height: 0.8)
                                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                                        .animation(.easeOut(duration: 0.6), value: dividerProgress)
                                }
                                .frame(height: 1)
                                
                                // Translated text
                                if let translatedText = viewModel.translatedText {
                                    Text(translatedText)
                                        .font(.system(dynamicTextStyle, design: .serif, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .opacity(showTranslated ? 1 : 0)
                                        .scaleEffect(y: showTranslated ? 1.0 : 0.8, anchor: .top)
                                        .offset(y: showTranslated ? 0 : -10)
                                        .clipped(antialiased: true)
                                        .mask(
                                            Rectangle()
                                                .frame(height: showTranslated ? 2000 : 0)
                                                .animation(.easeOut(duration: 0.5), value: showTranslated)
                                        )
                                        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: showTranslated)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Buttons
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
                                    .background(AppColor.Button.primary)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Detected slang
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
                                        .opacity(showDetectedSlang ? 1 : 0)
                                        .animation(
                                            .easeInOut(duration: 0.6)
                                            .delay(Double(viewModel.slangData.firstIndex(where: { $0.slang == slangData.slang }) ?? 0) * 0.05),
                                            value: showDetectedSlang
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                            .onAppear { showDetectedSlang = true }
                            .onDisappear { showDetectedSlang = false }
                        }
                        
                        Spacer(minLength: 120)
                    }
                    .tint(Color.textPrimary)
                    .alert("Copied!", isPresented: $viewModel.copiedToKeyboardAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("The translated text has been copied to the clipboard.")
                    }
                    .fullScreenCover(isPresented: $showExpanded) {
                        ExpandedTranslationView(text: viewModel.translatedText?.capitalized ?? "", onClose: { showExpanded = false })
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
                        .background(
                            AppColor.Button.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .padding(.bottom, 30)
                .opacity(showBottomUI ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: showBottomUI)
            }
            .onAppear {
                if shouldPlaySequentialAnimation {
                    playSequentialAnimation()
                    shouldPlaySequentialAnimation = false
                }
            }
            .toolbar(showBottomUI ? .visible : .hidden, for: .tabBar)
        }
    }
    
    // MARK: Animation Logic
    private func resetAnimation() {
        stage = 0
        showBurst = false
        showPulse = false
        dividerProgress = 0
        showTranslated = false
        showDetectedSlangButton = false
        showDetectedSlang = false
        alignToInputPosition = true
        showBottomUI = false
    }
    
    private func playSequentialAnimation() {
        stage = 1
        showBurst = true
        triggerBurstHaptic()
        
        // Stage 1: Mulai burst dan pulse bersamaan
        withAnimation(.easeInOut(duration: 0.2)) {
            showPulse = true
        }
        
        // Stage 2: Burst & pulse selesai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                showBurst = false
            }
            withAnimation(.easeInOut(duration: 0.08)) {
                showPulse = false
            }
            
            // Stage 3: Teks naik setelah burst & pulse selesai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    alignToInputPosition = false
                    moveUp = true
                }
                
                // Stage 4: Divider muncul
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        dividerProgress = 1.0
                    }
                    
                    // Stage 5: Translated text
                    // di playSequentialAnimation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                            showTranslated = true
                        }
                        
                        // Stage 6: Detected slang button
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeIn(duration: 0.25)) {
                                showDetectedSlangButton = true
                            }
                            
                            // Stage 7: Bottom UI
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    showBottomUI = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func playBurstSound() {
        guard let url = Bundle.main.url(forResource: "whoosh", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.9
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            fatalError()
        }
    }
    
    
    // MARK: Haptic
    func triggerBurstHaptic() {
        playBurstSound()
        
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        let notif = UINotificationFeedbackGenerator()
        impact.prepare()
        notif.prepare()
        impact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            impact.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            notif.notificationOccurred(.success)
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
