//
//  SetupKeyboardView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import SwiftUI
import Lottie

struct SetupKeyboardView: View {
    @ObservedObject var viewModel: KeyboardStatusViewModel
    @AppStorage("hasOpenKeyboardSetting", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!) private var hasOpenKeyboardSetting = false
    var onReturnFromSettings: () -> Void
    @Environment(\.colorScheme) var colorScheme

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
                
                LottieView(animation: .named(colorScheme == .light ? "keyboard-setup-light" : "keyboard-setup-dark"))
                    .looping()
                    .accessibilityHidden(true)
                
                Spacer()
                
            }
            .padding(.top,44)
            .padding(.horizontal,20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack {
                Spacer()
                VStack(spacing: 10){
                    Button{
                        openKeyboardSettings()
                    } label: {
                        Text("Add Keyboard")
                            .padding(.vertical, 18)
                            .font(Font.body.bold())
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .foregroundColor(.onboardingTextPrimary)
                            .background(
                                AppColor.Button.primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                    }
                    .accessibilityLabel("Add SLNG keyboard")
                    .accessibilityHint("Opens iOS Settings to enable the keyboard")
                    .accessibilityIdentifier("SetupKeyboardView.AddKeyboard")
                    
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
        .onAppear(){
            viewModel.updateKeyboardStatus()
        }
    }
    
    private func checkKeyboardStatus() {
        viewModel.updateKeyboardStatus()
        
        if viewModel.isFullAccessEnabled {
            hasOpenKeyboardSetting = true
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
