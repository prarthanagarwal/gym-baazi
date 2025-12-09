import SwiftUI

/// Main app entry point
@main
struct GymBaaziApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
}
