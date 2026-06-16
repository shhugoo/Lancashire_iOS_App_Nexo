import Foundation

private struct StationsEnvelope: Decodable {
    let data: [StationsAPIStop]
}

private struct NaptanEnvelope: Decodable {
    let data: [NaptanAPIStop]
}

private struct StationsAPIStop: Decodable {
    let id: Int?
    let code: String?
    let atcoCode: String?
    let name: String?
    let commonName: String?
    let latitude: Double?
    let longitude: Double?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case atcoCode = "atco_code"
        case name
        case commonName = "common_name"
        case latitude
        case longitude
        case type
    }
}

private struct NaptanAPIStop: Decodable {
    let id: Int?
    let code: String?
    let atcoCode: String?
    let naptanCode: String?
    let name: String?
    let commonName: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case atcoCode = "atco_code"
        case naptanCode = "naptan_code"
        case name
        case commonName = "common_name"
        case latitude
        case longitude
    }
}

private struct StopCandidate {
    let name: String
    let code: String?
    let latitude: Double
    let longitude: Double
}

enum NetworkServiceError: LocalizedError {
    case badURL(path: String)
    case badStatus(path: String, statusCode: Int)
    case localhostPortConflict
    case primaryAndFallbackFailed(primary: String, fallback: String)
    case zeroValidStopsReturned

    var errorDescription: String? {
        switch self {
        case .badURL(let path):
            return "Invalid URL for endpoint: \(path)"
        case .badStatus(let path, let statusCode):
            return "Request to \(path) failed with status \(statusCode)"
        case .localhostPortConflict:
            return "Localhost:5000 is serving AirTunes (403). Backend is not on that port. Use http://127.0.0.1:5001."
        case .primaryAndFallbackFailed(let primary, let fallback):
            return "Primary endpoint failed (\(primary)); fallback endpoint failed (\(fallback))."
        case .zeroValidStopsReturned:
            return "Stops API returned zero valid coordinate stops."
        }
    }
}

