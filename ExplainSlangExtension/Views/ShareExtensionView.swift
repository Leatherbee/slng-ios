//
//  ShareExtensionView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import SwiftData

struct ShareExtensionView: View {
    let sharedText: String
    let onDismiss: () -> Void
    
    @State private var detectedSlangs: [SlangData] = []
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: String?
    @State private var viewModel: ShareTranslateViewModel?
    
    // Dynamic font size based on text length
    private func dynamicFontSize(for text: String) -> Font {
        let length = text.count
        if length < 50 {
            return .system(.largeTitle, design: .serif, weight: .bold)
        } else if length < 100 {
            return .system(.title, design: .serif, weight: .bold)
        } else if length < 200 {
            return .system(.title2, design: .serif, weight: .bold)
        } else {
            return .system(.title3, design: .serif, weight: .bold)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Shared text
                    Text(sharedText)
                        .font(dynamicFontSize(for: sharedText))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Loading state
                    if isTranslating {
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.gray.opacity(0.15), .gray.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.4)
                                            .tint(.accentColor)
                                    )
                                    .shadow(radius: 4, y: 2)
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.3), value: isTranslating)
                            }
                            
                            Text("Translating your text...")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.25), value: isTranslating)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                    
                    // Error state
                    else if let error = translationError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(error)
                                .foregroundColor(.red)
                                .padding(0.4)
                        }
                        .padding()
                    }
                    
                    // Translated text + results
                    else if !translatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                                .frame(height: 1)
                                .overlay(AppColor.Stroke.color)
                                .padding(.horizontal)
                            
                            Text(translatedText)
                                .font(dynamicFontSize(for: translatedText))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            if !detectedSlangs.isEmpty {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Slang Detected (\(detectedSlangs.count))")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    ForEach(detectedSlangs.indices, id: \.self) { index in
                                        TranslateSlangCardView(
                                            slangData: detectedSlangs[index],
                                            backgroundColor: .clear
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .textSelection(.enabled)
                            } else {
                                VStack(spacing: 20) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 60))
                                        .foregroundStyle(.gray)
                                    Text("No slang detected")
                                        .font(.system(.headline, design: .serif, weight: .regular))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding()
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .scrollIndicators(.visible)
        }
        .onAppear {
            let context = SharedModelContainer.shared.context
            let apiKey = Bundle.main.infoDictionary?["APIKey"] as? String ?? ""
            let translationRepository = TranslationRepositoryImpl(apiKey: apiKey, context: context)
            let slangRepository = SlangRepositoryImpl(container: SharedModelContainer.shared.container)
            let useCase = TranslateSentenceUseCaseImpl(
                translationRepository: translationRepository,
                slangRepository: slangRepository
            )
            viewModel = ShareTranslateViewModel(useCase: useCase)
            
            Task {
                guard let vm = viewModel else { return }
                isTranslating = true
                vm.inputText = sharedText
                await vm.translate()
                
                if let result = vm.result {
                    translatedText = result.translation.englishTranslation
                    detectedSlangs = result.detectedSlangs
                }
                
                if let vmError = vm.errorMessage, !vmError.isEmpty {
                    translationError = vmError
                }
                isTranslating = false
            }
        }
    }
}

#Preview {
    ShareExtensionView(
        sharedText: """
        Bro, lo tau nggak, kemarin tuh gue literally capek banget sumpah...
        """,
        onDismiss: {}
    )
}
