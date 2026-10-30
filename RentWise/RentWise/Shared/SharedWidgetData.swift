//
//  SharedWidgetData.swift
//  RentWise
//
//  Created by Zahi Saba on 3/10/2026.
//

import Foundation

struct SharedInspection {

    let address: String
    let startTime: Date
    let endTime: Date
}

struct SharedWidgetData {

    static let appGroup = "group.com.ZahiOrg.RentWise"
    static let widgetKind = "RentWiseWidget"

    static func saveInspections(
        _ inspections: [SharedInspection]
    ) {

        let defaults = UserDefaults(
            suiteName: appGroup
        )

        var addresses: [String] = []
        var startTimes: [Date] = []
        var endTimes: [Date] = []

        for inspection in inspections {

            addresses.append(
                inspection.address
            )

            startTimes.append(
                inspection.startTime
            )

            endTimes.append(
                inspection.endTime
            )
        }

        defaults?.set(
            addresses,
            forKey: "widgetInspectionAddresses"
        )

        defaults?.set(
            startTimes,
            forKey: "widgetInspectionStartTimes"
        )

        defaults?.set(
            endTimes,
            forKey: "widgetInspectionEndTimes"
        )
    }

    static func loadInspections()
        -> [SharedInspection] {

        let defaults = UserDefaults(
            suiteName: appGroup
        )

        var inspections: [SharedInspection] = []

        if let addresses = defaults?.stringArray(
            forKey: "widgetInspectionAddresses"
        ),
        let startTimes = defaults?.array(
            forKey: "widgetInspectionStartTimes"
        ) as? [Date],
        let endTimes = defaults?.array(
            forKey: "widgetInspectionEndTimes"
        ) as? [Date] {

            for index in 0..<addresses.count {

                if index < startTimes.count &&
                    index < endTimes.count {

                    let inspection =
                        SharedInspection(
                            address: addresses[index],
                            startTime: startTimes[index],
                            endTime: endTimes[index]
                        )

                    inspections.append(
                        inspection
                    )
                }
            }
        }

        return inspections.sorted {
            $0.startTime < $1.startTime
        }
    }
}

// Pure date filtering shared with the widget and covered by app tests.
extension SharedWidgetData {
    static func upcoming(_ inspections: [SharedInspection], at date: Date) -> [SharedInspection] {
        inspections.filter { $0.endTime > date && $0.endTime > $0.startTime }
            .sorted { $0.startTime < $1.startTime }
    }

    static func timelineDates(for inspections: [SharedInspection], from date: Date) -> [Date] {
        let horizon = date.addingTimeInterval(24 * 60 * 60)
        let boundaries = upcoming(inspections, at: date).flatMap { [$0.startTime, $0.endTime] }
            .filter { $0 > date && $0 < horizon }
        return [date] + Array(Set(boundaries)).sorted()
    }
}
