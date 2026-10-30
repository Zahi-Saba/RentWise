
//
//  RentWiseViewModel.swift
//  RentWise
//
//  Created by Zahi Saba on 30/9/2026.
//

import Foundation
import Combine
import WidgetKit
import LinkPresentation

class RentWiseViewModel: ObservableObject {
    @Published private(set) var comparison: PropertyComparison?
    @Published private(set) var comparisonError = ""
    @Published var isImportingListings = false
    @Published var importMessage = ""
    let listingPreviewService = ListingPreviewService()
    private var attemptedListingImports: Set<String> = []
    private var attemptedSharedPayloads: Set<UUID> = []

    @Published var rentalProperties: [RentalProperty] = []
    @Published var inspections: [RentalInspection] = []
    @Published var observations: [InspectionObservation] = []
    @Published var errorMessage: String = ""
    @Published var propertyInspections: [RentalInspection] = []
    @Published var inspectionHistory: [RentalInspection] = []
    @Published var latestPropertyInspection: RentalInspection?
    @Published var latestPropertyObservations: [InspectionObservation] = []
    private let repository: RentalPropertyRepository

    private let saveRentalPropertyUseCase: SaveRentalPropertyUseCase
    private let deleteRentalPropertyUseCase: DeleteRentalPropertyUseCase
    private let scheduleInspectionUseCase: ScheduleInspectionUseCase

    private let recordInspectionObservationUseCase: RecordInspectionObservationUseCase

    private let updateInspectionObservationUseCase:
        UpdateInspectionObservationUseCase

    init(repository: RentalPropertyRepository) {

        self.repository = repository

        self.saveRentalPropertyUseCase = SaveRentalPropertyUseCase(
            repository: repository
        )

        self.scheduleInspectionUseCase = ScheduleInspectionUseCase(
            repository: repository
        )

        self.recordInspectionObservationUseCase =
            RecordInspectionObservationUseCase(
                repository: repository
            )

        deleteRentalPropertyUseCase =
            DeleteRentalPropertyUseCase(
                repository: repository
            )

        self.updateInspectionObservationUseCase =
            UpdateInspectionObservationUseCase(
                repository: repository
            )
    }

    func prepareRooms(for propertyID: UUID) {
        do {
            let property = try PrepareRoomsUseCase(repository: repository).execute(propertyID: propertyID)
            publishRoomChanges(property)
        } catch { errorMessage = error.localizedDescription }
    }

    func setRoomInspected(propertyID: UUID, roomID: UUID, checked: Bool) {
        do {
            let property = try SetRoomInspectedUseCase(repository: repository)
                .execute(propertyID: propertyID, roomID: roomID, checked: checked)
            publishRoomChanges(property)
        } catch { errorMessage = error.localizedDescription }
    }

