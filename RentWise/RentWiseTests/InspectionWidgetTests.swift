import Foundation
import Testing
@testable import RentWise

@MainActor
struct InspectionWidgetTests {
    @Test func includesOngoingAndFutureVisitsButExcludesExpiredOrInvalidOnes() {
        let now = Date(timeIntervalSince1970: 1000)
        func visit(_ start: Double, _ end: Double) -> SharedInspection {
            SharedInspection(address: "Test property", startTime: now.addingTimeInterval(start), endTime: now.addingTimeInterval(end))
        }
        let visits = [visit(100, 200), visit(-100, 50), visit(-200, 0), visit(100, 10)]
        let result = SharedWidgetData.upcoming(visits, at: now)
        #expect(result.count == 2)
        #expect(result.first?.startTime == now.addingTimeInterval(-100))
        #expect(SharedWidgetData.upcoming(visits, at: now.addingTimeInterval(200)).isEmpty)
    }

    @Test func timelineUsesSortedUniqueBoundariesWithinOneDay() {
        let now = Date(timeIntervalSince1970: 1000)
        let visits = [
            SharedInspection(address: "A", startTime: now.addingTimeInterval(100), endTime: now.addingTimeInterval(200)),
            SharedInspection(address: "B", startTime: now.addingTimeInterval(100), endTime: now.addingTimeInterval(300)),
            SharedInspection(address: "Later", startTime: now.addingTimeInterval(90000), endTime: now.addingTimeInterval(91000))
        ]
        #expect(SharedWidgetData.timelineDates(for: visits, from: now) == [now, now.addingTimeInterval(100), now.addingTimeInterval(200), now.addingTimeInterval(300)])
        #expect(SharedWidgetData.timelineDates(for: [], from: now) == [now])
    }
}
