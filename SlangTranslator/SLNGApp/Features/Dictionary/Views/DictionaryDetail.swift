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
            
            GeometryReader { geo in
                VStack{
                    VStack(spacing: 32){
                        Text(slangData?.slang ?? "Tes")
                            .font(.system(size: 64, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .textSelection(.enabled)
                        VStack(spacing: 24){
                            Text(slangData?.translationEN ?? "Lorem ipsum dolor sit amet")
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                            Text(slangData?.exampleEN ?? "Lorem ipsum")
                                .font(.system(size: 20, design: .serif))
                                .foregroundColor(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.top ,geo.size.height * 0.20)
                .frame(maxWidth: geo.size.width, maxHeight: geo.size.height, alignment: .top)
               
            }
           
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
            NavigationView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Context")
                            .font(.system(size: 17, design: .serif))
                            .bold().italic()
                            .foregroundColor(AppColor.Text.primary)
                        Text(slangData?.contextEN ?? "")
                            .font(.system(size: 17, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.system(size: 17, design: .serif))
                            .bold().italic()
                            .foregroundColor(AppColor.Text.primary)
                        Text("""
                        "\(slangData?.exampleEN ?? "")"
                        "\(slangData?.exampleID ?? "")"
                        """)
                        .font(.system(size: 17, design: .serif))
                        .foregroundColor(AppColor.Text.primary)
                        .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .navigationTitle("Explanation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showInfoSheet.toggle()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17))
                                .foregroundColor(AppColor.Text.primary.opacity(0.6))
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
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
