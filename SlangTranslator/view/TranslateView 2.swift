//
//  OldTranslateView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 20/10/25.
//
import SwiftUI

struct OldTranslateView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    
    var body: some View {
        ScrollView(){
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
                            .disabled(true)
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 12)
                .background(Color(.systemGray6))
                .frame(maxHeight: 278)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Spacer()
            }
            .padding(.top,44)
            .padding(.horizontal)
            .frame(minHeight: 500)
//            .frame(minHeight: UIScreen.main.bounds.height - 100)
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.dismissKeyboard()
            }
        )
        .gesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
        )
            
    }
}

#Preview {
    OldTranslateView()
}
