//
//  DictionaryDetailView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 25/11/25.
//

import SwiftUI
import FirebaseAnalytics


struct DictionaryDetailView: View {
    let slangData: SlangModel?
    let variants: [SlangModel]
    @Binding var selectedVariantIndex: Int
    @ObservedObject var viewModel: DictionaryDetailViewModel
    
    var body: some View {
        
        GeometryReader { geo in
            VStack{
                VStack(spacing: 10){
                    let current = variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex] : slangData
                    Text(current?.slang ?? "")
                        .font(.system(size: 64, design: .serif))
                        .foregroundColor(AppColor.Text.primary)
                        .textSelection(.enabled)
                    Button {
                        viewModel.speak(current?.slang ?? "", language: "id")
                    } label: {
                        HStack(spacing: 8){
                            (
                                Text("/")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(.white) +
                                Text(current?.pronunciation ?? "")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(.white) +
                                Text("/")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .frame(height: 20)
                            Image(systemName: "speaker.wave.3")
                                .font(.system(size: 14.5, weight: .semibold))
                                .foregroundColor(.white)
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .background(AppColor.StatusBar.color.opacity(0.2))
                    .cornerRadius(37)
                    .shadow(radius: -10)
                    .modifier(GlassIfAvailable(isActive: true))
                    .padding(.bottom, 32)
                    
                    VStack(spacing: 24){
                        Text(current?.translationEN ?? "")
                            .font(.system(size: 18, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                        Text(current?.contextEN ?? "")
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .textSelection(.enabled)
                        VStack(spacing: 8){
                            Text("\"\(current?.exampleID ?? "")\"")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                            Text("\"\(current?.exampleEN ?? "")\"")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                            
                        }
                    }
                }
            }
            .padding(.top ,geo.size.height * 0.16)
            .padding(.horizontal)
            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height, alignment: .top)
        }
    }
}

@available(iOS 15.0, *)
private struct GlassIfAvailable: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *), isActive {
            content
                .clipShape(RoundedRectangle(cornerRadius: 37))
                .glassEffect(.regular.interactive())
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 37))
                .overlay(
                    RoundedRectangle(cornerRadius: 37)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
