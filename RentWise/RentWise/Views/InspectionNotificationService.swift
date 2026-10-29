
import Foundation
import UserNotifications

class InspectionNotificationService {

    private let notificationCenter = UNUserNotificationCenter.current()

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

        let reminderDate = inspection.startTime.addingTimeInterval(-30 * 60)

        guard reminderDate > Date() else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Property Inspection"
        content.body = "Your inspection at \(propertyAddress) starts in 30 minutes."
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "inspection-\(inspection.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        return true
    }
    
    func cancelReminders(for inspections: [RentalInspection]) {
        let identifiers = inspections.map {
            "inspection-\($0.id.uuidString)"
        }

        guard !identifiers.isEmpty else {
            return
        }

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }

}
