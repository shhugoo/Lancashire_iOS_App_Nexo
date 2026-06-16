import SwiftUI

@main
struct TrainAppApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear { appState.initialize() }
        }
    }
}
