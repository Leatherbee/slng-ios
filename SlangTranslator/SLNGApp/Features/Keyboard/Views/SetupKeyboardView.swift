//
//  SetupKeyboardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import SwiftUI
import Lottie

struct SetupKeyboardView: View {
    @AppStorage("hasSetupKeyboard") private var hasSetupKeyboard: Bool = false
    var onReturnFromSettings: () -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8){
                HStack
                {
                    Text("Setup Keyboard")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                    Spacer()
                }
                Text("Follow the instruction bellow to setup keyboard translator")
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                
                LottieAnimationUIView(animationName: "keyboard-setup", width: 242, height: 526)
                
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
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.black))
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    
                    Text("This will open IOS system settings")
                        .font(.footnote)
                    
                    
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .padding(.horizontal)
                .padding(.bottom, 50)
                .background(Color(.systemGray6))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            checkKeyboardStatus()
        }
    }
    
    private func checkKeyboardStatus() {
        if UserDefaults.standard.bool(forKey: "didOpenKeyboardSettings") {
            hasSetupKeyboard = true
            onReturnFromSettings()
        }
    }
    
    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { _ in
                UserDefaults.standard.set(true, forKey: "didOpenKeyboardSettings")
            }
        }
    }
}
