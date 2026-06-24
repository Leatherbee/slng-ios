//
//  SharedKeyboardUserDefaults.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 05/11/25.
//

import SwiftUI

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.prammmoe.SLNG") ?? .standard
    }
}
