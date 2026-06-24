//
//  Availability+Extension.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 20/11/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func ifAvailable<Content: View>(
        _ version: OperatingSystemVersion,
        transform: (Self) -> Content
    ) -> some View {
        if ProcessInfo.processInfo.isOperatingSystemAtLeast(version) {
            transform(self)
        } else {
            self
        }
    }
}

