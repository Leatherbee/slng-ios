//
//  KeyboardSettingView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 04/11/25.
//

import SwiftUI

struct KeyboardSettingView: View {
    
    @State private var showShareSheetPreview: Bool = false
    
    @AppStorage("settings.autoCorrect", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!)
    private var autoCorrect: Bool = true
    @AppStorage("settings.autoCaps", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!)
    private var autoCapslock: Bool = true
    @AppStorage("settings.keyboardLayout", store: UserDefaults(suiteName: "group.prammmoe.SLNG")!)
        
    private var keyboardLayoutRaw: String = LayoutType.qwerty.rawValue

    private var selectedLayout: LayoutType {
        get { LayoutType(rawValue: keyboardLayoutRaw) ?? .qwerty }
        set { keyboardLayoutRaw = newValue.rawValue }
    }
    
    var body: some View {
        ZStack {
            VStack {
                VStack(alignment: .leading, spacing: 8){
                    HStack {
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
                    let iconTwo = Text(Image(systemName: "info.circle")).foregroundStyle(.blue)
                    
                    Image("keyboardsettingplaceholder")
                        .resizable()
                        .frame(width: 315, height: 195, alignment: .center)
                        .padding(.vertical, 10)
                    
                    Text("SLNG keyboard is now enabled")
                        .font(.body)
                        .foregroundStyle(AppColor.Text.primary)
                        .padding(.top, 4)
                    
                    Button {
                        showShareSheetPreview = true
                    } label: {
                        Text("Long press \(iconOne) and select SLNG keyboard or you can use Share extension \(iconTwo)")
                            .font(.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                            .frame(maxWidth: 250)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 14)
                    }
                }
                
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Toggle("Auto Capslock", isOn: $autoCapslock)
                            .padding(.vertical, 2)
                            .tint(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Keyboard Layout")
                            .font(.system(.headline, design: .default, weight: .regular))
                        
                        HStack(spacing: 40) {
                            ForEach(LayoutType.allCases, id: \.self) { layout in
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(selectedLayout == layout ? AppColor.Text.primary : Color(.systemGray4))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .resizable()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(AppColor.Background.primary)
                                                .opacity(selectedLayout == layout ? 1 : 0)
                                        )
                                        .shadow(radius: 1)
                                        .onTapGesture {
                                            withAnimation(.easeInOut) {
                                                keyboardLayoutRaw = layout.rawValue
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
                    .cornerRadius(16)
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheetPreview) {
            ShareSheetPreviewSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct ShareSheetPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack {
                Image("ShareSheetPlaceholder")
                    .resizable()
                    .frame(width: 255, height: 520)
                    .padding(.bottom, 4)
                
                Text("Copy text and share")
                    .font(.system(.body, design: .default, weight: .regular))
                
                Text("Tap SLNG icon in the list of your apps")
                    .font(.system(.callout, design: .default, weight: .regular))
                    .foregroundStyle(AppColor.Text.secondary)
            }
            .navigationTitle("Share Sheet Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        
                    }
                }
            }
            .scrollIndicators(.hidden)
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

