# Train App (iOS) – Phase 1

Swift/SwiftUI iPhone app for the SCC200 Group 6-5 train project. Phase 1 includes database (SQLite), pathfinding (BFS + Dijkstra), DB parser, station mapping, and a minimal search UI.

## Requirements

- Xcode 15+ (Swift 5.9+)
- iOS 17.0+ deployment target (or lower if you adjust the project)

## How to run the app (see what it looks like)

You need a **Mac with Xcode** installed (Xcode and the iOS Simulator don’t run on Windows).

1. **Open the project**
   - On your Mac, go to the repo folder and open:
   - **`TrainApp/TrainApp.xcodeproj`** (double‑click or in Xcode: File → Open).

2. **Select a run destination**
   - At the top of Xcode, click the device/simulator dropdown (e.g. “iPhone 15”) and pick an **iPhone simulator** (or a connected iPhone).

3. **Build and run**
   - Press **⌘R** (or click the Run button).
   - The simulator will start and launch the app.

4. **Use the app**
   - Tap **From** and **To** to choose stations (e.g. London Euston → Edinburgh Waverley).
   - Choose **Dijkstra (shortest time)** or **BFS (fewest changes)**.
   - Tap **Find route** to see the route and, for Dijkstra, total time.

If you don’t have a Mac, you can use a university Mac lab or a cloud Mac (e.g. MacStadium, AWS EC2 Mac) to run Xcode and the simulator.

## Phase 1 checkpoint

- On launch, the app initialises the SQLite DB (schema + seed), loads stations and route segments, and builds the pathfinding graph.
- Use **From** and **To** to pick stations, choose **BFS** (fewest changes) or **Dijkstra** (shortest time), then **Find route**.
- The route is shown as station names and, for Dijkstra, total time and number of legs.

## Folder structure

```
TrainApp/
├── README.md
├── TrainApp/                    # Xcode app target root
│   ├── TrainAppApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   ├── Database/
│   ├── Pathfinding/
│   ├── Parser/
│   ├── Mapping/
│   ├── App/
│   └── Resources/
│       ├── schema.sql
│       └── seed.sql
```

## Next (Phase 2)

Event handling, full GUI screens (search → results → booking), Ticket Suite, Account Manager.
