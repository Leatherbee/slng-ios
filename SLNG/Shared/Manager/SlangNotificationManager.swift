//
//  SlangNotificationManager.swift
//  SlangTranslator
//
//  Manager for scheduling local notifications with random slang words every 3 hours.
//

import Foundation
import UserNotifications
import SwiftData

extension Notification.Name {
    static let slangNotificationTapped = Notification.Name("slangNotificationTapped")
}

final class SlangNotificationManager {
    static let shared = SlangNotificationManager()

    /// Key for slang ID in notification userInfo
    static let slangIDKey = "slangID"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let preferences = AppPreferences.shared

    /// Number of notifications to schedule at once (~2.5 days coverage)
    private let notificationCount = 20

    /// Interval between notifications in seconds (3 hours)
    #if DEBUG
    private let notificationInterval: TimeInterval = 60 // 1 minute for testing
    #else
    private let notificationInterval: TimeInterval = 3 * 60 * 60 // 3 hours
    #endif

    /// Threshold for rescheduling (1 day)
    private let refreshThreshold: TimeInterval = 24 * 60 * 60

    private let notificationCategory = "SLANG_NOTIFICATION"

    private init() {
        setupNotificationCategory()
    }

    // MARK: - Public Methods

    /// Request notification permission and schedule if granted
    func requestPermissionAndSchedule() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                preferences.slangNotificationsEnabled = true
                await scheduleNotifications()
                logInfo("Slang notifications enabled and scheduled", category: .notifications)
            } else {
                preferences.slangNotificationsEnabled = false
                logInfo("Notification permission denied", category: .notifications)
            }
            return granted
        } catch {
            logError("Failed to request notification permission: \(error)", category: .notifications)
            return false
        }
    }

    /// Enable or disable slang notifications
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            let settings = await notificationCenter.notificationSettings()
            if settings.authorizationStatus == .authorized {
                preferences.slangNotificationsEnabled = true
                await scheduleNotifications()
            } else if settings.authorizationStatus == .notDetermined {
                _ = await requestPermissionAndSchedule()
            } else {
                preferences.slangNotificationsEnabled = false
                logWarning("Cannot enable notifications - permission denied", category: .notifications)
            }
        } else {
            preferences.slangNotificationsEnabled = false
            await cancelAllNotifications()
            logInfo("Slang notifications disabled", category: .notifications)
        }
    }

    /// Check current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    /// Refresh notification schedule if needed (called on app foreground)
    func refreshScheduleIfNeeded() async {
        guard preferences.slangNotificationsEnabled else { return }

        let status = await checkAuthorizationStatus()
        guard status == .authorized else {
            preferences.slangNotificationsEnabled = false
            return
        }

        if let lastScheduled = preferences.notificationsLastScheduledDate {
            let timeSinceLastSchedule = Date().timeIntervalSince(lastScheduled)
            if timeSinceLastSchedule > refreshThreshold {
                logInfo("Refreshing notification schedule (last scheduled \(Int(timeSinceLastSchedule / 3600))h ago)", category: .notifications)
                await scheduleNotifications()
            }
        } else {
            await scheduleNotifications()
        }
    }

    /// Handle notification tap (for deep linking)
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        if let slangID = userInfo[Self.slangIDKey] as? String {
            logInfo("User tapped notification for slang: \(slangID)", category: .notifications)
            // Post notification to trigger deep link in MainTabbedView
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .slangNotificationTapped,
                    object: nil,
                    userInfo: [Self.slangIDKey: slangID]
                )
            }
        }
    }

    // MARK: - Private Methods

    private func setupNotificationCategory() {
        let category = UNNotificationCategory(
            identifier: notificationCategory,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        notificationCenter.setNotificationCategories([category])
    }

    @MainActor
    private func scheduleNotifications() async {
        await cancelAllNotifications()

        let slangs = selectRandomSlangs()
        guard !slangs.isEmpty else {
            logWarning("No slangs available for notifications", category: .notifications)
            return
        }

        var scheduledCount = 0
        for (index, slang) in slangs.enumerated() {
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: notificationInterval * Double(index + 1),
                repeats: false
            )

            let content = UNMutableNotificationContent()
            content.title = "Slang: \(slang.slang)"
            content.subtitle = slang.translationID
            content.body = slang.contextID.isEmpty ? slang.translationID : slang.contextID
            content.sound = .default
            content.categoryIdentifier = notificationCategory
            content.userInfo = ["slangID": slang.id.uuidString]

            let request = UNNotificationRequest(
                identifier: "slang_\(slang.id.uuidString)_\(index)",
                content: content,
                trigger: trigger
            )

            do {
                try await notificationCenter.add(request)
                scheduledCount += 1
                markSlangAsShown(slang)
            } catch {
                logError("Failed to schedule notification for \(slang.slang): \(error)", category: .notifications)
            }
        }

        preferences.notificationsLastScheduledDate = Date()
        logInfo("Scheduled \(scheduledCount) slang notifications", category: .notifications)
    }

    private func cancelAllNotifications() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers:
            await notificationCenter.pendingNotificationRequests()
                .filter { $0.identifier.hasPrefix("slang_") }
                .map { $0.identifier }
        )
    }

    @MainActor
    private func selectRandomSlangs() -> [SlangData] {
        let container = SharedModelContainer.shared.container
        let repo = SlangRepositoryImpl(container: container)
        let allSlangs = repo.loadAll()

        guard !allSlangs.isEmpty else { return [] }

        let shownIDs = Set(preferences.notificationsShownSlangIDs)

        // Filter to slangs that haven't been shown
        var available = allSlangs.filter { !shownIDs.contains($0.id.uuidString) }

        // If all slangs have been shown, reset and use all
        if available.count < notificationCount {
            preferences.notificationsShownSlangIDs = []
            available = allSlangs
            logInfo("Reset shown slang IDs - all slangs have been displayed", category: .notifications)
        }

        // Shuffle and pick
        let selected = Array(available.shuffled().prefix(notificationCount))
        return selected
    }

    private func markSlangAsShown(_ slang: SlangData) {
        var shownIDs = preferences.notificationsShownSlangIDs
        shownIDs.append(slang.id.uuidString)
        preferences.notificationsShownSlangIDs = shownIDs
    }
}
