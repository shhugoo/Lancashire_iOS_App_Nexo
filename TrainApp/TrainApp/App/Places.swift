import SwiftUI
import MapKit

// MARK: - Models

struct Place: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let latitude: Double
    let longitude: Double
    let address: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(id: UUID = UUID(), name: String, category: String, latitude: Double, longitude: Double, address: String = "") {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
    }
}

struct PlaceCategory: Identifiable {
    let id: String
    let name: String
}

enum PlacesSearchMode {
    case keyword
    case nearby
}

// MARK: - Service

final class PlacesService: ObservableObject {

    func fetchCategories() async -> [PlaceCategory] {
        return [
            PlaceCategory(id: "all", name: "All"),
            PlaceCategory(id: "food", name: "Food & Drink"),
            PlaceCategory(id: "shopping", name: "Shopping"),
            PlaceCategory(id: "culture", name: "Culture"),
            PlaceCategory(id: "outdoors", name: "Outdoors"),
            PlaceCategory(id: "transport", name: "Transport")
        ]
    }

    func search(query: String, near coordinate: CLLocationCoordinate2D?, category: String) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        if query.isEmpty {
            request.naturalLanguageQuery = category == "all" ? "points of interest" : category
        } else {
            request.naturalLanguageQuery = query
        }
        if let coord = coordinate {
            let region = MKCoordinateRegion(center: coord, latitudinalMeters: 10_000, longitudinalMeters: 10_000)
            request.region = region
        }
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.map { item in
            Place(
                name: item.name ?? "Unknown",
                category: item.pointOfInterestCategory?.rawValue ?? category,
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude,
                address: item.placemark.thoroughfare ?? ""
            )
        }
    }
}

// MARK: - Detail Sheet

struct PlaceDetailSheet: View {
    let place: Place
    let usesLightPalette: Bool
    let isAlreadySaved: Bool
    let onDirections: () -> Void
    let onAddStop: () -> Void
    let onPlanViaHere: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var bgColor: Color { usesLightPalette ? Color(.systemGroupedBackground) : Color(red: 0.05, green: 0.10, blue: 0.18) }
    private var primaryText: Color { usesLightPalette ? .black : .white }
    private var secondaryText: Color { usesLightPalette ? Color.black.opacity(0.6) : Color.white.opacity(0.6) }

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(place.name)
                            .font(.title2.bold())
                            .foregroundStyle(primaryText)
                        if !place.address.isEmpty {
                            Text(place.address)
                                .font(.subheadline)
                                .foregroundStyle(secondaryText)
                        }
                        Text(place.category.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.18))
                            .foregroundStyle(Color.blue)
                            .clipShape(Capsule())
                    }

                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: place.coordinate,
                        latitudinalMeters: 800,
                        longitudinalMeters: 800
                    ))) {
                        Marker(place.name, coordinate: place.coordinate)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(spacing: 12) {
                        Button(action: onDirections) {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: onAddStop) {
                            Label(isAlreadySaved ? "Remove Saved Stop" : "Save as Stop", systemImage: isAlreadySaved ? "bookmark.slash" : "bookmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button(action: onPlanViaHere) {
                            Label("Plan Journey via Here", systemImage: "map")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Place Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(primaryText)
                }
            }
        }
    }
}
