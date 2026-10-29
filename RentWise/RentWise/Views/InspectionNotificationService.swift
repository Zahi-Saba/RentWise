
import Foundation
import UserNotifications

class InspectionNotificationService {

    private let notificationCenter = UNUserNotificationCenter.current()

    // Get the reminder time, 30 minutes before inspection
    static func reminderDate(for inspection: RentalInspection) -> Date {
        inspection.startTime.addingTimeInterval(-30 * 60)
    }

    // Use the inspection ID for scheduling and cancellation
    static func notificationIdentifier(for inspection: RentalInspection) -> String {
        "inspection-\(inspection.id.uuidString)"
    }

    static func canScheduleReminder(
        for inspection: RentalInspection,
        now: Date = Date()
    ) -> Bool {
        reminderDate(for: inspection) > now
    }

    func requestPermission() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true

        case .denied:
            return false

        case .notDetermined:
            return try await notificationCenter.requestAuthorization(
                options: [.alert, .sound]
            )

        @unknown default:
            return false
        }
    }

    func scheduleReminder(
        for inspection: RentalInspection,
        propertyAddress: String
    ) async throws -> Bool {

        guard Self.canScheduleReminder(for: inspection) else {
            return false
        }

        let reminderDate = Self.reminderDate(for: inspection)

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Property Inspection"
        content.body = "Your inspection at \(propertyAddress) starts in 30 minutes."
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier(for: inspection),
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        return true
    }

    func cancelReminders(for inspections: [RentalInspection]) {
        let identifiers = inspections.map {
            Self.notificationIdentifier(for: $0)
        }

        guard !identifiers.isEmpty else {
            return
        }

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }
}
