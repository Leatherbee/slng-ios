//
//  Untitled.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 30/10/25.
//

import SwiftUI
import UIKit

// MARK: - TranslateSlangCardView
struct TranslateSlangCardView: View {
    let slangData: SlangData
    var backgroundColor: Color = Color(.systemBackground)
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(slangData.slang.capitalized)
                    .font(.system(.title, design: .serif, weight: .regular))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(.primary)
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: isExpanded)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleCard()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(isExpanded ? "Collapse details for \(slangData.slang.capitalized)" : "Expand details for \(slangData.slang.capitalized)")
            .accessibilityHint("Tap to show or hide slang details")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityAction {
                toggleCard()
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(slangData.translationEN)
                        .font(.system(.body, design: .serif, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    
                    Text("Context")
                        .font(.system(.body, design: .serif, weight: .semibold))
                        .padding(.top, 10)
                        .italic()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    
                    Text(slangData.contextEN)
                        .font(.system(.body, design: .serif, weight: .regular))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Example")
                            .font(.system(.body, design: .serif, weight: .semibold))
                            .italic()
                            .foregroundStyle(.primary)
                            .textSelection(.enabled)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(slangData.exampleID)")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                            
                            Text("\(slangData.exampleEN)")
                                .font(.system(.body, design: .serif))
                                .italic()
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            Divider()
        }
        .background(backgroundColor)
        .accessibilityElement(children: .contain)
    }
    
    private func toggleCard() {
        let generator = UIImpactFeedbackGenerator(style: isExpanded ? .light : .medium)
        generator.prepare()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.80, blendDuration: 0.2)) {
            isExpanded.toggle()
        }
        
        if Haptics.isEnabled {
            if isExpanded {
                generator.impactOccurred(intensity: 0.7)
            } else {
                generator.impactOccurred(intensity: 0.4)
            }
        }
    }
}
