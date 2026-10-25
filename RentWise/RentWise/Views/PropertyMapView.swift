
import SwiftUI
import MapKit

struct PropertyMapView: View {

    let properties: [RentalProperty]

    @State private var pins: [PropertyMapPin] = []
    @State private var isLoading = false

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: -33.8688,
                longitude: 151.2093
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.1,
                longitudeDelta: 0.1
            )
        )
    )

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(pins) { pin in
                Marker(
                    pin.property.address,
                    coordinate: pin.coordinate
                )
            }
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if isLoading {
                ProgressView("Loading property locations...")
                    .padding()
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .padding()
            }
        }
        .task(id: properties.map { "\($0.id)-\($0.address)" }) {
            await loadPropertyLocations()
        }
    }

    @MainActor
    private func loadPropertyLocations() async {

        isLoading = true
        defer { isLoading = false }

        let geocodingService = PropertyGeocodingService()
        var loadedPins: [PropertyMapPin] = []

        for property in properties {

            if Task.isCancelled {
                return
            }

            do {
                if let coordinate = try await geocodingService.coordinate(
                    for: property.address
                ) {
                    loadedPins.append(
                        PropertyMapPin(
                            property: property,
                            coordinate: coordinate
                        )
                    )
                }
            } catch {
                print("Could not find location for \(property.address): \(error)")
            }
        }

        if Task.isCancelled {
            return
        }

        pins = loadedPins

        if let firstPin = loadedPins.first {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: firstPin.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.05,
                        longitudeDelta: 0.05
                    )
                )
            )
        }
    }
}

struct PropertyMapPin: Identifiable {
    let property: RentalProperty
    let coordinate: CLLocationCoordinate2D

    var id: UUID {
        property.id
    }
}

#Preview {
    NavigationStack {
        PropertyMapView(properties: [
            RentalProperty(
                address: "1 Martin Place, Sydney NSW 2000",
                weeklyRent: 650
            ),
            RentalProperty(
                address: "483 George Street, Sydney NSW 2000",
                weeklyRent: 750
            )
        ])
    }
}
