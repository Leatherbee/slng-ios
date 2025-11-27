//
//  AppColor.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 21/10/25.
//

import SwiftUI

enum AppColor {
    
    // MARK: - Background
    enum Background {
        static let primary = Color("backgroundPrimary")
        static let secondary = Color("backgroundSecondary")
        static let pureBlack = Color("pureBlack")
    }
    
    // MARK: - Button
    enum Button {
        static let primary = Color("buttonPrimary")
        static let secondary = Color("buttonSecondary")
        static let onboarding = Color("buttonEnable")
        
        enum Text {
            static let primary = Color("buttonTextPrimary")
        }
    }
    
    // MARK: - Status Bar
    enum StatusBar {
        static let color = Color("statusBar")
    }
    
    // MARK: - Stroke
    enum Stroke {
        static let color = Color("stroke")
    }
    
    // MARK: - Text
    enum Text {
        static let primary = Color("textPrimary")
        static let secondary = Color("textSecondary")
        static let disable = Color("textDisable")
    }
    
    // MARK: - Onboarding
    enum Onboarding {
        static let background = Color("OnboardingBackground")
        static let text = Color("OnboardingText")
        static let textTitle = Color("onboardingTextTitle")
        enum button {
            static let color = Color("OnboardingButton")
            static let text = Color("onboardingButtonText")
        }
    }
    
    enum List {
        static let primary = Color("listRowPrimary")
    }
    
    enum Hint {
        static let primary = Color("dragHint")
    }
    
    enum Divider {
        static let primary = Color("dividerPrimary").opacity(0.4)
    }
}

