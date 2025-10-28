//
//  TranslateView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 20/10/25.
//
import SwiftUI

struct TranslateView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @StateObject private var viewModel = TranslateViewModel()
    @State private var inputText: String = ""
    @State private var dynamicTextStyle: Font.TextStyle = .largeTitle  // largeTitle default
    @State private var isTranslated: Bool = true
    
    @State private var textHeight: CGFloat = 100 // initial height
    
    var body: some View {
        if viewModel.translatedText == nil{
            GeometryReader { geometry in
                VStack(){
                    Spacer()
                    ZStack(alignment: .leading) {
                        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Heard a slang you don't get? Type here")
                                .foregroundColor(colorScheme == .dark ? DesignSystem.Colors.textDisableDark : DesignSystem.Colors.textDisable)
                                .zIndex(1)
                        }
                        
                        TextEditor(text: $inputText)
                            .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(height: textHeight)
                            .autocorrectionDisabled(true)
                            .onChange(of: inputText) {
                                adjustFontSize()
                                recalcHeight(geometry: geometry)
                            }
                            .zIndex(0)
                    }
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .padding(.horizontal)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            UIApplication.shared.dismissKeyboard()
                        }
                    )
                    .gesture(
                        DragGesture().onChanged { _ in
                            UIApplication.shared.dismissKeyboard()
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                }
                .frame(maxWidth: .infinity, maxHeight: geometry.size.height)
                .padding()
                .onAppear {
                    recalcHeight(geometry: geometry)
                }
                
            }
            
            Button{
                viewModel.translate(text: inputText)
                print("Added to Keyboard")
            } label: {
                HStack(){
                    Text("Translate")
                    Image(systemName: "arrow.right")
                }
                .padding(.vertical, 18)
                .font(Font.body.bold())
                .frame(maxWidth: 314, minHeight: 60)
                .foregroundColor((colorScheme == .dark && (inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)==false) ? .black : .white)
                .background(
                    inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    Color(DesignSystem.Colors.buttonDisable) : (colorScheme == .light ? Color(DesignSystem.Colors.buttonPrimary) : .white)
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .padding()
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        else if let translatedText = viewModel.translatedText{
            VStack{
                VStack(alignment: .leading){
                    VStack(spacing: 24){
                        VStack(alignment: .leading){
                            Text(viewModel.inputText)
                                .foregroundColor(colorScheme == .light ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textPrimaryDark)
                                .textSelection(.enabled)
                                .autocorrectionDisabled(true)
                            
                            Divider()
                                .overlay(colorScheme == .light ? DesignSystem.Colors.textSecondary : DesignSystem.Colors.buttonDisable)
                            
                            Text(translatedText)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                
                        }
                        .font(.system(dynamicTextStyle, design: .serif, weight: .bold))
                        
                        //Action Buttons Row
                        HStack() {
                            HStack(spacing: 10){
                                Button {
                                    viewModel.expandedView()
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                }
                                
                                Button {
                                    viewModel.copyToClipboard()
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                            Spacer()
                            Button{
                                viewModel.showDetectedSlang()
                            } label: {
                                Text(viewModel.isDetectedSlangShown ? "Close Detected Slang (\(viewModel.slangDetected.count))" : "Show Detected Slang (\(viewModel.slangDetected.count))")
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 16)
                                    .foregroundColor(colorScheme == .dark ? .black : .white)
                                    .background(
                                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                        Color(DesignSystem.Colors.buttonDisable) : (colorScheme == .light ? Color(DesignSystem.Colors.buttonPrimary) : .white)
                                    )
                                    .clipShape(Capsule())
                            }

                        }
                        
                        if viewModel.isDetectedSlangShown{
                            VStack(alignment: .leading, spacing: 16){
                                Text("Slang Detected (\(viewModel.slangDetected.count))")
                                VStack(){
                                    ForEach(viewModel.slangDetected, id: \.self) { slang in
                                        HStack{
                                            Text(slang)
                                                .font(.title)
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                        }
                                        Divider()
                                    }
                                }
                            }
                        }
                        
                        Spacer()
//                        Spacer()
                    }
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .padding(.top, 44)
                .tint(colorScheme == .light ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textPrimaryDark)
                .alert("Copied!", isPresented: $viewModel.copiedToKeyboardAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("The translated text has been copied to the clipboard.")
                }
                
                Button{
                    viewModel.reset()
                    print("reset")
                } label: {
                    Label("Try Another", systemImage: "arrow.left")                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: 314, minHeight: 60)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .background(colorScheme == .light ? Color(DesignSystem.Colors.buttonPrimary) : .white
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .padding()
            }
            .background(
                colorScheme == .light ?
                Color(DesignSystem.Colors.backgroundSecondary).ignoresSafeArea() : Color(DesignSystem.Colors.backgroundSecondaryDark).ignoresSafeArea()
            )
        }
        
    }
        
        
    private func adjustFontSize() {
        let length = inputText.count
        // simple heuristic for dynamic font scaling
        withAnimation(.easeInOut(duration: 0.2)) {
            switch length {
            case 0...40: dynamicTextStyle = .largeTitle
            case 41...100: dynamicTextStyle = .title
            case 101...200: dynamicTextStyle = .title2
            case 201...340: dynamicTextStyle = .title3
            default: dynamicTextStyle = .headline
            }
        }
    }
    
    private func recalcHeight(geometry: GeometryProxy) {
        // Measure text height dynamically
        let width = geometry.size.width - 32
        let estimatedHeight = inputText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.preferredFont(forTextStyle: .largeTitle)],
            context: nil
        ).height + 50
        
        // Limit growth so it doesn’t exceed screen height
        textHeight = min(estimatedHeight, geometry.size.height - 30)
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
