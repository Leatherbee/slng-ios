//
//  String+SlangNormalization.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 26/10/25.
//

import Foundation

extension String {
    func normalizedForSlangMatching() -> String {
        let lowercased = self.lowercased()
        return lowercased.replacingOccurrences(of: "(.)\\1+", with: "$1", options: .regularExpression)
    }
}
