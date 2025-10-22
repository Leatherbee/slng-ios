//
//  KeyboardView.swift
//  IndoSlangTrans
//
//  Created by Cynthia Yapiter on 21/10/25.
//

import SwiftUI

struct KeyboardView: View {
    @State private var autoCorrection = true
    @State private var predictive = true
    @State private var smartPunctuation = false
    @State private var enableFullAccess = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("General")) {
                    NavigationLink(destination: Text("Keyboard list placeholder")) {
                        HStack {
                            Text("Keyboards")
                            Spacer()
                            Text("1")
                                .foregroundColor(.gray)
                        }
                    }

                    NavigationLink(destination: Text("Text Replacement placeholder")) {
                        Text("Text Replacement")
                    }
                }

                Section(header: Text("Typing")) {
                    Toggle("Auto-Correction", isOn: $autoCorrection)
                    Toggle("Predictive", isOn: $predictive)
                    Toggle("Smart Punctuation", isOn: $smartPunctuation)
                }

                Section(header: Text("Keyboard")) {
                    Toggle("Allow Full Access", isOn: $enableFullAccess)
                    NavigationLink(destination: Text("Instructions placeholder")) {
                        Text("How to enable the keyboard")
                    }
                }
            }
            .navigationTitle("Keyboard Settings")
        }
    }
}

#Preview {
    KeyboardView()
}
