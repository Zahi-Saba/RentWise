import Foundation
import Testing
@testable import RentWise

struct InspectionReminderTests {

    private func makeInspection(startTime: Date) -> RentalInspection {
        RentalInspection(
            rentalPropertyID: UUID(),
            startTime: startTime,
            endTime: startTime.addingTimeInterval(1800)
        )
    }

    @Test
    func reminderIsThirtyMinutesBeforeInspection() {
        let startTime = Date(timeIntervalSince1970: 2_000_000_000)
        let inspection = makeInspection(startTime: startTime)

        let reminder = InspectionNotificationService.reminderDate(
            for: inspection
        )

        #expect(reminder == startTime.addingTimeInterval(-1800))
    }

    @Test
    func futureReminderCanBeScheduled() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let inspection = makeInspection(
            startTime: now.addingTimeInterval(3600)
        )

        #expect(
            InspectionNotificationService.canScheduleReminder(
                for: inspection,
                now: now
            )
        )
    }

    @Test
    func reminderTooCloseToInspectionIsRejected() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let inspection = makeInspection(
            startTime: now.addingTimeInterval(1200)
        )

        #expect(
            !InspectionNotificationService.canScheduleReminder(
                for: inspection,
                now: now
            )
        )
    }

    @Test
    func notificationIdentifiersAreUnique() {
        let startTime = Date(timeIntervalSince1970: 2_000_000_000)

        let first = makeInspection(startTime: startTime)
        let second = makeInspection(startTime: startTime)

        let firstID = InspectionNotificationService.notificationIdentifier(
            for: first
        )

        let secondID = InspectionNotificationService.notificationIdentifier(
            for: second
        )

        #expect(firstID == "inspection-\(first.id.uuidString)")
        #expect(firstID != secondID)
    }
}
