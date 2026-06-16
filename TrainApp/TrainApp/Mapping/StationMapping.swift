import Foundation

/// Maps station IDs to names/codes for display.
struct StationMapping {
    private let stationsById: [Int: Station]

    init(stations: [Station]) {
        self.stationsById = Dictionary(uniqueKeysWithValues: stations.map { ($0.id, $0) })
    }

    func station(for id: Int) -> Station? {
        stationsById[id]
    }

    func name(for id: Int) -> String {
        stationsById[id]?.name ?? "Station \(id)"
    }

    func code(for id: Int) -> String {
        stationsById[id]?.code ?? "?"
    }

    /// Format a path of station IDs as "A → B → C".
    func formatPath(stationIds: [Int]) -> String {
        stationIds.map { name(for: $0) }.joined(separator: " → ")
    }
}
