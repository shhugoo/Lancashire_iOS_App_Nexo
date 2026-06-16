import Foundation

/// Loads schema and seed SQL from the app bundle (if present) or returns embedded defaults.
enum ResourceLoader {
    static func loadSchema() -> String {
        if let url = Bundle.main.url(forResource: "schema", withExtension: "sql"),
           let data = try? Data(contentsOf: url),
           let s = String(data: data, encoding: .utf8), !s.isEmpty {
            return s
        }
        return embeddedSchema
    }

    static func loadSeed() -> String {
        if let url = Bundle.main.url(forResource: "seed", withExtension: "sql"),
           let data = try? Data(contentsOf: url),
           let s = String(data: data, encoding: .utf8), !s.isEmpty {
            return s
        }
        return embeddedSeed
    }

    private static let embeddedSchema = """
    CREATE TABLE IF NOT EXISTS stations (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, code TEXT NOT NULL UNIQUE, latitude REAL, longitude REAL, created_at TEXT DEFAULT (datetime('now')));
    CREATE TABLE IF NOT EXISTS route_segments (id INTEGER PRIMARY KEY AUTOINCREMENT, from_station_id INTEGER NOT NULL, to_station_id INTEGER NOT NULL, distance_km REAL NOT NULL, duration_mins INTEGER NOT NULL, created_at TEXT DEFAULT (datetime('now')), FOREIGN KEY (from_station_id) REFERENCES stations(id), FOREIGN KEY (to_station_id) REFERENCES stations(id), UNIQUE(from_station_id, to_station_id));
    CREATE INDEX IF NOT EXISTS idx_route_segments_from ON route_segments(from_station_id);
    CREATE INDEX IF NOT EXISTS idx_route_segments_to ON route_segments(to_station_id);
    """

    private static let embeddedSeed = """
    INSERT OR IGNORE INTO stations (id, name, code, latitude, longitude) VALUES
    (1, 'Preston', 'PRE', 53.7569, -2.7089),
    (2, 'Lancaster', 'LAN', 54.0487, -2.8007),
    (3, 'Carnforth', 'CNF', 54.1292, -2.7717),
    (4, 'Silverdale', 'SVR', 54.1693, -2.8034),
    (5, 'Barrow-in-Furness', 'BAR', 54.1198, -3.2274),
    (6, 'Morecambe', 'MCM', 54.0700, -2.8684),
    (7, 'Heysham Port', 'HHB', 54.0338, -2.9137),
    (8, 'Blackpool North', 'BPN', 53.8176, -3.0490),
    (9, 'Layton', 'LAY', 53.8353, -3.0317),
    (10, 'Poulton-le-Fylde', 'PFY', 53.8481, -2.9909),
    (11, 'Kirkham & Wesham', 'KKM', 53.7862, -2.8719),
    (12, 'Salwick', 'SLW', 53.7867, -2.8147),
    (13, 'Leyland', 'LEY', 53.6974, -2.6877),
    (14, 'Bamber Bridge', 'BMB', 53.7262, -2.6617),
    (15, 'Blackpool South', 'BPS', 53.7982, -3.0503),
    (16, 'Blackpool Pleasure Beach', 'BPB', 53.7880, -3.0552),
    (17, 'Squires Gate', 'SQU', 53.7772, -3.0504),
    (18, 'St Annes-on-the-Sea', 'SAS', 53.7524, -3.0289),
    (19, 'Ansdell & Fairhaven', 'AFV', 53.7419, -2.9948),
    (20, 'Lytham', 'LTM', 53.7399, -2.9626),
    (21, 'Moss Side', 'MOS', 53.7692, -2.9427),
    (22, 'Liverpool Lime Street', 'LIV', 53.4084, -2.9788),
    (23, 'Birkenhead North', 'BKN', 53.3926, -3.0148),
    (24, 'New Brighton', 'NBN', 53.4370, -3.0490),
    (25, 'West Kirby', 'WKI', 53.3734, -3.1847);

    INSERT OR IGNORE INTO route_segments (from_station_id, to_station_id, distance_km, duration_mins) VALUES
    (1, 2, 33.0, 18), (2, 1, 33.0, 18),
    (2, 3, 13.0, 12), (3, 2, 13.0, 12),
    (3, 4, 6.0, 7), (4, 3, 6.0, 7),
    (4, 5, 33.0, 26), (5, 4, 33.0, 26),
    (2, 6, 7.5, 12), (6, 2, 7.5, 12),
    (6, 7, 4.0, 4), (7, 6, 4.0, 4),
    (1, 12, 8.0, 6), (12, 1, 8.0, 6),
    (12, 11, 6.0, 5), (11, 12, 6.0, 5),
    (11, 10, 7.0, 6), (10, 11, 7.0, 6),
    (10, 9, 4.0, 5), (9, 10, 4.0, 5),
    (9, 8, 3.0, 4), (8, 9, 3.0, 4),
    (1, 13, 9.0, 7), (13, 1, 9.0, 7),
    (13, 14, 4.0, 5), (14, 13, 4.0, 5),
    (11, 21, 3.5, 4), (21, 11, 3.5, 4),
    (21, 20, 3.0, 4), (20, 21, 3.0, 4),
    (20, 19, 2.0, 3), (19, 20, 2.0, 3),
    (19, 18, 2.2, 3), (18, 19, 2.2, 3),
    (18, 17, 3.2, 4), (17, 18, 3.2, 4),
    (17, 16, 1.5, 3), (16, 17, 1.5, 3),
    (16, 15, 2.0, 4), (15, 16, 2.0, 4),
    (8, 15, 6.5, 16), (15, 8, 6.5, 16),
    (1, 22, 50.0, 45), (22, 1, 50.0, 45),
    (22, 23, 5.2, 9), (23, 22, 5.2, 9),
    (23, 24, 4.8, 14), (24, 23, 4.8, 14),
    (23, 25, 11.0, 18), (25, 23, 11.0, 18);
    """
}
