//
//  ContentView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var detectedSlangs: [SlangData] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Indonesian Slang Translator")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Pahami slang Indonesia dengan mudah")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Coba tempel teks yang mengandung slang:")
                        .font(.headline)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: detectSlangs) {
                        Text("Deteksi Slang")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                if !detectedSlangs.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(detectedSlangs.indices, id: \.self) { index in
                                SlangCardView(slangData: detectedSlangs[index])
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if !inputText.isEmpty {
                    Text("Tidak ada slang yang terdeteksi")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Cara menggunakan Share Extension:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("1. Highlight teks di aplikasi chat\n2. Tap Share\n3. Pilih 'Explain Slang'")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    func detectSlangs() {
        detectedSlangs = SlangDictionary.shared.findSlang(in: inputText)
    }
}
