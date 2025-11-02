//
//  KeyboardView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI

struct KeyboardView: View {
    var body: some View {
        ZStack
        {
            VStack(alignment: .leading, spacing: 8){
                HStack
                {
                    Text("Setup Keyboard")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                    Spacer()
                }
                Text("Follow the instruction bellow to setup keyboard translator")
                    .font(.footnote)
                    .foregroundStyle(Color.txtSecondary)
       
                //placeholder lottie
                Image("lottiePlaceholder")
                
                Spacer()
                
            }
            .padding(.top,44)
            .padding(.horizontal,20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            //action sheet
            VStack(){
                Spacer()
                VStack(spacing: 10){
                    Button{
                        print("Added to Keyboard")
                        openKeyboardSettings()
                    } label: {
                        Text("Add Keyboard")
                            .padding(.vertical, 18)
                            .font(Font.body.bold())
                            .foregroundColor(Color(.white))
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                     
                    .background(Color(.black))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text("This will open IOS system settings")
                        .font(.footnote)
                    
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 32)
                .background(Color(.systemGray6))
                
            }
        }
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    KeyboardView()
}
