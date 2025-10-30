//
//  SlangCardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 17/10/25.
//

import SwiftUI
import UIKit

struct SlangCardView: View {
    let slangData: SlangData
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(slangData.slang.capitalized)
                    .font(.system(.largeTitle, design: .serif, weight: .regular))
                    .foregroundColor(.primary)
                
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
                    
                    Text("Explanation")
                        .font(.system(.body, design: .serif, weight: .semibold))
                        .padding(.top, 10)
                        .italic()
                        .foregroundStyle(.primary)
                    
                    Text(slangData.contextEN)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Example")
                            .font(.system(.body, design: .serif, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("“\(slangData.exampleID)”")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.primary)
                            Text("“\(slangData.exampleEN)”")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.secondary)
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
        .scaleEffect(isExpanded ? 1.02 : 1.0)
        .contentShape(Rectangle()) // Make whole card tappable
        .onTapGesture {
            toggleCard()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isExpanded)
    }
    
    private func toggleCard() {
        let generator = UIImpactFeedbackGenerator(style: isExpanded ? .light : .medium)
        generator.prepare()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.2)) {
            isExpanded.toggle()
        }
        
        // Give distinct feel for expand vs collapse
        if isExpanded {
            generator.impactOccurred(intensity: 0.7)
        } else {
            generator.impactOccurred(intensity: 0.4)
        }
    }
}
