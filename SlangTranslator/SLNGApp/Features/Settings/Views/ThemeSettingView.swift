//
//  ThemeSettingView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 20/11/25.
//


import SwiftUI

struct ThemeSettingView: View {
    var body: some View {
        VStack {
            List {
                Section {
                    Button {
                        
                    } label: {
                        Text("Dark")
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        
                    } label: {
                        Text("Light")
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(AppColor.Background.secondary))
        }
    }
}

#Preview {
    ThemeSettingView()
}
