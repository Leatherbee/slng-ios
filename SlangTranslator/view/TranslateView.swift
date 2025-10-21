//
//  TranslateView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 20/10/25.
//
import SwiftUI

struct TranslateView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    
    var body: some View {
        VStack(alignment: .leading){
            //title
            HStack
            {
                Text("Translate")
                    .font(.largeTitle)
                    .bold()
                Spacer()
            }
            
            //iput text area
            VStack(){
                VStack(alignment: .leading, spacing:2){
                    Text("Indonesia (Slang)")
                        .font(.footnote)
                    TextField("Masukkan Teks", text: $inputText, axis: .vertical)
                        .font(.title)
                        .bold()
                }
                
                Spacer()
                Divider()
                
                VStack(alignment: .leading, spacing:2){
                    Text("English")
                        .font(.footnote)
                    TextField("Translate", text: $translatedText, axis: .vertical)
                        .font(.title)
                        .bold()
                }
                .padding(.top, 12)
                
                Spacer()
            }
            .padding()
            .padding(.top, 12)
            .background(Color(.systemGray6))
            .frame(maxHeight: 278)
            
            Spacer()
        }
        .padding(.top,44)
        .padding(.horizontal,20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
            
    }
}

#Preview {
    TranslateView()
}
