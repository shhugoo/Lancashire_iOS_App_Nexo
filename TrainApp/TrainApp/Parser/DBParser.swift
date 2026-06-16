import Foundation

/// Loads stations and route segments from the database into an in-memory graph and station list.
final class DBParser {
    private let db: DatabaseManager

    init(databaseManager: DatabaseManager) {
        self.db = databaseManager
    }

    /// Load all stations from the database.
    func loadStations() throws -> [Station] {
        try db.fetchStations()
    }

    /// Load all route segments from the database.
    func loadRouteSegments() throws -> [RouteSegment] {
        try db.fetchRouteSegments()
    }

    /// Build a RouteGraph from segments. Use duration_mins as edge weight (for Dijkstra by time).
    func buildGraph(segments: [RouteSegment], weightByDuration: Bool = true) -> RouteGraph {
        var graph = RouteGraph()
        for seg in segments {
        let weight = weightByDuration ? Double(seg.durationMins) : seg.distanceKm
            graph.addEdge(from: seg.fromStationId, to: seg.toStationId, weight: weight)
        }
        return graph
    }

    /// One-shot: load stations, segments, and build graph. Returns (stations, graph).
    func loadStationsAndGraph(weightByDuration: Bool = true) throws -> (stations: [Station], graph: RouteGraph) {
        let stations = try loadStations()
        let segments = try loadRouteSegments()
        let graph = buildGraph(segments: segments, weightByDuration: weightByDuration)
        return (stations, graph)
    }
}
