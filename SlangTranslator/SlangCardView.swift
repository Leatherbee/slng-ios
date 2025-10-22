//
//  SlangCardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
///Users/prammmoe/ADA-IL/Final Challenge/SlangTranslator/SlangTranslator/SlangCardView.swift
//
//  SlangCardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI

struct SlangCardView: View {
    let slangData: SlangData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(slangData.slang.uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(slangData.translationEN)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Context Section
            VStack(alignment: .leading, spacing: 6) {
                Label("Context", systemImage: "info.circle")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(slangData.contextEN)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            
            // Example Section
            VStack(alignment: .leading, spacing: 6) {
                Text("Example")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("“\(slangData.exampleID)”")
                        .font(.body)
                        .italic()
                        .foregroundColor(.primary)
                    Text("“\(slangData.exampleEN)”")
                        .font(.body)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(.gray.opacity(0.1))
        .cornerRadius(14)
    }
}

#Preview {
    SlangCardView(
        slangData: SlangData(
            slang: "gue",
            translationID: "saya / aku",
            translationEN: "me, I, I am",
            contextID: "Kata ganti orang pertama informal yang sangat umum di Jakarta dan sekitarnya.",
            contextEN: "A very common informal first-person pronoun in Jakarta and its surroundings.",
            exampleID: "Gue lagi sibuk nih.",
            exampleEN: "I'm busy right now."
        )
    )
}

