//
//  DictionaryDetailView.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 19/11/25.
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
                VStack(spacing: 32){
                    let current = variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex] : slangData
                    Text(current?.slang ?? "")
                        .font(.system(size: 64, design: .serif))
                        .foregroundColor(AppColor.Text.primary)
                        .textSelection(.enabled)
                    
                    PrimaryButton(buttonColor: AppColor.Button.primary, textColor: AppColor.Button.Text.primary) {
                        viewModel.speak(current?.slang ?? "", language: "id")
                    } label: {
                        HStack(spacing: 8){
                            (
                                Text("/")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(AppColor.Button.Text.primary) +
                                Text(current?.pronunciation ?? "")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(AppColor.Button.Text.primary) +
                                Text("/")
                                    .font(.system(size: 14.5, weight: .bold))
                                    .foregroundColor(AppColor.Button.Text.primary)
                            )
                            .frame(height: 20)
                            Image(systemName: "speaker.wave.3")
                                .font(.system(size: 14.5, weight: .semibold))
                            
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
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
            .padding(.top ,geo.size.height * 0.20)
            .padding(.horizontal)
            .frame(maxWidth: geo.size.width, maxHeight: geo.size.height, alignment: .top)
            
        }
 
         
    }
    
  
}
