import Foundation

/// A directed edge between two stations (for pathfinding graph).
struct RouteSegment: Identifiable {
    let id: Int
    let fromStationId: Int
    let toStationId: Int
    let distanceKm: Double
    let durationMins: Int

    init(id: Int, fromStationId: Int, toStationId: Int, distanceKm: Double, durationMins: Int) {
        self.id = id
        self.fromStationId = fromStationId
        self.toStationId = toStationId
        self.distanceKm = distanceKm
        self.durationMins = durationMins
    }
}
