//
//  LanguageSettingView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 20/11/25.
//

import SwiftUI

struct LanguageSettingView: View {
    var body: some View {
        VStack {
            List {
                Section {
                    Button {
                        
                    } label: {
                        Text("English")
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        
                    } label: {
                        Text("Bahasa Indonesia")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    LanguageSettingView()
}
