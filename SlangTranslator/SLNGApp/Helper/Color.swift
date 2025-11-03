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
    }
    
    // MARK: - Button
    enum Button {
        static let primary = Color("buttonPrimary")
        static let secondary = Color("buttonSecondary")
        
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
}
