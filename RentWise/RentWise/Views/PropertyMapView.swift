
import SwiftUI
import MapKit

struct PropertyMapView: View {

    let properties: [RentalProperty]

    @State private var pins: [PropertyMapPin] = []
    @State private var selectedPropertyID: UUID?
    @State private var isLoading = false
    @State private var failedAddressCount = 0

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

    private var selectedPin: PropertyMapPin? {
        pins.first { $0.id == selectedPropertyID }
    }

    var body: some View {
        Map(
            position: $cameraPosition,
            selection: $selectedPropertyID
        ) {
            ForEach(pins) { pin in
                Marker(
                    pin.property.address,
                    coordinate: pin.coordinate
                )
                .tag(pin.id)
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
            } else if properties.isEmpty {
                statusMessage(
                    "No saved properties to display.",
                    icon: "mappin.slash"
                )
            } else if pins.isEmpty {
                statusMessage(
                    "Could not find any property locations.",
                    icon: "exclamationmark.triangle"
                )
            } else if failedAddressCount > 0 {
                statusMessage(
                    "\(failedAddressCount) property location(s) could not be found.",
                    icon: "exclamationmark.triangle"
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let selectedPin {
                propertyCard(for: selectedPin)
            }
        }
        .task(id: properties.map { "\($0.id)-\($0.address)" }) {
            await loadPropertyLocations()
        }
    }

    private func propertyCard(
        for pin: PropertyMapPin
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(pin.property.address)
                    .font(.headline)

                Spacer()

                Button {
                    selectedPropertyID = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close property details")
            }

            Text(pin.property.rentLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func statusMessage(
        _ message: String,
        icon: String
    ) -> some View {
        Label(message, systemImage: icon)
            .font(.subheadline)
            .padding()
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .padding()
    }

    @MainActor
    private func loadPropertyLocations() async {
        pins = []
        selectedPropertyID = nil
        failedAddressCount = 0

        guard !properties.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        defer { isLoading = false }

        let geocodingService = PropertyGeocodingService()
        var loadedPins: [PropertyMapPin] = []
        var failedCount = 0

        for property in properties {
            if Task.isCancelled {
                return
            }

            let address = property.address.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if address.isEmpty {
                failedCount += 1
                continue
            }

            do {
                if let coordinate = try await geocodingService.coordinate(
                    for: address
                ) {
                    loadedPins.append(
                        PropertyMapPin(
                            property: property,
                            coordinate: coordinate
                        )
                    )
                } else {
                    failedCount += 1
                }
            } catch {
                if Task.isCancelled {
                    return
                }

                failedCount += 1
                print("Could not locate \(address): \(error)")
            }
        }

        if Task.isCancelled {
            return
        }

        pins = loadedPins
        failedAddressCount = failedCount

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
