//
//  CoreDataRentalPropertyRepository.swift
//  RentWise
//
//  Created by Zahi Saba on 1/10/2026.
//

import Foundation
import CoreData

enum CoreDataRentalPropertyRepositoryError: Error {
    case rentalPropertyNotFound
    case inspectionNotFound
    case observationNotFound
}

class CoreDataRentalPropertyRepository: RentalPropertyRepository {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func save(_ property: RentalProperty) throws {

        let propertyEntity = RentalPropertyEntity(context: context)

        propertyEntity.id = property.id
        propertyEntity.address = property.address
        propertyEntity.weeklyRent = property.weeklyRent
        propertyEntity.sourceURL = property.sourceURL
        propertyEntity.roomsData = try JSONEncoder().encode(property.rooms)

        try context.save()
    }
    
    func update(_ property: RentalProperty) throws {
        let request = RentalPropertyEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", property.id as CVarArg)
        guard let entity = try context.fetch(request).first else {
            throw CoreDataRentalPropertyRepositoryError.rentalPropertyNotFound
        }
        entity.address = property.address
        entity.weeklyRent = property.weeklyRent
        entity.sourceURL = property.sourceURL
        entity.roomsData = try JSONEncoder().encode(property.rooms)
        try context.save()
    }

    func delete(_ inspection: RentalInspection) throws {
        let request = RentalInspectionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", inspection.id as CVarArg)
        guard let entity = try context.fetch(request).first else {
            throw CoreDataRentalPropertyRepositoryError.inspectionNotFound
        }
        // Core Data cascades to observations; the property and its rooms remain.
        context.delete(entity)
        do { try context.save() }
        catch { context.rollback(); throw error }
    }

    func delete(_ property: RentalProperty) throws {

        let request =
            RentalPropertyEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "id == %@",
            property.id as CVarArg
        )

        let properties =
            try context.fetch(request)

        if properties.isEmpty {

            throw CoreDataRentalPropertyRepositoryError
                .rentalPropertyNotFound
        }

        context.delete(
            properties[0]
        )

        try context.save()
    }
    func update(
        _ observation: InspectionObservation
    ) throws {

        let request =
            InspectionObservationEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "id == %@",
            observation.id as CVarArg
        )

        let savedObservations =
            try context.fetch(request)

        if savedObservations.isEmpty {

            throw CoreDataRentalPropertyRepositoryError
                .observationNotFound
        }

        let observationEntity =
            savedObservations[0]

        observationEntity.status =
            observation.status.rawValue

        observationEntity.notes =
            observation.notes

        try context.save()
    }
    func save(_ inspection: RentalInspection) throws {

        let request = RentalPropertyEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "id == %@",
            inspection.rentalPropertyID as CVarArg
        )

        let properties = try context.fetch(request)

        if properties.isEmpty {
            throw CoreDataRentalPropertyRepositoryError.rentalPropertyNotFound
        }

        let inspectionEntity = RentalInspectionEntity(context: context)

        inspectionEntity.id = inspection.id
        inspectionEntity.startTime = inspection.startTime
        inspectionEntity.endTime = inspection.endTime
        inspectionEntity.rentalProperty = properties[0]

        try context.save()
    }

    func save(_ observation: InspectionObservation) throws {

        let request = RentalInspectionEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "id == %@",
            observation.inspectionID as CVarArg
        )

        let inspections = try context.fetch(request)

        if inspections.isEmpty {
            throw CoreDataRentalPropertyRepositoryError.inspectionNotFound
        }

        let observationEntity = InspectionObservationEntity(context: context)

        observationEntity.id = observation.id
        observationEntity.criterion = observation.criterion.rawValue
        observationEntity.status = observation.status.rawValue
        observationEntity.notes = observation.notes
        observationEntity.inspection = inspections[0]

        try context.save()
    }
    func fetchRentalProperties() throws -> [RentalProperty] {

        let request = RentalPropertyEntity.fetchRequest()

        let entities = try context.fetch(request)

        var properties: [RentalProperty] = []

        for entity in entities {

            if let id = entity.id,
               let address = entity.address {

                var property = RentalProperty(
                    id: id,
                    address: address,
                    weeklyRent: entity.weeklyRent,
                    sourceURL: entity.sourceURL
                )

                if let data = entity.roomsData {
                    property.rooms = try JSONDecoder().decode([InspectionRoom].self, from: data)
                }
                properties.append(property)
            }
        }

        return properties
    }
    func fetchUpcomingInspections() throws -> [RentalInspection] {

        let request = RentalInspectionEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "endTime >= %@",
            Date() as NSDate
        )
        
        request.sortDescriptors = [
            NSSortDescriptor(
                key: "startTime",
                ascending: true
            )
        ]

        let entities = try context.fetch(request)

        var inspections: [RentalInspection] = []

        for entity in entities {

            if let id = entity.id,
               let startTime = entity.startTime,
               let endTime = entity.endTime,
               let propertyID = entity.rentalProperty?.id {

                let inspection = RentalInspection(
                    id: id,
                    rentalPropertyID: propertyID,
                    startTime: startTime,
                    endTime: endTime
                )

                inspections.append(inspection)
            }
        }

        return inspections
    }
    func fetchInspections(
        for rentalPropertyID: UUID
    ) throws -> [RentalInspection] {

        let request = RentalInspectionEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "rentalProperty.id == %@",
            rentalPropertyID as CVarArg
        )

        let entities = try context.fetch(request)

        var inspections: [RentalInspection] = []

        for entity in entities {

            if let id = entity.id,
               let startTime = entity.startTime,
               let endTime = entity.endTime,
               let propertyID = entity.rentalProperty?.id {

                let inspection = RentalInspection(
                    id: id,
                    rentalPropertyID: propertyID,
                    startTime: startTime,
                    endTime: endTime
                )

                inspections.append(inspection)
            }
        }

        return inspections
    }
    func fetchObservations(
        for inspectionID: UUID
    ) throws -> [InspectionObservation] {

        let request = InspectionObservationEntity.fetchRequest()

        request.predicate = NSPredicate(
            format: "inspection.id == %@",
            inspectionID as CVarArg
        )

        let entities = try context.fetch(request)

        var observations: [InspectionObservation] = []

        for entity in entities {

            if let id = entity.id,
               let inspectionID = entity.inspection?.id,
               let criterionValue = entity.criterion,
               let statusValue = entity.status,
               let notes = entity.notes,
               let criterion = InspectionCriterion(
                    rawValue: criterionValue
               ),
               let status = ObservationStatus(
                    rawValue: statusValue
               ) {

                let observation = InspectionObservation(
                    id: id,
                    inspectionID: inspectionID,
                    criterion: criterion,
                    status: status,
                    notes: notes
                )

                observations.append(observation)
            }
        }

        return observations
    }
}
