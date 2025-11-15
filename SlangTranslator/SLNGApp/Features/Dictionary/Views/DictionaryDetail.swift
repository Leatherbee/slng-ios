//
//  DictionaryDetail.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 28/10/25.
//
import SwiftUI
import Foundation
struct DictionaryDetail: View {
    @Environment(PopupManager.self) private var popupManager
    @State private var slangData: SlangModel?
    @State private var variants: [SlangModel] = []
    @State private var selectedVariantIndex: Int = 0
    @State private var canonicalForm: String = ""
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
                        let current = variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex] : slangData
                        Text(current?.slang ?? "")
                            .font(.system(size: 64, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                            .textSelection(.enabled)
                        VStack(spacing: 24){
                            Text(current?.translationEN ?? "")
                                .font(.system(size: 18, design: .serif))
                                .foregroundColor(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                            Text(current?.exampleEN ?? "")
                                .font(.system(size: 14, design: .serif))
                                .foregroundColor(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding(.top ,geo.size.height * 0.20)
                .padding(.horizontal)
                .frame(maxWidth: geo.size.width, maxHeight: geo.size.height, alignment: .top)
               
            }
           
            VStack{
                Spacer()
                    .frame(height: 450)
                VStack(spacing:64){
                    VStack(spacing: 16){
                        Text("Similar")
                            .font(.system(size: 18, design: .serif))
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppColor.Text.primary)
                        HStack(spacing: 8){
                            ForEach(Array(variants.enumerated()), id: \.offset) { idx, v in
                                similiarButton(title: v.slang) {
                                    selectedVariantIndex = idx
                                }
                            }
                        }
                    }
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
                            let current = variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex] : slangData
                            if let text = current?.slang { viewModel.speak(text) }
                        } label: {
                            Image("speaker-icon")
                                .resizable()
                                .frame(width: 33, height: 33)
                                .foregroundColor(AppColor.Text.primary)
                        }
                    }
                }
             
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Spacer()
            
            
        }
        .onAppear() {
            self.slangData = popupManager.getSlangData()
            self.variants = popupManager.getVariants()
            self.canonicalForm = popupManager.getCanonicalForm() ?? ""
            if !variants.isEmpty { selectedVariantIndex = 0 }
            
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
                        let current = variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex] : slangData
                        Text(current?.contextEN ?? "")
                            .font(.system(size: 17, design: .serif))
                            .foregroundColor(AppColor.Text.primary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.system(size: 17, design: .serif))
                            .bold().italic()
                            .foregroundColor(AppColor.Text.primary)
                        Text("""
                        "\(variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex].exampleEN : slangData?.exampleEN ?? "")"
                        "\(variants.indices.contains(selectedVariantIndex) ? variants[selectedVariantIndex].exampleID : slangData?.exampleID ?? "")"
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
                             
                            
                        }
                        .frame(width: 44, height: 44)
                        .foregroundColor(AppColor.Text.primary.opacity(0.6))
                        .clipShape(.circle)
                      
                    }
                }
            }
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private struct similiarButton:  View {
        let title: String
        let onTap: () -> Void
        var body: some View {
            Button { onTap() } label: {
                Text(title)
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(AppColor.Text.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay {
                RoundedRectangle(cornerRadius: 37)
                    .inset(by: 0.5)
                    .stroke(
                        AppColor.Button.primary
                    )
            }
        }
    }
}
//
//struct DictionaryDetail_Previews: PreviewProvider {
//
//    // Mock Data
//    static let mockSlang = SlangModel(
//        id: UUID(),
//        slang: "anjeng",
//        translationID: "anjing",
//        translationEN: "crazy, impressive",
//        contextID: "Dalam konteks bercanda antar teman, kadang digunakan secara akrab untuk mengekspresikan keterkejutan atau kekaguman tanpa maksud menghina.",
//        contextEN: "In friendly banter, sometimes used playfully to express surprise or amazement without offensive intent.",
//        exampleID: "Anjeng, lo keren banget sih!",
//        exampleEN: "Damn, you're so cool!",
//        sentiment: .positive
//    )
//
//    // Mock PopupManager
//    class MockPopupManager: PopupManager {
//        override func getSlangData() -> SlangModel? {
//            return mockSlang
//        }
//    }
//
//    static var previews: some View {
//        DictionaryDetail()
//            .environment(PopupManager())
//            .previewDevice("iPhone 15 Pro")
//            .preferredColorScheme(.light)
//    }
//}


//"slang":"anjeng",
//"translationID":"anjing",
//"translationEN":"dog",
//"contextID":"Dalam konteks bercanda antar teman, kadang digunakan secara akrab untuk mengekspresikan keterkejutan atau kekaguman tanpa maksud menghina.",
//"contextEN":"In friendly banter, sometimes used playfully to express surprise or amazement without offensive intent.",
//"exampleID":"Anjeng, lo keren banget sih!",
//"exampleEN":"Damn, you're so cool!",
//"sentiment":"positive"
