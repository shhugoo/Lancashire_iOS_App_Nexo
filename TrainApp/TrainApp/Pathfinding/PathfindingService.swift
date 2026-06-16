import Foundation

/// Pathfinding: BFS (fewest segments) and Dijkstra (shortest by time or distance).
final class PathfindingService {
    private var graph: RouteGraph

    init(graph: RouteGraph = RouteGraph()) {
        self.graph = graph
    }

    func replaceGraph(_ newGraph: RouteGraph) {
        graph = newGraph
    }

    /// BFS: returns one path with fewest segments (unweighted).
    func findPathBFS(from originId: Int, to destinationId: Int) -> RouteResult? {
        guard originId != destinationId else {
            return RouteResult(stationIds: [originId], totalDurationMins: nil, totalDistanceKm: nil)
        }
        var visited = Set<Int>()
        var queue: [(id: Int, path: [Int])] = [(originId, [originId])]
        visited.insert(originId)
        while !queue.isEmpty {
            let (node, path) = queue.removeFirst()
            for (neighbour, _) in graph.neighbours(of: node) {
                if neighbour == destinationId {
                    return RouteResult(stationIds: path + [neighbour], totalDurationMins: nil, totalDistanceKm: nil)
                }
                if !visited.contains(neighbour) {
                    visited.insert(neighbour)
                    queue.append((neighbour, path + [neighbour]))
                }
            }
        }
        return nil
    }

    /// Dijkstra: returns one shortest path by the given weight (e.g. duration or distance).
    func findPathDijkstra(from originId: Int, to destinationId: Int, useDuration: Bool = true) -> RouteResult? {
        guard originId != destinationId else {
            return RouteResult(stationIds: [originId], totalDurationMins: 0, totalDistanceKm: 0)
        }
        var dist: [Int: Double] = [originId: 0]
        var prev: [Int: Int] = [:]
        var heap: [(Double, Int)] = [(0, originId)]
        while !heap.isEmpty {
            heap.sort { $0.0 < $1.0 }
            let (d, node) = heap.removeFirst()
            if node == destinationId {
                var path = [destinationId]
                var cur = destinationId
                while let p = prev[cur] {
                    path.append(p)
                    cur = p
                }
                path.reverse()
                let totalWeight = dist[destinationId] ?? 0
                if useDuration {
                    return RouteResult(stationIds: path, totalDurationMins: Int(totalWeight), totalDistanceKm: nil)
                } else {
                    return RouteResult(stationIds: path, totalDurationMins: nil, totalDistanceKm: totalWeight)
                }
            }
            for (neighbour, weight) in graph.neighbours(of: node) {
                let alt = d + weight
                if alt < (dist[neighbour] ?? .infinity) {
                    dist[neighbour] = alt
                    prev[neighbour] = node
                    heap.append((alt, neighbour))
                }
            }
        }
        return nil
    }
}
