
import Foundation
import MapKit

class PropertyGeocodingService {

    func coordinate(for address: String) async throws -> CLLocationCoordinate2D? {

        let cleanedAddress = address.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard let request = MKGeocodingRequest(
            addressString: cleanedAddress
        ) else {
            return nil
        }

        let results = try await request.mapItems

        guard let firstResult = results.first else {
            return nil
        }

        return firstResult.location.coordinate
    }
}
