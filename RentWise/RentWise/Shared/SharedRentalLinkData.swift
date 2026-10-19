//
//  SharedRentalLinkData.swift
//  RentWise
//
//  Created by Zahi Saba on 3/10/2026.
//

import Foundation

struct SharedRentalLinkData {

    static let appGroup = "group.com.ZahiOrg.RentWise"

    static func saveLink(_ link: String) {

        let defaults = UserDefaults(
            suiteName: appGroup
        )

        var links: [String] = []

        if let savedLinks = defaults?.stringArray(
            forKey: "sharedRentalLinks"
        ) {
            links = savedLinks
        }

        if !links.contains(link) {
            links.append(link)
        }

        defaults?.set(
            links,
            forKey: "sharedRentalLinks"
        )
    }

    static func loadLinks() -> [String] {

        let defaults = UserDefaults(
            suiteName: appGroup
        )

        if let savedLinks = defaults?.stringArray(
            forKey: "sharedRentalLinks"
        ) {
            return savedLinks
        }

        return []
    }
    
    static func removeLink(_ link: String) {

        let defaults = UserDefaults(
            suiteName: appGroup
        )

        var links: [String] = []

        if let savedLinks = defaults?.stringArray(
            forKey: "sharedRentalLinks"
        ) {
            links = savedLinks
        }

        if let index = links.firstIndex(
            of: link
        ) {
            links.remove(
                at: index
            )
        }

        defaults?.set(
            links,
            forKey: "sharedRentalLinks"
        )
    }



    static func clearLinks() {

        let defaults = UserDefaults(
            suiteName: appGroup
        )

        defaults?.removeObject(
            forKey: "sharedRentalLinks"
        )
    }
}


struct SharedListing: Codable, Identifiable {
    var id = UUID()
    var url: String
    var title: String
    var weeklyRent: Double? = nil
}

extension SharedRentalLinkData {
    // Each share is its own atomic file, avoiding a read/modify/write race
    // between the extension and app. Legacy URL-only queues remain readable.
    static func inboxDirectory() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            throw NSError(domain: "Rentwise", code: 1, userInfo: [NSLocalizedDescriptionKey: "Shared storage is unavailable. Check the App Group on both targets."])
        }
        let directory = container.appendingPathComponent("ListingInbox", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
    static func saveListing(_ listing: SharedListing, directory: URL? = nil) throws {
        let folder = try directory ?? inboxDirectory()
        let file = folder.appendingPathComponent(listing.id.uuidString).appendingPathExtension("json")
        try JSONEncoder().encode(listing).write(to: file, options: .atomic)
    }
    static func pendingListings(directory: URL? = nil) throws -> [(URL, SharedListing)] {
        let folder = try directory ?? inboxDirectory()
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { ($0, try JSONDecoder().decode(SharedListing.self, from: Data(contentsOf: $0))) }
    }
    static func acknowledgeListing(_ file: URL) throws {
        try FileManager.default.removeItem(at: file)
    }
}
