import Foundation
import CoreData
import JavaScriptCore
import Testing
@testable import RentWise

@MainActor
struct SharedRentTests {
    @Test func resharingUpdatesPriceWithoutDuplicatingProperty() throws {
        let repository = MockRentalPropertyRepository()
        let useCase = ImportSharedPropertyUseCase(repository: repository)
        let first = try useCase.execute(link: "https://example.com/1", title: "Apartment")
        let updated = try useCase.execute(link: "https://example.com/1#photos", title: "Other title", weeklyRent: 610)
        #expect(updated.id == first.id)
        #expect(updated.weeklyRent == 610)
        #expect(updated.address == first.address)
        #expect(repository.savedProperties.count == 1)
    }
    @Test func absentOrInvalidRentDoesNotEraseExistingRent() throws {
        let repository = MockRentalPropertyRepository()
        let useCase = ImportSharedPropertyUseCase(repository: repository)
        _ = try useCase.execute(link: "https://example.com/1", title: "Apartment", weeklyRent: 610)
        for price in [nil, -1, 0, Double.infinity, Double.nan] as [Double?] {
            #expect(try useCase.execute(link: "https://example.com/1", title: nil, weeklyRent: price).weeklyRent == 610)
        }
    }
    @Test func priceUpdatePreservesCoreDataInspectionAndObservation() throws {
        let container = NSPersistentContainer(name: "RentWiseModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        var failure: Error?
        container.loadPersistentStores { _, error in failure = error }
        if let failure { throw failure }
        let repository = CoreDataRentalPropertyRepository(context: container.viewContext)
        let useCase = ImportSharedPropertyUseCase(repository: repository)
        let property = try useCase.execute(link: "https://example.com/1", title: "Apartment")
        let inspection = try ScheduleInspectionUseCase(repository: repository).execute(rentalPropertyID: property.id, startTime: Date(), endTime: Date().addingTimeInterval(1800))
        _ = try RecordInspectionObservationUseCase(repository: repository).execute(inspectionID: inspection.id, criterion: .noise, status: .meetsNeeds, notes: "Quiet")
        _ = try useCase.execute(link: "https://example.com/1", title: nil, weeklyRent: 610)
        container.viewContext.reset()
        #expect(try repository.fetchRentalProperties().count == 1)
        #expect(try repository.fetchRentalProperties().first?.weeklyRent == 610)
        #expect(try repository.fetchInspections(for: property.id).first?.id == inspection.id)
        #expect(try repository.fetchObservations(for: inspection.id).first?.notes == "Quiet")
    }
    @Test func atomicInboxPreservesOtherSharesWhenAcknowledgingOne() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let first = SharedListing(url: "https://example.com/1", title: "A", weeklyRent: 610)
        let second = SharedListing(url: "https://example.com/2", title: "B", weeklyRent: 720)
        try SharedRentalLinkData.saveListing(first, directory: folder)
        try SharedRentalLinkData.saveListing(second, directory: folder)
        let pending = try SharedRentalLinkData.pendingListings(directory: folder)
        #expect(pending.count == 2)
        let item = try #require(pending.first { $0.1.id == first.id })
        #expect(item.1.weeklyRent == 610)
        try SharedRentalLinkData.acknowledgeListing(item.0)
        #expect(try SharedRentalLinkData.pendingListings(directory: folder).first?.1.id == second.id)
    }
    @Test func safariExtractorIsBundledAndReadsWeeklyRent() throws {
        let bundleURL = try #require(Bundle.main.builtInPlugInsURL).appendingPathComponent("RentWiseShare.appex")
        let script = try String(contentsOf: bundleURL.appendingPathComponent("ListingPage.js"), encoding: .utf8)
        let context = try #require(JSContext())
        context.evaluateScript(script)
        context.evaluateScript("""
        function page(text, primary) {
          return {
            querySelectorAll: function(s) { return s === '[data-testid="property-price"]' && primary ? [{innerText:primary}] : []; },
            querySelector: function() { return {innerText:text}; }, body:{innerText:text}
          };
        }
        """)
        #expect(context.evaluateScript("listingWeeklyRent(page('Studio/185-211 Broadway, Ultimo NSW 2007: $610 per week'))")?.toDouble() == 610)
        #expect(context.evaluateScript("listingWeeklyRent(page('$1,250 pw'))")?.toDouble() == 1250)
        #expect(context.evaluateScript("listingWeeklyRent(page('$610 per week. Similar properties: $900 per week'))")?.toDouble() == 610)
        #expect(context.evaluateScript("listingWeeklyRent(page('$2440 bond'))")?.isNull == true)
        #expect(context.evaluateScript("listingWeeklyRent(page('$610 per week and $900 per week'))")?.isNull == true)
        #expect(context.evaluateScript("listingWeeklyRent(page('$610 per week and $900 per week', '$610 per week'))")?.toDouble() == 610)
        #expect(context.exception == nil)
    }
}
