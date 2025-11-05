//
//  DictionaryDetail.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 28/10/25.
//
import SwiftUI

struct DictionaryDetail: View {
    @Environment(PopupManager.self) private var popupManager
    @State private var slangData: SlangData?
    @State private var showCloseButton: Bool = false
    @StateObject private var viewModel = DictionaryDetailViewModel()
    @State private var showInfoSheet: Bool = false
    @State private var sheetHeight: CGFloat = 300
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack{
            VStack(spacing: 64){
                if !showCloseButton{
                    Spacer()
                        .frame(width: 43, height: 43)
                }
                if showCloseButton {
                    HStack{
                        Spacer()
                        Button {
                            popupManager.isPresented.toggle()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppColor.Button.Text.primary)
                        }
                        .frame(width: 43, height: 43)
                        .background(AppColor.Button.primary)
                        .cornerRadius(9999)
                        .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.Background.secondary)
            VStack(spacing: 64){
                Spacer()
                VStack(spacing: 32){
                    Text(slangData?.slang ?? "Tes")
                        .font(.system(size: 64, design: .serif))
                        .foregroundColor(AppColor.Text.primary)
                    VStack(spacing: 24){
                        Text(slangData?.translationEN ?? "Lorem ipsum dolor sit amet")
                            .font(.system(size: 18, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                        Text(slangData?.exampleEN ?? "Lorem ipsum")
                            .font(.system(size: 20, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                Spacer()
                
                
            }
            .padding(.horizontal, 31)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            VStack{
                Spacer()
                    .frame(height: 450)
                HStack(spacing: 32){
                    Button{
                        showInfoSheet.toggle()
                    }label: {
                        Image("info-icon")
                            .resizable()
                            .frame(width: 33, height: 33)
                            .foregroundColor(AppColor.Text.primary)
                    }
                    
                    Button{
                        if let text = slangData?.slang {
                            viewModel.speak(text)
                        }
                    } label: {
                        Image("speaker-icon")
                            .resizable()
                            .frame(width: 33, height: 33)
                            .foregroundColor(AppColor.Text.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
            
            
        }
        .onAppear() {
            self.slangData = popupManager.getSlangData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.3)) {
                    self.showCloseButton = true
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            VStack(){
                HStack{
                    Button{
                        showInfoSheet.toggle()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17))
                            .foregroundColor(AppColor.Text.primary.opacity(0.6))
                    }
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.16))
                    .clipShape(.circle)
                    Spacer()
                    Text("Explain")
                        .font(.headline)
                        .foregroundColor(AppColor.Text.primary)
                    Spacer()
                }
                Spacer()
                VStack(spacing: 24){
                    VStack(spacing: 8){
                        Text("Context")
                            .font(.system(size: 17, design: .serif))
                            .bold()
                            .italic()
                            .foregroundColor(AppColor.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(slangData?.contextEN ?? "")
                            .font(.system(size: 17, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 8){
                        Text("Example")
                            .font(.system(size: 17, design: .serif))
                            .bold()
                            .italic()
                            .foregroundColor(AppColor.Text.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        
                        Text("""
                        "\(slangData?.exampleEN ?? "")"
                        "\(slangData?.exampleID ?? "")"
                        """)
                        .font(.system(size: 17, design: .serif))
                        .foregroundColor(AppColor.Text.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
               Spacer()
                
                
            }
            .padding()
            .presentationDetents([.height(sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationBackground(colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 1, green: 0.95, blue: 0.86))
        }
    }
}

#Preview {
    let popupManager = PopupManager()
    popupManager.setSlangData(
        SlangData(
            slang: "Gokil",
            translationID: "OKE",
            translationEN: "OKAY",
            contextID: "Gokil kamu pecah",
            contextEN: "Used to express excitement or disbelief",
            exampleID: "Gokil, kamu keren banget!",
            exampleEN: "Wow, you’re amazing!",
            sentiment: .negative
        )
    )
    
    return DictionaryDetail()
        .environment(popupManager)
}
