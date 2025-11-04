//
//  KeyboardSettingView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import SwiftUI

struct KeyboardSettingView: View {
    @State private var autoCorrect: Bool = true
    @State private var autoCapslock: Bool = true
    @State private var selectedLayout: LayoutType = .qwerty
    
    var body: some View {
        ZStack
        {
            VStack {
                VStack(alignment: .leading, spacing: 8){
                    HStack
                    {
                        Text("Keyboard")
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                        Spacer()
                    }
                    Text("Now you can use this keyboard in any app")
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
                
                
                VStack(alignment: .center) {
                    let iconOne = Image(systemName: "globe")
                    let iconTwo = Image(systemName: "info.circle")
                    //placeholder lottie
                    Image("keyboardsettingplaceholder")
                        .resizable()
                        .frame(width: 315, height: 195, alignment: .center)
                        .padding(.vertical, 10)
                    
                    Text("SLNG keyboard is now enabled")
                        .font(.body)
                        .foregroundStyle(AppColor.Text.primary)
                        .padding(.top, 4)
                    
                    Text("Long press \(iconOne) and select SLNG keyboard or you can use Share extension \(iconTwo)")
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(maxWidth: 250)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 14)
                }
                
                VStack(spacing: 24) {
                    // Auto toggles
                    VStack(spacing: 4) {
                        Toggle("Auto Correct", isOn: $autoCorrect)
                            .padding(.vertical, 2)
                        Divider()
                        Toggle("Auto Capslock", isOn: $autoCapslock)
                            .padding(.vertical, 2)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    // gunakan maxWidth
                    .frame(maxWidth: .infinity)

                    // Keyboard layout
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Keyboard Layout")
                            .font(.headline)
                        
                        HStack(spacing: 40) {
                            ForEach(LayoutType.allCases, id: \.self) { layout in
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(selectedLayout == layout ? .black : Color(.systemGray4))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .opacity(selectedLayout == layout ? 1 : 0)
                                        )
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                selectedLayout = layout
                                            }
                                        }
                                    Text(layout.rawValue)
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .padding()
        }
    }
}

enum LayoutType: String, CaseIterable {
    case qwerty = "QWERTY"
    case qwertz = "QWERTZ"
    case azerty = "AZERTY"
}

#Preview {
    KeyboardSettingView()
}
