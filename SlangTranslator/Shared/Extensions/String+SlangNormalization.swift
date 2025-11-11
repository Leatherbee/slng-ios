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

    func maxRepeatRun() -> Int {
        var maxRun = 1
        var currentRun = 0
        var prev: Character?

        for ch in self.lowercased() {
            if ch == prev {
                currentRun += 1
            } else {
                currentRun = 1
                prev = ch
            }
            if currentRun > maxRun { maxRun = currentRun }
        }
        return maxRun
    }
}
