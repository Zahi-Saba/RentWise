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
