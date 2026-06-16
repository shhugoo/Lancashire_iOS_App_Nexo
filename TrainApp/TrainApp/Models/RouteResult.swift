import Foundation

/// A single path between two stations (list of station IDs in order).
struct RouteResult {
    /// Station IDs from origin to destination (inclusive).
    let stationIds: [Int]
    /// Total duration in minutes (Dijkstra) or nil (BFS).
    let totalDurationMins: Int?
    /// Total distance in km (Dijkstra) or nil (BFS).
    let totalDistanceKm: Double?
    /// Number of segments (legs).
    var segmentCount: Int { max(0, stationIds.count - 1) }
}
