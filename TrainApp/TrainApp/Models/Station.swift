import Foundation

/// A train station (node in the route graph).
struct Station: Identifiable, Hashable {
    let id: Int
    let name: String
    let code: String
    let latitude: Double?
    let longitude: Double?

    init(id: Int, name: String, code: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.code = code
        self.latitude = latitude
        self.longitude = longitude
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Station, rhs: Station) -> Bool { lhs.id == rhs.id }
}
