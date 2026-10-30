import SwiftUI
import WidgetKit

struct InspectionEntry: TimelineEntry {
    let date: Date
    let inspections: [SharedInspection]
}

struct InspectionProvider: TimelineProvider {
    func placeholder(in context: Context) -> InspectionEntry {
        InspectionEntry(date: Date(), inspections: [SharedInspection(
            address: "Example property", startTime: Date().addingTimeInterval(3600),
            endTime: Date().addingTimeInterval(5400))])
    }

    func getSnapshot(in context: Context, completion: @escaping (InspectionEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        let now = Date()
        completion(InspectionEntry(date: now,
            inspections: SharedWidgetData.upcoming(SharedWidgetData.loadInspections(), at: now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InspectionEntry>) -> Void) {
        let now = Date()
        let inspections = SharedWidgetData.loadInspections()
        // Precompute changes at start/end times so expired visits disappear
        // even when the containing app is closed.
        let dates = SharedWidgetData.timelineDates(for: inspections, from: now)
        let entries = dates.map { date in
            InspectionEntry(date: date, inspections: SharedWidgetData.upcoming(inspections, at: date))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(24 * 60 * 60))))
    }
}

struct InspectionWidgetView: View {
    let entry: InspectionEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Inspections", systemImage: "calendar")
                .font(.headline).foregroundStyle(.teal)
            if entry.inspections.isEmpty {
                Text("No upcoming visits").font(.headline)
                Text("Schedule an inspection in Rentwise.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(Array(entry.inspections.prefix(family == .systemSmall ? 1 : 2).enumerated()), id: \.offset) { index, inspection in
                    if index > 0 { Divider() }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(inspection.address).font(.subheadline.weight(.semibold))
                            .lineLimit(family == .systemSmall ? 2 : 1)
                        HStack(spacing: 4) {
                            Text(inspection.startTime, style: .date)
                            Text("•")
                            Text(inspection.startTime, style: .time)
                        }.font(.caption).foregroundStyle(.secondary)
                        if inspection.startTime <= entry.date {
                            Text("In progress").font(.caption.weight(.semibold)).foregroundStyle(.teal)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
    }
}

@main
struct RentWiseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedWidgetData.widgetKind, provider: InspectionProvider()) { entry in
            InspectionWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Inspections")
        .description("See your next saved property visits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
