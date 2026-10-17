//
//  PersistenceController.swift
//  RentWise
//
//  Created by Zahi Saba on 1/10/2026.
//

import Foundation
import CoreData

struct PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {

        container = NSPersistentContainer(
            name: "RentWiseModel"
        )

        container.loadPersistentStores { description, error in

            if let error = error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
    }
}
