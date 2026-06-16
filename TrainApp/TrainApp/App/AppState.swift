import Foundation

/// Holds Phase 1 services: DB, parser, pathfinding, mapping. Initialize once at launch.
final class AppState: ObservableObject {
    let database: DatabaseManager
    let parser: DBParser
    let pathfinding: PathfindingService
    let networkService: NetworkService
    @Published private(set) var mapping: StationMapping
    @Published private(set) var stations: [Station] = []
    @Published private(set) var mapStops: [Station] = []
    @Published var errorMessage: String?

    init() {
        database = DatabaseManager()
        parser = DBParser(databaseManager: database)
        pathfinding = PathfindingService(graph: RouteGraph())
        networkService = NetworkService()
        mapping = StationMapping(stations: [])
    }

    /// Call on app launch: init DB from schema/seed, load stations and graph.
    func initialize() {
        do {
            try database.initializeIfNeeded(schemaSQL: ResourceLoader.loadSchema(), seedSQL: ResourceLoader.loadSeed())
            let (stations, graph) = try parser.loadStationsAndGraph(weightByDuration: true)
            self.stations = stations
            self.mapping = StationMapping(stations: stations)
            pathfinding.replaceGraph(graph)
            Task {
                await refreshMapStopsFromAPI()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var mapStations: [Station] {
        if !mapStops.isEmpty {
            return mapStops
        }
        return stations.filter { $0.latitude != nil && $0.longitude != nil }
    }

    @MainActor
    func refreshMapStopsFromAPI() async {
        do {
            let stops = try await networkService.fetchStops()
            mapStops = stops
            if !stops.isEmpty {
                // Clear a stale API error after a successful refresh.
                errorMessage = nil
            }
        } catch {
            // Keep DB stations as fallback; expose API issue for visibility.
            if mapStops.isEmpty {
                errorMessage = "Map stops API fallback failed: \(error.localizedDescription)"
            }
            print("[AppState] Map stops API refresh failed; using DB fallback. Error: \(error.localizedDescription)")
        }
    }

    func findRoute(originId: Int, destinationId: Int, useBFS: Bool) -> RouteResult? {
        if useBFS {
            return pathfinding.findPathBFS(from: originId, to: destinationId)
        } else {
            return pathfinding.findPathDijkstra(from: originId, to: destinationId, useDuration: true)
        }
    }
}
