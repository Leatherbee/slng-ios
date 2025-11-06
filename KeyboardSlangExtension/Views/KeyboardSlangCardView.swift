//
//  SlangCardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import UIKit

struct KeyboardSlangCardView: View {
    let slangData: SlangData
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(slangData.slang.capitalized)
                    .font(.system(.title, design: .serif, weight: .regular))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .scaleEffect(isExpanded ? 1.1 : 1.0)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isExpanded)
                    .onTapGesture {
                        toggleCard()
                    }
                    .padding(.horizontal, 4)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(slangData.translationEN)
                        .font(.system(.body, design: .serif, weight: .bold))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                    
                    Text("Context")
                        .font(.system(.body, design: .serif, weight: .semibold))
                        .padding(.top, 10)
                        .italic()
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                    
                    Text(slangData.contextEN)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Example")
                            .font(.system(.body, design: .serif, weight: .semibold))
                            .italic()
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("“\(slangData.exampleID)”")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            
                            Text("“\(slangData.exampleEN)”")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.top, 6)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.clear))
        )
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleCard()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isExpanded)
    }
    
    private func toggleCard() {
        let generator = UIImpactFeedbackGenerator(style: isExpanded ? .light : .medium)
        generator.prepare()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.80, blendDuration: 0.2)) {
            isExpanded.toggle()
        }
        
        if isExpanded {
            generator.impactOccurred(intensity: 0.7)
        } else {
            generator.impactOccurred(intensity: 0.4)
        }
    }
}
