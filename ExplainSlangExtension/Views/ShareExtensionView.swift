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
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Text")
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .textCase(.uppercase)
                            
                            Text(sharedText)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if isTranslating {
                            ProgressView("Translating...")
                                .padding()
                        } else if let error = translationError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(error)")
                                    .foregroundColor(.red)
                                    .padding(0.4)
                            }
                            .padding()
                        } else if !translatedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("English Translation")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .textCase(.uppercase)
                                
                                Text(translatedText)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        if !detectedSlangs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Slang Detected (\(detectedSlangs.count))")
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .textCase(.uppercase)
                                    .padding(.horizontal)
                                
                                ForEach(detectedSlangs.indices, id: \.self) { index in
                                    SlangCardView(slangData: detectedSlangs[index])
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.gray)
                                Text("No slang detected")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Word Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { onDismiss() }
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            detectedSlangs = SlangDictionary.shared.findSlang(in: sharedText)
            
            let context = SharedModelContainer.shared.context
            let apiKey = Bundle.main.infoDictionary?["APIKey"] as? String ?? ""
            let repository = TranslationRepositoryImpl(apiKey: apiKey, context: context)
            let useCase = TranslateSentenceUseCaseImpl(repository: repository)
            viewModel = ShareTranslateViewModel(useCase: useCase)
            
            // Translate
            Task {
                guard let vm = viewModel else { return }
                isTranslating = true
                vm.inputText = sharedText
                await vm.translate()
                translatedText = vm.result?.englishTranslation ?? ""
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
        sharedText: "Gue lagi gabut nih, lu mau ngapain? Santuy aja deh",
        onDismiss: {}
    )
}
