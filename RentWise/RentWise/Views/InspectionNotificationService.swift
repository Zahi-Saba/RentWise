
import Foundation
import UserNotifications

class InspectionNotificationService {

    private let notificationCenter = UNUserNotificationCenter.current()

    func requestPermission() async throws -> Bool {
        return try await notificationCenter.requestAuthorization(
            options: [.alert, .sound]
        )
    }

    func scheduleReminder(
        for inspection: RentalInspection,
        propertyAddress: String
    ) async throws {

        let reminderDate = inspection.startTime.addingTimeInterval(-30 * 60)

        guard reminderDate > Date() else {
            return
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
    }
}
