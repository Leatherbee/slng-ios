//
//  DictionaryDetail.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 28/10/25.
//
import SwiftUI

struct DictionaryDetail: View {
    @Environment(PopupManager.self) private var popupManager
    @State private var slangData: SlangDataDummy?
    @State private var showCloseButton: Bool = false
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
                                .foregroundColor(.white)
                        }
                        .frame(width: 43, height: 43)
                        .background(.black)
                        .cornerRadius(9999)
                        .transition(.opacity)  
                    }
                    .frame(maxWidth: .infinity)
                }
                
                VStack(spacing: 64){
                    VStack(spacing: 8){
                        Text("\(slangData?.slang ?? "")")
                            .font(.system(size: 64, design: .serif)).frame(maxWidth: .infinity, alignment: .leading)
                        Text("/go-kil/")
                            .font(.system(size: 17, weight: .bold, design: .serif)).frame(maxWidth: .infinity, alignment: .leading)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 18){
                        VStack(spacing: 8){
                            Text("Meaning")
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .italic().frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(slangData?.contextEN ?? "") ")
                                .font(.system(size: 15, design: .serif))
                                .italic().frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        VStack(spacing: 8){
                            HStack{
                                Image(systemName: "info.circle")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                                Text("Context")
                                    .font(.system(size: 17, weight: .semibold, design: .serif))
                                    .italic()
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(slangData?.contextEN ?? "") ")
                                .font(.system(size: 15, design: .serif))
                                .italic().frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                        VStack(spacing: 8){
                            Text("Example:")
                                .font(.system(size: 17, weight: .semibold, design: .serif))
                                .italic().frame(maxWidth: .infinity, alignment: .leading)
                            VStack{
                                Text("“\(slangData?.exampleID ?? "")” ")
                                    .font(.system(size: 15, design: .serif))
                                    .italic().frame(maxWidth: .infinity, alignment: .leading)
                                Text("“\(slangData?.exampleEN ?? "")”")
                                    .font(.system(size: 15, design: .serif))
                                    .italic().frame(maxWidth: .infinity, alignment: .leading)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                .frame(maxWidth: 331, alignment: .center)
                
                Spacer()
                
                
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.99, green: 0.96, blue: 0.92))
        }
        .frame(width: .infinity, height: .infinity)
        .onAppear() {
            self.slangData = popupManager.getData()
             
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {                   withAnimation(.easeIn(duration: 0.3)) {
                    self.showCloseButton = true
                }
            }
        }
        
    }
    
}

#Preview {
    DictionaryDetail()
        .environment(PopupManager())
}
