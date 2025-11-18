//
//  OnboardingNewView.swift
//  GravityDemo
//
//  Created by Filza on 06/11/25.
//
import SwiftUI
import Foundation
import SpriteKit

struct OnboardingFourthPage: View {
    @Environment(\.displayScale) private var displayScale
    @State private var selectedTitles: [String] = []
    @State private var scene: FocusScene? = nil
    @Binding var pageNumber: Int
    
    let data: [dataScene] = [
        dataScene(id: UUID(), title: "Mantul", color: AppColor.Button.primary, textColor: AppColor.Button.Text.primary),
        dataScene(id: UUID(), title: "Salfok", color: AppColor.Background.primary, textColor: AppColor.Text.primary),
        dataScene(id: UUID(), title: "Santuy", color: AppColor.Button.primary, textColor: AppColor.Button.Text.primary),
        dataScene(id: UUID(), title: "OMG!!!", color: AppColor.Background.primary, textColor: AppColor.Text.primary),
        dataScene(id: UUID(), title: "Gw", color: AppColor.Button.primary, textColor: AppColor.Button.Text.primary),
        dataScene(id: UUID(), title: "Gokil", color: AppColor.Background.primary, textColor: AppColor.Text.primary),
        dataScene(id: UUID(), title: "Nyesek", color: AppColor.Background.primary, textColor: AppColor.Text.primary),
        dataScene(id: UUID(), title: "Sabi", color: AppColor.Button.primary, textColor: AppColor.Button.Text.primary),
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            GeometryReader { geo in
                ZStack {
                    Color.clear.onAppear {
                        if scene == nil {
                            scene = FocusScene(
                                size: geo.size,
                                data: data,
                                displayScale: displayScale,
                                backgroundColor: .clear,
                                restitution: 0.4,
                                gravityY: -3,
                                startDelaY: 0,
                                onSelectionChange: { selected in
                                    selectedTitles = selected
                                }
                            )
                        }
                    }
                    if let scene = scene {
                        SpriteView(scene: scene, options: [.allowsTransparency])
                            .ignoresSafeArea()
                    }
                }
            }
            .frame(height: 320) 
            .padding(.horizontal, 16)
            
            Spacer()
            
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Stay fluent in the ever-changing slang world")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundColor(AppColor.Text.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.5)
                    
                    Text("Discover new phrases, abbreviations, and real-life examples that show how Indonesian actually talk.")
                        .font(.subheadline)
                        .foregroundColor(AppColor.Text.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                
                Button {
                    pageNumber += 1
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .padding(.vertical, 18)
                    .font(Font.body.bold())
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.onboardingTextPrimary)
                    .background(AppColor.Button.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                }
            }
            .padding()
            .padding(.bottom, 33)
        }
        .background(AppColor.Background.secondary)
    }
}


#Preview {
    OnboardingFourthPage(pageNumber: .constant(3))
}
