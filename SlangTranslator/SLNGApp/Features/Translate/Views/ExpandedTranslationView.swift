//
//  ExpandedTranslationView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 05/11/25.
//

import SwiftUI

struct ExpandedTranslationView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let text: String
    let onClose: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(AppColor.Background.secondary)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                ScrollView(.vertical, showsIndicators: true){
                    VStack {
                        Spacer(minLength: geo.size.height / 4)
                        Text(text)
                            .font(.system(size: 64, weight: .bold, design: .serif))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 10)
                        Spacer(minLength: geo.size.height / 4)
                    }
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height)
                }
                .frame(minWidth: geo.size.width, minHeight: geo.size.height)
            }
            
            Button {
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                dismiss()
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(colorScheme == .light ? .black : .white)
                    .padding()
            }
        }
        .onAppear {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
    }
}
