//
//  OnboardingNewView.swift
//  GravityDemo
//
//  Created by Filza on 06/11/25.
//
import SwiftUI
import Foundation
import SpriteKit
struct OnboardingNewView: View {
    @Environment(\.displayScale) private var displayScale
    @State private var selectedTitles: [String] = []
    @State private var scene: FocusScene? = nil
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
        VStack(spacing: 40){
            VStack(spacing: 0){
                GeometryReader{ geo in
                    ZStack{
                        Color.clear.onAppear{
                            if scene == nil {
                                scene = FocusScene(
                                    size: geo.size,
                                    data: data,
                                    displayScale: displayScale,
                                    backgroundColor: .clear ,
                                    restitution: 0.4,
                                    gravityY: -3,
                                    startDelaY: 0,
                                    onSelectionChange: { selected in selectedTitles = selected}
                                )
                            }
                        }
                        if let scene = scene {
                            SpriteView(scene: scene, options: [.allowsTransparency])
                                .ignoresSafeArea()
                        }
                    }
                    .background(.clear)
                }
                .background(.clear)
              
            }
            .padding()
            VStack(spacing: 32){
                VStack(spacing: 16){
                    Text("Stay fluent in the ever-changing slang world")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(AppColor.Text.primary)
                     
                    
                    Text("Discover new phrases, abbreviations, and real-life examples that show how Indonesian actually talk.")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(AppColor.Text.secondary)
                    
                        
                }
                
                Button{
                    
                } label: {
                    HStack(spacing: 7){
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColor.Button.Text.primary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColor.Button.Text.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(width: 294, height: 60)
                .background(AppColor.Button.primary, in: .capsule)
                
            }

        }
        .padding()
        .background(AppColor.Background.secondary)
    }
}

#Preview {
    OnboardingNewView()
}