final class NetworkService {
    // Configure this key in UserDefaults for real-device runs:
    // apiBaseURL = http://<your-mac-lan-ip>:5001
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        if let baseURL {
            self.baseURL = baseURL
        } else if let configured = UserDefaults.standard.string(forKey: "apiBaseURL"),
                  let url = URL(string: configured) {
            self.baseURL = url
        } else {
            self.baseURL = URL(string: "http://127.0.0.1:5001")!
        }
        self.session = session
    }

    func fetchStops(limit: Int = 2000) async throws -> [Station] {
        var primaryFailure: Error?

        do {
            let primaryStops = try await fetchStopsFromStationsEndpoint(limit: limit)
            if !primaryStops.isEmpty {
                print("[NetworkService] Using /api/stations bus stops: \(primaryStops.count)")
                return primaryStops
            }
            print("[NetworkService] Primary endpoint /api/stations returned zero valid coordinate stops.")
        } catch {
            primaryFailure = error
            print("[NetworkService] Primary endpoint failed (/api/stations?type=bus&limit=\(limit)): \(error.localizedDescription)")
        }

        do {
            let fallbackStops = try await fetchStopsFromNaptanEndpoint()
            if !fallbackStops.isEmpty {
                print("[NetworkService] Using fallback /api/naptan stops: \(fallbackStops.count)")
                return fallbackStops
            }
            print("[NetworkService] Fallback endpoint /api/naptan returned zero valid coordinate stops.")
            throw NetworkServiceError.zeroValidStopsReturned
        } catch {
            print("[NetworkService] Fallback endpoint failed (/api/naptan): \(error.localizedDescription)")
            if let primaryFailure {
                throw NetworkServiceError.primaryAndFallbackFailed(
                    primary: primaryFailure.localizedDescription,
                    fallback: error.localizedDescription
                )
            }
            throw error
        }
    }

    private func fetchStopsFromStationsEndpoint(limit: Int) async throws -> [Station] {
        let path = "api/stations"
        let url = try makeURL(path: path, queryItems: [
            URLQueryItem(name: "type", value: "bus"),
            URLQueryItem(name: "limit", value: String(limit))
        ])

        let data = try await fetchData(url: url, path: path)
        let decoder = JSONDecoder()

        // Support both { data: [...] } and direct array payloads.
        let rawStops: [StationsAPIStop]
        if let envelope = try? decoder.decode(StationsEnvelope.self, from: data) {
            rawStops = envelope.data
        } else {
            rawStops = try decoder.decode([StationsAPIStop].self, from: data)
        }

        let candidates = rawStops.compactMap { stop in
            candidate(
                name: stop.name ?? stop.commonName,
                code: stop.atcoCode ?? stop.code,
                latitude: stop.latitude,
                longitude: stop.longitude
            )
        }

        return normalizeAndDedupe(candidates)
    }

    private func fetchStopsFromNaptanEndpoint() async throws -> [Station] {
        let path = "api/naptan"
        let url = try makeURL(path: path)
        let data = try await fetchData(url: url, path: path)
        let decoder = JSONDecoder()

        // Support both { data: [...] } and direct array payloads.
        let rawStops: [NaptanAPIStop]
        if let envelope = try? decoder.decode(NaptanEnvelope.self, from: data) {
            rawStops = envelope.data
        } else {
            rawStops = try decoder.decode([NaptanAPIStop].self, from: data)
        }

        let candidates = rawStops.compactMap { stop in
            candidate(
                name: stop.commonName ?? stop.name,
                code: stop.atcoCode ?? stop.naptanCode ?? stop.code,
                latitude: stop.latitude,
                longitude: stop.longitude
            )
        }

        return normalizeAndDedupe(candidates)
    }

    private func candidate(name: String?, code: String?, latitude: Double?, longitude: Double?) -> StopCandidate? {
        guard
            let latitude, let longitude,
            latitude.isFinite, longitude.isFinite,
            (-90.0...90.0).contains(latitude),
            (-180.0...180.0).contains(longitude)
        else { return nil }

        let cleanedName = cleaned(name) ?? "Bus Stop"
        let cleanedCode = cleaned(code)

        return StopCandidate(
            name: cleanedName,
            code: cleanedCode,
            latitude: latitude,
            longitude: longitude
        )
    }

    private func normalizeAndDedupe(_ candidates: [StopCandidate]) -> [Station] {
        var seen = Set<String>()
        var output: [Station] = []
        output.reserveCapacity(candidates.count)

        for stop in candidates {
            let key = stableKey(for: stop)
            if seen.contains(key) { continue }
            seen.insert(key)

            let code = stop.code ?? "STOP"
            let station = Station(
                id: Self.deterministicID(from: key),
                name: stop.name,
                code: code,
                latitude: stop.latitude,
                longitude: stop.longitude
            )
            output.append(station)
        }

        return output
    }

    private func stableKey(for stop: StopCandidate) -> String {
        if let code = stop.code, !code.isEmpty {
            return "code:\(code.lowercased())"
        }
        let lat = String(format: "%.6f", stop.latitude)
        let lon = String(format: "%.6f", stop.longitude)
        return "name:\(stop.name.lowercased())|lat:\(lat)|lon:\(lon)"
    }

    private func cleaned(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw NetworkServiceError.badURL(path: path)
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkServiceError.badURL(path: path)
        }
        return url
    }

    private func fetchData(url: URL, path: String) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.badStatus(path: path, statusCode: -1)
        }
        if httpResponse.statusCode == 403,
           let server = httpResponse.value(forHTTPHeaderField: "Server"),
           server.localizedCaseInsensitiveContains("AirTunes") {
            throw NetworkServiceError.localhostPortConflict
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkServiceError.badStatus(path: path, statusCode: httpResponse.statusCode)
        }
        return data
    }

    private static func deterministicID(from source: String) -> Int {
        var hash: UInt64 = 5381
        for scalar in source.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ UInt64(scalar.value)
        }
        return Int(hash % UInt64(Int.max - 1)) + 1
    }
}
