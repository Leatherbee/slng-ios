//
//  LanguageSettingView.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 20/11/25.
//

import SwiftUI
import FirebaseAnalytics

struct LanguageSettingView: View {
    var body: some View {
        VStack {
            List {
                Section {
                    Button {
                        Analytics.logEvent("language_selected", parameters: [
                            "lang": "en"
                        ])
                    } label: {
                        Text("English")
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        Analytics.logEvent("language_selected", parameters: [
                            "lang": "id"
                        ])
                    } label: {
                        Text("Bahasa Indonesia")
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(AppColor.Background.secondary))
        }
    }
}

#Preview {
    LanguageSettingView()
}
