import Foundation
import Testing
import UIKit
import PDFKit
@testable import RentWise

@MainActor
struct RoomReportTests {
    private func fixture() -> (MockRentalPropertyRepository, RentalProperty, RentalInspection) {
        let repository = MockRentalPropertyRepository()
        let property = RentalProperty(address: "12 George Street, Sydney", weeklyRent: 650)
        let inspection = RentalInspection(rentalPropertyID: property.id, startTime: Date(), endTime: Date().addingTimeInterval(1800))
        repository.savedProperties = [property]
        repository.savedInspections = [inspection]
        return (repository, property, inspection)
    }

    @Test func checkedRoomOrDefectAllowsReportWithoutObservations() throws {
        let (repository, property, inspection) = fixture()
        for room in [InspectionRoom(name: "Kitchen", checked: true),
                     InspectionRoom(name: "Bathroom", defects: [RoomDefect(description: "Leak", severity: .major)])] {
            repository.savedProperties[0].rooms = [room]
            let option = try #require(ListInspectionReportOptionsUseCase(repository: repository).execute().first)
            #expect(option.canGenerateReport)
            let report = try CreateInspectionConditionReportUseCase(repository: repository)
                .execute(propertyID: property.id, inspectionID: inspection.id)
            #expect(report.observations.isEmpty)
            #expect(report.property.rooms == [room])
        }
    }

    @Test func untouchedRoomsDoNotCountAsFindings() throws {
        let (repository, property, inspection) = fixture()
        repository.savedProperties[0].rooms = InspectionRoom.standardRooms()
        #expect(try ListInspectionReportOptionsUseCase(repository: repository).execute().first?.canGenerateReport == false)
        #expect(throws: CreateInspectionConditionReportError.noFindings) {
            try CreateInspectionConditionReportUseCase(repository: repository).execute(propertyID: property.id, inspectionID: inspection.id)
        }
    }

    @Test func reportSnapshotPreservesPhotoAndDoesNotMixPropertyRooms() throws {
        let (repository, property, inspection) = fixture()
        let defect = RoomDefect(description: "Crack", severity: .moderate, photo: Data([1, 2]))
        repository.savedProperties[0].rooms = [InspectionRoom(name: "Kitchen", defects: [defect])]
        var other = RentalProperty(address: "Other", weeklyRent: 800)
        other.rooms = [InspectionRoom(name: "Bathroom", defects: [RoomDefect(description: "Other leak", severity: .major)])]
        repository.savedProperties.append(other)
        let report = try CreateInspectionConditionReportUseCase(repository: repository).execute(propertyID: property.id, inspectionID: inspection.id)
        repository.savedProperties[0].rooms = []
        #expect(report.property.rooms.count == 1)
        #expect(report.property.rooms[0].defects == [defect])
    }

    @Test func pdfIncludesAllRoomStatusesDefectsAndPhotosAcrossPages() throws {
        let (repository, property, inspection) = fixture()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 300)).image { context in
            UIColor.systemTeal.setFill(); context.fill(CGRect(x: 0, y: 0, width: 600, height: 300))
            ("DEFECT PHOTO TEST" as NSString).draw(at: CGPoint(x: 30, y: 100), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 30)])
        }
        let photo = try #require(image.jpegData(compressionQuality: 0.8))
        repository.savedProperties[0].rooms = [
            InspectionRoom(name: "Kitchen", checked: true, defects: [RoomDefect(description: "Cracked tile beside sink.", severity: .major, photo: photo)]),
            InspectionRoom(name: "Bathroom", defects: [RoomDefect(description: String(repeating: "Leak near the shower. ", count: 150), severity: .moderate, photo: photo)]),
            InspectionRoom(name: "Bedroom", checked: true),
            InspectionRoom(name: "Living Area", defects: [RoomDefect(description: "Final wall scratch", severity: .minor)])
        ]
        let report = try CreateInspectionConditionReportUseCase(repository: repository).execute(propertyID: property.id, inspectionID: inspection.id)
        let url = try InspectionReportPDFRenderer().render(report)
        let pdf = try #require(PDFDocument(url: url))
        let text = try #require(pdf.string)
        #expect(pdf.pageCount > 1)
        for expected in ["CURRENT ROOM FINDINGS", "Kitchen", "Bathroom", "Bedroom", "Living Area", "Major", "Moderate", "Minor", "Final wall scratch", "Not checked", "not a historical snapshot"] {
            #expect(text.contains(expected))
        }
        var imagePages = 0
        for index in 0..<pdf.pageCount {
            let page = try #require(pdf.page(at: index)?.pageRef)
            let dictionary = try #require(page.dictionary)
            var resources: CGPDFDictionaryRef?
            var objects: CGPDFDictionaryRef?
            if CGPDFDictionaryGetDictionary(dictionary, "Resources", &resources), let resources,
               CGPDFDictionaryGetDictionary(resources, "XObject", &objects), let objects,
               CGPDFDictionaryGetCount(objects) > 0 { imagePages += 1 }
        }
        #expect(imagePages >= 1)
        print("ROOM_REPORT_PREVIEW=\(url.path)")
    }
}
