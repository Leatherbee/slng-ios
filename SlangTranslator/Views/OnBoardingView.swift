//
//  OnboardingView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 03/11/25.
//

import SwiftUI

struct OnBoardingView: View {
    var isSecondPage: Bool = true
    
    var body: some View {
        if isSecondPage {
            secondPage
        }
        else{
            firstPage
        }
    }
    
    private var firstPage: some View {
        VStack(spacing: 32){
            Spacer()
            VStack(alignment: .leading) {
                Text("CATCH")
                    .foregroundColor(Color.btnSecondary)
                Text("THE VIBE,")
                    .foregroundColor(Color.txtPrimary)
                Text("NOT JUST THE")
                    .foregroundColor(Color.btnSecondary)
                Text("WORDS")
                    .foregroundColor(Color.txtPrimary)
            }
            .font(.system(size: 64, weight: .bold, design: .serif))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16){
                Button {
                    print("hello")
                } label: {
                    Text("Get Started")
                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundColor(Color.btnTextPrimary)
                        .background(
                            Color.btnPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                
                Text("By starting, you accept our Terms of Use and Privacy Policy")
                    .foregroundColor(Color.txtSecondary)
                    .font(Font.caption)
                    .padding(.horizontal)
                    
            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(Color.bgSecondary)
    }
    
    private var secondPage: some View {
        OnBoardingPage(
            onBoardingTitle: "Stay fluent in the ever-changing slang world",
            onBoardingContent: "Discover new phrases, abbreviations, and real-life examples that show how Indonesian actually talk."
        )
    }
}

struct OnBoardingPage: View {
    var onBoardingTitle: String
    var onBoardingContent: String
    
    var body: some View {
        VStack{
            Spacer()
            VStack(spacing: 32){
                VStack(alignment: .leading, spacing: 16){
                    Text(onBoardingTitle)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundColor(Color.txtPrimary)
                    Text(onBoardingContent)
                        .font(.subheadline)
                        .foregroundColor(Color.txtSecondary)
                }
                
                Button {
                    print("hello")
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: 294, minHeight: 60)
                        .foregroundColor(Color.btnTextPrimary)
                        .background(
                            Color.btnPrimary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
            }
            .padding()
        }
    }
}

#Preview {
    OnBoardingView()
}
