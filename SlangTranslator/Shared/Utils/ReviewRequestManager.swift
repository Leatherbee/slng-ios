import Foundation
import StoreKit
import UIKit

final class ReviewRequestManager {
    static let shared = ReviewRequestManager()
    private init() {}

    private let defaults = UserDefaults.shared
    private let keyTranslationCount = "review.translationCount"
    private let keySTTCount = "review.sttCount"
    private let keyFirstOpenDate = "review.firstOpenDate"
    private let keyActiveDaysCount = "review.activeDaysCount"
    private let keyLastActiveDay = "review.lastActiveDay"
    private let keyReviewRequestCount = "review.requestCount"
    private let keyFirstRequestDate = "review.firstRequestDate"
    private let keyActiveDaysAtFirstRequest = "review.activeDaysAtFirstRequest"
    private let keyFinalChanceShown = "review.finalChanceShown"

    func recordAppOpenAndMaybePrompt() {
        updateActiveDays()
        maybeRequestReviewIfEligible()
    }

    func recordTranslationAndMaybePrompt() {
        let c = defaults.integer(forKey: keyTranslationCount) + 1
        defaults.set(c, forKey: keyTranslationCount)
        maybeRequestReviewIfEligible()
    }

    func recordSTTAndMaybePrompt() {
        let c = defaults.integer(forKey: keySTTCount) + 1
        defaults.set(c, forKey: keySTTCount)
        maybeRequestReviewIfEligible()
    }

    private func updateActiveDays() {
        let today = Self.dayString(from: Date())
        let lastDay = defaults.string(forKey: keyLastActiveDay)
        if lastDay != today {
            let count = defaults.integer(forKey: keyActiveDaysCount) + 1
            defaults.set(count, forKey: keyActiveDaysCount)
            defaults.set(today, forKey: keyLastActiveDay)
        }
        if defaults.object(forKey: keyFirstOpenDate) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: keyFirstOpenDate)
        }
    }

    private func maybeRequestReviewIfEligible() {
        let initialEligible = isInitialEligibilityMet()
        let hasRequested = defaults.integer(forKey: keyReviewRequestCount) > 0
        let finalEligible = isFinalChanceEligibilityMet()

        if initialEligible && !hasRequested {
            requestReview()
            defaults.set(Date().timeIntervalSince1970, forKey: keyFirstRequestDate)
            defaults.set(defaults.integer(forKey: keyActiveDaysCount), forKey: keyActiveDaysAtFirstRequest)
            defaults.set(defaults.integer(forKey: keyReviewRequestCount) + 1, forKey: keyReviewRequestCount)
            return
        }

        if finalEligible {
            requestReview()
            defaults.set(true, forKey: keyFinalChanceShown)
        }
    }

    private func isInitialEligibilityMet() -> Bool {
        let translations = defaults.integer(forKey: keyTranslationCount)
        let stt = defaults.integer(forKey: keySTTCount)
        let firstOpenTs = defaults.double(forKey: keyFirstOpenDate)
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60
        let hasSevenDays = firstOpenTs > 0 && (Date().timeIntervalSince1970 - firstOpenTs) >= sevenDays
        return translations >= 6 || stt >= 6 || hasSevenDays
    }

    private func isFinalChanceEligibilityMet() -> Bool {
        let hasRequested = defaults.integer(forKey: keyReviewRequestCount) > 0
        let finalShown = defaults.bool(forKey: keyFinalChanceShown)
        if !hasRequested || finalShown { return false }
        let activeNow = defaults.integer(forKey: keyActiveDaysCount)
        let activeAtFirst = defaults.integer(forKey: keyActiveDaysAtFirstRequest)
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
