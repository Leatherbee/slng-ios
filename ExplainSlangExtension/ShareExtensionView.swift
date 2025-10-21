//
//  ShareExtensionView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import Translation

struct ShareExtensionView: View {
    let sharedText: String
    let onDismiss: () -> Void
    
    @State private var detectedSlangs: [SlangData] = []
    @State private var translationSession: TranslationSession.Configuration?
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false
    @State private var translationError: String?

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Text")
                                .font(.caption)
                                .foregroundStyle(.black)
                                .textCase(.uppercase)
                            
                            Text(sharedText)
                                .font(.body)
                                .foregroundStyle(.black)
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
                            Text("\(error)")
                                .foregroundColor(.red)
                                .padding()
                        } else if !translatedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("English Translation")
                                    .font(.caption)
                                    .foregroundStyle(.black)
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
                                    .foregroundStyle(.black)
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
        }
        .translationTask(translationSession) { session in
            isTranslating = true
            translationError = nil
            do {
                let response = try await session.translate(sharedText)
                translatedText = response.targetText
            } catch {
                translationError = error.localizedDescription
            }
            isTranslating = false
        }
        .onAppear {
            detectedSlangs = SlangDictionary.shared.findSlang(in: sharedText)
            performTranslation()
        }
    }

    private func performTranslation() {
        if translationSession == nil {
            translationSession = TranslationSession.Configuration(
                source: nil,
                target: Locale.Language(languageCode: .english)
            )
        } else {
            translationSession?.invalidate()
            translationSession = nil
        }
    }
}

#Preview {
    ShareExtensionView(
        sharedText: "Gue lagi gabut nih, lu mau ngapain? Santuy aja deh",
        onDismiss: {}
    )
}
