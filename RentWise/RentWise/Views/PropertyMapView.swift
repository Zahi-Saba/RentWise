
import SwiftUI
import MapKit

struct PropertyMapView: View {

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
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PropertyMapView()
    }
}
