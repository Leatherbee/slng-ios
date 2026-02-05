import Foundation
import StoreKit
import UIKit

final class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    private init() {}

    private let prefs = AppPreferences.shared

    func recordAppOpenAndMaybePrompt() {
        updateActiveDays()
        maybeRequestReviewIfEligible()
    }

    func recordTranslationAndMaybePrompt() {
        prefs.reviewTranslationCount += 1
        maybeRequestReviewIfEligible()
    }

    func recordSTTAndMaybePrompt() {
        prefs.reviewSTTCount += 1
        maybeRequestReviewIfEligible()
    }

    private func updateActiveDays() {
        let today = Self.dayString(from: Date())
        let lastDay = prefs.reviewLastActiveDay
        if lastDay != today {
            prefs.reviewActiveDaysCount += 1
            prefs.reviewLastActiveDay = today
        }
        if prefs.reviewFirstOpenDate == 0 {
            prefs.reviewFirstOpenDate = Date().timeIntervalSince1970
        }
    }

    private func maybeRequestReviewIfEligible() {
        let initialEligible = isInitialEligibilityMet()
        let hasRequested = prefs.reviewRequestCount > 0
        let finalEligible = isFinalChanceEligibilityMet()

        if initialEligible && !hasRequested {
            requestReview()
            prefs.reviewFirstRequestDate = Date().timeIntervalSince1970
            prefs.reviewActiveDaysAtFirstRequest = prefs.reviewActiveDaysCount
            prefs.reviewRequestCount += 1
            return
        }

        if finalEligible {
            requestReview()
            prefs.reviewFinalChanceShown = true
        }
    }

    private func isInitialEligibilityMet() -> Bool {
        let translations = prefs.reviewTranslationCount
        let stt = prefs.reviewSTTCount
        let firstOpenTs = prefs.reviewFirstOpenDate
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        let hasSevenDays = firstOpenTs > 0 && (Date().timeIntervalSince1970 - firstOpenTs) >= sevenDays
        return translations >= 6 || stt >= 6 || hasSevenDays
    }

    private func isFinalChanceEligibilityMet() -> Bool {
        let hasRequested = prefs.reviewRequestCount > 0
        let finalShown = prefs.reviewFinalChanceShown
        if !hasRequested || finalShown { return false }
        let activeNow = prefs.reviewActiveDaysCount
        let activeAtFirst = prefs.reviewActiveDaysAtFirstRequest
        return (activeNow - activeAtFirst) >= 30
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }
        AppStore.requestReview(in: scene)
    }

    private static func dayString(from date: Date) -> String {
        let cal = Calendar.current
        let comp = cal.dateComponents([.year, .month, .day], from: date)
        let y = comp.year ?? 0
        let m = comp.month ?? 0
        let d = comp.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
