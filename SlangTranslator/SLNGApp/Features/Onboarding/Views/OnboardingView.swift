//
//  OnboardingView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 03/11/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isSecondPage: Bool = true
    @SceneStorage("onboarding.pageNumber") var pageNumber: Int = 1
    @State var trialKeyboardText: String = ""
    @AppStorage("hasSetupKeyboard", store: UserDefaults.shared) private var hasSetupKeyboard = false

    @FocusState private var focusedField: Bool
    
    var body: some View {
        Group {
            if pageNumber==1 {
                firstPage
            }
            else if pageNumber==2{
                secondPage
            }
            else if pageNumber==3{
                thirdPage
            }
            else if pageNumber==4{
                KeyboardView {
                    if hasSetupKeyboard {
                        withAnimation {
                            pageNumber = 5
                        }
                    } else {
                        print("Keyboard belum diaktifkan di Settings.")
                    }
                }
            }
            else if pageNumber==5{
                fifthPage
            }
            else if pageNumber==6{
                sixthPage
            }
        }
        .onAppear {
            // If the keyboard has already been set up, fast-forward to the test page.
            if hasSetupKeyboard && pageNumber < 5 {
                pageNumber = 5
            } else if UserDefaults.standard.bool(forKey: "didOpenKeyboardSettings") && pageNumber < 5 {
                // Fallback: if we returned from Settings and the view was recreated,
                // mark setup as done and jump to test page.
                hasSetupKeyboard = true
                pageNumber = 5
            }
        }
        .onChange(of: hasSetupKeyboard) { newValue in
            if newValue && pageNumber < 5 {
                pageNumber = 5
            }
        }
    }
    
    private var firstPage: some View {
        VStack(spacing: 32){
            Spacer()
            VStack(alignment: .leading) {
                Text("CATCH")
                    .foregroundColor(AppColor.Button.secondary)
                Text("THE VIBE,")
                    .foregroundColor(AppColor.Text.primary)
                Text("NOT JUST THE")
                    .foregroundColor(AppColor.Button.secondary)
                Text("WORDS")
                    .foregroundColor(AppColor.Text.primary)
            }
            .font(.system(size: 64, weight: .bold, design: .serif))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16){
                Button {
                    pageNumber+=1
                } label: {
                    Text("Get Started")
                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundColor(.onboardingTextPrimary)
                        .background(
                            AppColor.Button.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                
                Text("By starting, you accept our [Terms of Use](https://slng.space/terms/) and [Privacy Policy](https://slng.space/privacy/).")
                    .tint(AppColor.Button.primary)
                    .foregroundStyle(AppColor.Text.secondary)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    
            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(AppColor.Background.secondary)
    }
    
    private var secondPage: some View {
        OnBoardingPage(
            content: {Image(colorScheme == .light ?"OnBoardingIcon" : "OnBoardingIconDark")},
            pageNumber: $pageNumber,
            onBoardingTitle: "Stay fluent in the ever-changing slang world",
            onBoardingContent: "Discover new phrases, abbreviations, and real-life examples that show how Indonesian actually talk.",
        )
    }
    
    private var thirdPage: some View {
        OnBoardingPage(
            content: {
                Image("OnBoardingIcon2")
                    .resizable()
                    .frame(width: 300,height: 340)
            },
            pageNumber: $pageNumber,
            onBoardingTitle: "Translate as you chat",
            onBoardingContent: "SLNG works right inside your keyboard and share sheet, helping you understand conversations.",
        )
    }
    
    private var fifthPage: some View{
        VStack{
            VStack(spacing: 16){
                VStack{
                    VStack(alignment: .center, spacing:16){
                        Text("Switch to SLNG")
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                        Text("Tap and hold 􀆪 key below. Select SLNG Keyboard.")
                            .font(.subheadline)
                            .foregroundColor(AppColor.Text.primary)
                    }
                    Image("OnBoardingSwitchKeyboard")
                        .frame(maxWidth: 312, maxHeight: 268)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                
                TextField("Write Something", text: $trialKeyboardText)
                    .focused($focusedField)
                    .foregroundColor(focusedField ? .black : AppColor.Text.disable)
                    .tint(.black)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .frame(minHeight: 62)
                
            }
            .padding()
            .padding(.horizontal, 10)
            
            Spacer()
            Button {
                pageNumber+=1
            } label: {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                    .padding(.vertical, 18)
                    .font(Font.body.bold())
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .foregroundColor(.onboardingTextPrimary)
                    .background(
                        AppColor.Button.primary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30))
            }
            .padding(.horizontal, 33)
        }
    }
    
    private var sixthPage: some View {
        OnBoardingPage(
            content: {
                Image("OnBoardingIcon")
            },
            pageNumber: $pageNumber,
            onBoardingTitle: "You're all set",
            onBoardingContent: "Explore slang and abbreviations. Type to see what they mean.",
        )
    }
}

struct OnBoardingPage<Content: View>: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @ViewBuilder var content: () -> Content
    @Binding var pageNumber: Int
    var onBoardingTitle: String
    var onBoardingContent: String
    
    var body: some View {
        VStack{
            Spacer()
            VStack{
                content()
            }
            Spacer()
            VStack(spacing: 32){
                VStack(alignment: .leading, spacing: 16){
                    Text(onBoardingTitle)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundColor(AppColor.Text.primary)
                    Text(onBoardingContent)
                        .font(.subheadline)
                        .foregroundColor(AppColor.Text.secondary)
                }
                .padding(.horizontal, 10)
                
                Button {
                    if pageNumber < 6 {
                        pageNumber+=1
                    }
                    else{
                        hasOnboarded = true
                    }
                } label: {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                        .padding(.vertical, 18)
                        .font(Font.body.bold())
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .foregroundColor(.onboardingTextPrimary)
                        .background(
                            AppColor.Button.primary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                }
                .padding(.horizontal, 33)
            }
            .padding()
            .padding(.bottom, 33)
        }
    }
}

#Preview {
    OnboardingView()
}