    func recordRoomDefect(propertyID: UUID, roomID: UUID, description: String, severity: DefectSeverity, photo: Data? = nil) -> Bool {
        do {
            let property = try RecordRoomDefectUseCase(repository: repository)
                .execute(propertyID: propertyID, roomID: roomID, description: description, severity: severity, photo: photo)
            publishRoomChanges(property)
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func deleteRoomDefect(propertyID: UUID, roomID: UUID, defectID: UUID) {
        do {
            let property = try DeleteRoomDefectUseCase(repository: repository)
                .execute(propertyID: propertyID, roomID: roomID, defectID: defectID)
            publishRoomChanges(property)
        } catch { errorMessage = error.localizedDescription }
    }

    private func publishRoomChanges(_ property: RentalProperty) {
        if let index = rentalProperties.firstIndex(where: { $0.id == property.id }) {
            rentalProperties[index] = property
        } else { rentalProperties.append(property) }
        errorMessage = ""
    }

    func clearComparison() {
        comparison = nil
        comparisonError = ""
    }

    func compareProperties(firstID: UUID, secondID: UUID) {
        clearComparison()

        do {
            comparison = try ComparePropertiesUseCase(repository: repository)
                .execute(firstID: firstID, secondID: secondID)
        } catch let error as ComparePropertiesError {
            comparisonError = error.localizedDescription
        } catch {
            comparisonError = "The comparison could not be loaded. Please try again."
        }
    }

    func loadRentalProperties() {

        do {
            rentalProperties =
                try repository.fetchRentalProperties()

            errorMessage = ""

        } catch {
            errorMessage =
                "Saved rental properties could not be loaded."
        }
    }

    func loadUpcomingInspections() {

        do {
            inspections =
                try repository.fetchUpcomingInspections()

            updateWidget()
            errorMessage = ""

        } catch {
            errorMessage =
                "Upcoming inspections could not be loaded."
        }
    }

    func loadObservations(
        for inspectionID: UUID
    ) {

        do {
            observations =
                try repository.fetchObservations(
                    for: inspectionID
                )

            errorMessage = ""

        } catch {
            errorMessage =
                "Inspection observations could not be loaded."
        }
    }

    func propertyAddress(
        for rentalPropertyID: UUID
    ) -> String {

        for property in rentalProperties {
            if property.id == rentalPropertyID {
                return property.address
            }
        }

        return "Unknown Property"
    }

    func addRentalProperty(
        address: String,
        weeklyRent: Double
    ) {

        do {
            let property =
                try saveRentalPropertyUseCase.execute(
                    address: address,
                    weeklyRent: weeklyRent
                )

            rentalProperties.append(property)
            errorMessage = ""

        } catch SaveRentalPropertyError.missingAddress {
            errorMessage =
                "Please enter the property address."

        } catch SaveRentalPropertyError.invalidWeeklyRent {
            errorMessage =
                "Weekly rent must be greater than $0."

        } catch {
            errorMessage =
                "The property could not be saved. Please try again."
        }
    }

    // Updated to return the saved inspection for notifications
    @discardableResult
    func scheduleInspection(
        rentalPropertyID: UUID,
        startTime: Date,
        endTime: Date
    ) -> RentalInspection? {

        do {
            let inspection = try scheduleInspectionUseCase.execute(
                rentalPropertyID: rentalPropertyID,
                startTime: startTime,
                endTime: endTime
            )

            inspections.append(inspection)
            loadUpcomingInspections()

            errorMessage = ""
            return inspection

        } catch ScheduleInspectionError.invalidTime {
            errorMessage = "The inspection end time must be after the start time."

        } catch {
            errorMessage = "The inspection could not be scheduled. Please try again."
        }

        return nil
    }

    func loadPropertyDetails(for propertyID: UUID) {
        propertyInspections = []
        loadLatestInspectionNotes(for: propertyID)

        do {
            propertyInspections = try FetchPropertyInspectionsUseCase(
                repository: repository
            ).execute(propertyID: propertyID)
        } catch {
            errorMessage = "Property inspections could not be loaded."
        }
    }

    func loadLatestInspectionNotes(
        for rentalPropertyID: UUID
    ) {

        latestPropertyInspection = nil
        latestPropertyObservations = []

        do {
            let propertyInspections =
                try repository.fetchInspections(
                    for: rentalPropertyID
                )

            var selectedInspection: RentalInspection?
            var selectedObservations: [InspectionObservation] = []

            for inspection in propertyInspections {

                let savedObservations =
                    try repository.fetchObservations(
                        for: inspection.id
                    )

                if !savedObservations.isEmpty {

                    if let currentInspection = selectedInspection {

                        if inspection.startTime > currentInspection.startTime {
                            selectedInspection = inspection
                            selectedObservations = savedObservations
                        }

                    } else {
                        selectedInspection = inspection
                        selectedObservations = savedObservations
                    }
                }
            }

            latestPropertyInspection = selectedInspection
            latestPropertyObservations = selectedObservations
            errorMessage = ""

        } catch {
            errorMessage =
                "Inspection notes could not be loaded."
        }
    }

    func loadInspectionHistory() {

        do {
            let properties = try repository.fetchRentalProperties()

            var pastInspections: [RentalInspection] = []

            for property in properties {

                let propertyInspections =
                    try repository.fetchInspections(
                        for: property.id
                    )

                for inspection in propertyInspections {

                    if inspection.endTime < Date() {
                        pastInspections.append(inspection)
                    }
                }
            }

            inspectionHistory = pastInspections.sorted {
                $0.startTime > $1.startTime
            }

            errorMessage = ""

        } catch {
            errorMessage =
                "Inspection history could not be loaded."
        }
    }

    
    func deleteInspection(_ inspection: RentalInspection) {
        do {
            try DeleteInspectionUseCase(repository: repository).execute(inspection: inspection)
            InspectionNotificationService().cancelReminders(for: [inspection])
            observations.removeAll { $0.inspectionID == inspection.id }
            inspectionHistory.removeAll { $0.id == inspection.id }
            clearComparison()
            loadPropertyDetails(for: inspection.rentalPropertyID)
            loadUpcomingInspections() // Also refreshes the widget snapshot and timeline.
        } catch {
            errorMessage = "The inspection could not be deleted. Please try again."
        }
    }

    func deleteRentalProperty(_ property: RentalProperty) {

        do {
            let propertyInspections = try repository.fetchInspections(
                for: property.id
            )

            try deleteRentalPropertyUseCase.execute(
                property: property
            )

            let notificationService = InspectionNotificationService()
            notificationService.cancelReminders(
                for: propertyInspections
            )

            loadRentalProperties()
            loadUpcomingInspections()

            errorMessage = ""

        } catch DeleteRentalPropertyError.rentalPropertyNotFound {
            errorMessage = "This rental property could not be found."

        } catch {
            errorMessage = "The rental property could not be deleted."
        }
    }


    func recordObservation(
        inspectionID: UUID,
        criterion: InspectionCriterion,
        status: ObservationStatus,
        notes: String
    ) {

        do {
            let observation =
                try recordInspectionObservationUseCase.execute(
                    inspectionID: inspectionID,
                    criterion: criterion,
                    status: status,
                    notes: notes
                )

            observations.append(observation)
            errorMessage = ""

        } catch RecordInspectionObservationError.missingNotes {
            errorMessage =
                "Please add a note about what you observed."

        } catch RecordInspectionObservationError.criterionAlreadyRecorded {
            errorMessage =
                "This inspection item has already been recorded."

        } catch {
            errorMessage =
                "The observation could not be saved. Please try again."
        }
    }

    func updateObservation(
        observation: InspectionObservation,
        status: ObservationStatus,
        notes: String
    ) {

        do {
            let updatedObservation =
                try updateInspectionObservationUseCase.execute(
                    observation: observation,
                    status: status,
                    notes: notes
                )

            for index in observations.indices {

                if observations[index].id == updatedObservation.id {
                    observations[index] = updatedObservation
                }
            }

            errorMessage = ""

        } catch UpdateInspectionObservationError.missingNotes {
            errorMessage =
                "Please add a note about what you observed."

        } catch UpdateInspectionObservationError.observationNotFound {
            errorMessage =
                "This inspection observation could not be found."

        } catch {
            errorMessage =
                "The observation could not be updated. Please try again."
        }
    }

    private func updateWidget() {

        var sharedInspections: [SharedInspection] = []

        for inspection in inspections {

            let sharedInspection = SharedInspection(
                address: propertyAddress(
                    for: inspection.rentalPropertyID
                ),
                startTime: inspection.startTime,
                endTime: inspection.endTime
            )

            sharedInspections.append(sharedInspection)
        }

        SharedWidgetData.saveInspections(
            sharedInspections
        )

        WidgetCenter.shared.reloadTimelines(
            ofKind: SharedWidgetData.widgetKind
        )
    }

    func importSharedListings() async {
        guard !isImportingListings else { return }

        isImportingListings = true
        importMessage = ""
        defer { isImportingListings = false }

        let useCase = ImportSharedPropertyUseCase(repository: repository)

        do {
            for (file, listing) in try SharedRentalLinkData.pendingListings() {

                guard attemptedSharedPayloads.insert(listing.id).inserted else {
                    continue
                }

                do {
                    // Safari already supplied the title and price: save immediately.
                    _ = try useCase.execute(
                        link: listing.url,
                        title: listing.title,
                        weeklyRent: listing.weeklyRent
                    )

                    try SharedRentalLinkData.acknowledgeListing(file)
                    loadRentalProperties()

                } catch {
                    importMessage = "A shared listing could not be saved. Pull down to retry."
                }
            }

        } catch {
            importMessage = "Shared listings could not be read. Check App Group signing or pull down to retry."
        }

        // Import any URL-only shares queued by the previous extension version.
        for link in SharedRentalLinkData.loadLinks()
        where !attemptedListingImports.contains(link) {

            attemptedListingImports.insert(link)

            do {
                let url = try ImportSharedPropertyUseCase.validatedURL(link)
                let metadata = await listingPreviewService.metadata(for: url)

                _ = try useCase.execute(
                    link: link,
                    title: metadata?.title
                )

                SharedRentalLinkData.removeLink(link)
                loadRentalProperties()

            } catch {
                importMessage = "A shared listing could not be saved. Pull down to retry."
            }
        }
    }

    func refreshShortlist() async {
        loadRentalProperties()
        loadUpcomingInspections()
        await importSharedListings()
    }

    func retrySharedImports() async {
        guard !isImportingListings else { return }

        attemptedListingImports.removeAll()
        attemptedSharedPayloads.removeAll()
        await refreshShortlist()
    }

    func importListingURL(_ text: String) async -> Bool {
        importMessage = ""

        do {
            let url = try ImportSharedPropertyUseCase.validatedURL(text)
            let metadata = await listingPreviewService.metadata(for: url)

            _ = try ImportSharedPropertyUseCase(
                repository: repository
            ).execute(
                link: text,
                title: metadata?.title
            )

            loadRentalProperties()
            return true

        } catch {
            importMessage = error.localizedDescription
            return false
        }
    }
}
