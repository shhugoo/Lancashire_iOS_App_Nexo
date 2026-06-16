import Foundation

/// Directed graph for pathfinding: adjacency list with optional edge weight.
struct RouteGraph {
    /// Adjacency list: node id -> [(neighbour id, weight)]
    /// Weight is used by Dijkstra (e.g. duration_mins or distance_km).
    private(set) var adjacency: [Int: [(Int, Double)]]

    init() {
        self.adjacency = [:]
    }

    mutating func addEdge(from: Int, to: Int, weight: Double) {
        if adjacency[from] == nil { adjacency[from] = [] }
        adjacency[from]?.append((to, weight))
    }

    func neighbours(of node: Int) -> [(Int, Double)] {
        adjacency[node] ?? []
    }

    /// All node IDs that appear as from or to in the graph.
    func allNodeIds() -> Set<Int> {
        var ids = Set<Int>()
        for (from, edges) in adjacency {
            ids.insert(from)
            for (to, _) in edges { ids.insert(to) }
        }
        return ids
    }
}
