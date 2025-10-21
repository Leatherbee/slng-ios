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
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Original text section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original Text")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Text(sharedText)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Translation section
                        if isTranslating {
                            ProgressView("Translating...")
                                .padding()
                        } else if let error = translationError {
                            Text("⚠️ \(error)")
                                .foregroundColor(.red)
                                .padding()
                        } else if !translatedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("English Translation")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                Text(translatedText)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Slang detection results
                        if !detectedSlangs.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Slang Detected (\(detectedSlangs.count))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
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
                                    .foregroundColor(.gray)
                                Text("No slang detected")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Explain Slang")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { onDismiss() }
                }
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                        performTranslation()
//                    } label: {
//                        Label("Translate", systemImage: "translate")
//                    }
//                }
            }
        }
        // Translation happens here automatically when configuration is non-nil
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
        // Initialize or toggle the translation session
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
