//
//  InspectionReportFileStore.swift
//  RentWise
//
//  Created by Bo Wen Chan on 28/10/2026.
//

import Foundation

struct InspectionReportFileStore {
    private let fileManager = FileManager.default

    // Keep generated reports for up to seven days
    private let retentionInterval: TimeInterval = 7 * 24 * 60 * 60

    func makeOutputURL(for report: InspectionConditionReport) throws -> URL {
        // Locate the application's cache directory
        let caches = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        // Create a dedicated reports folder
        let folder = caches.appendingPathComponent("RentWiseConditionReports", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

        // Remove old reports before creating a new one
        removeExpiredReports(in: folder)

        // Generate a safe property-address filename
        let addressPart = safeFilenamePart(report.property.address)

        // Include the inspection date.
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmm"

        let inspectionDate = dateFormatter.string(from: report.inspection.startTime)

        // Prevent collisions when generating multiple reports
        let uniquePart = String(UUID().uuidString.prefix(8))

        let filename = "RentWise-Condition-\(addressPart)-" + "\(inspectionDate)-\(uniquePart).pdf"

        return folder.appendingPathComponent(filename, isDirectory: false)
    }

    private func safeFilenamePart(_ address: String) -> String {
        let allowed = CharacterSet.alphanumerics

        let separated = address.unicodeScalars.map { scalar in
            allowed.contains(scalar)
                ? String(scalar)
                : "-"
        }.joined()

        // Remove consecutive separators
        let collapsed = separated.split(separator: "-").joined(separator: "-")
        let shortened = String(collapsed.prefix(50))

        return shortened.isEmpty ? "Property": shortened
    }

    private func removeExpiredReports(in folder: URL) {
        let cutoff = Date().addingTimeInterval(-retentionInterval)

        guard let files = try? fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [
                .contentModificationDateKey,
                .isRegularFileKey
            ]
        ) else {
            return
        }

        for file in files where file.pathExtension.lowercased() == "pdf" && file.lastPathComponent.hasPrefix("RentWise-Condition-") {
            guard let values = try? file.resourceValues(
                forKeys: [
                    .contentModificationDateKey,
                    .isRegularFileKey
                ]
            ),
            values.isRegularFile == true,
            let modified = values.contentModificationDate,
            modified < cutoff else {
                continue
            }

            try? fileManager.removeItem(at: file)
        }
    }
}
