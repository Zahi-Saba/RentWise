
import SwiftUI
import MapKit

struct PropertyMapView: View {

    let pins: [PropertyMapPin]

    init(pins: [PropertyMapPin] = []) {
        self.pins = pins
    }

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
        PropertyMapView(pins: [
            PropertyMapPin(
                property: RentalProperty(
                    address: "Sydney CBD",
                    weeklyRent: 650
                ),
                coordinate: CLLocationCoordinate2D(
                    latitude: -33.8731,
                    longitude: 151.2066
                )
            ),
            PropertyMapPin(
                property: RentalProperty(
                    address: "Central Station",
                    weeklyRent: 750
                ),
                coordinate: CLLocationCoordinate2D(
                    latitude: -33.8830,
                    longitude: 151.2065
                )
            )
        ])
    }
}
