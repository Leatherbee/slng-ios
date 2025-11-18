//
//  OnboardingView.swift
//  SlangTranslator
//
//  Created by Cynthia Yapiter on 03/11/25.
//

import SwiftUI
import Lottie
import FirebaseAnalytics

struct OnboardingView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var isSecondPage: Bool = true
    @SceneStorage("onboarding.pageNumber") var pageNumber: Int = 1
    @State var trialKeyboardText: String = ""
    @AppStorage("hasOpenKeyboardSetting", store: UserDefaults.shared) private var hasOpenKeyboardSetting = false
    

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
                OnboardingFourthPage(pageNumber: $pageNumber)
            }
            else if pageNumber==5{
                KeyboardView {
                    if hasOpenKeyboardSetting {
                        withAnimation {
                            pageNumber = 6
                        }
                    } else {
                        print("Keyboard belum diaktifkan di Settings.")
                    }
                }
            }
            else if pageNumber==6{
                sixthPage
            }
        }
//        .onAppear {
//            // If the keyboard has already been set up, fast-forward to the test page.
//            if hasOpenKeyboardSetting && pageNumber < 6 {
//                pageNumber = 6
//            } else if UserDefaults.standard.bool(forKey: "didOpenKeyboardSettings") && pageNumber < 6 {
//                // Fallback: if we returned from Settings and the view was recreated,
//                // mark setup as done and jump to test page.
//                hasOpenKeyboardSetting = true
//                pageNumber = 6
//            }
//        }
//        .onChange(of: hasOpenKeyboardSetting) { oldValue, newValue in
//            if newValue && pageNumber < 6 {
//                pageNumber = 6
//            }
//        }
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
                    Analytics.logEvent("tutorial_begin", parameters: [
                        "source": "onboarding"
                    ])
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
                    .frame(maxWidth: .infinity, alignment: .center)
                    
            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(AppColor.Background.secondary)
    }
    
    private var secondPage: some View {
        OnBoardingPage(
            content: {
                Image(colorScheme == .light ?"SecondOnboardingIllustration" : "SecondOnboardingIllustrationDark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 182, maxHeight: 288)
            },
            pageNumber: $pageNumber,
            onBoardingTitle: "Everyday Indonesian Translator",
            onBoardingContent: "Translate indonesian sentences, even when they mix slang, abbreviation, and everyday expressions.",
        )
    }
    
    private var thirdPage: some View {
        OnBoardingPage(
            content: {
                Image(colorScheme == .light ? "ThirdOnboardingIllustration" : "ThirdOnboardingIllustrationDark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 318, maxHeight: 339)
            },
            pageNumber: $pageNumber,
            onBoardingTitle: "Translate as you chat",
            onBoardingContent: "SLNG works right inside your keyboard and share sheet, helping you understand conversations.",
        )
    }
    
    private var fourthPage: some View {
        OnBoardingPage(
            content: {
                Image(colorScheme == .light ? "FourthOnboardingIllustration" : "FourthOnboardingIllustrationDark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 339, maxHeight: 262)
            },
            pageNumber: $pageNumber,
            onBoardingTitle: "Stay fluent in the ever-changing slang world",
            onBoardingContent: "Discover new phrases, abbreviations, and real-life examples that show how Indonesian actually talk.",
        )
    }
    
    private var sixthPage: some View{
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                VStack(alignment: .center, spacing: 16) {
                    let icon = Image(systemName: "globe")
                    Text("Switch to SLNG")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .padding(.top, 12) 
                    Text("Tap and hold \(icon) key below. Select SLNG Keyboard.")
                        .font(.subheadline)
                        .foregroundColor(AppColor.Text.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 292, minHeight: 50)
                }
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                LottieView(animation: .named(colorScheme == .light ? "keyboard-change-light" : "keyboard-change-dark"))
                    .looping()
                    .frame(width: 312, height: 268)
                    .padding(.bottom, 14)
                
                TextField("Write Something", text: $trialKeyboardText)
                    .focused($focusedField)
                    .foregroundColor(AppColor.Text.primary)
                    .tint(AppColor.Text.primary)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .frame(minHeight: 62)
                    .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            }
            
            Button {
                @AppStorage("hasOnboarded") var hasOnboarded = false
                hasOnboarded = true
                Analytics.logEvent("tutorial_complete", parameters: [
                    "source": "onboarding"
                ])
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
            .padding(.horizontal, 33)
            .padding(.bottom, 33)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(onBoardingContent)
                        .font(.subheadline)
                        .foregroundColor(AppColor.Text.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
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
            }
            .padding()
            .padding(.bottom, 33)
        }
    }
}

#Preview {
    OnboardingView()
}
