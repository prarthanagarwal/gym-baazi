import SwiftUI

/// Main app entry point
@main
struct GymBaaziApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Request notification permission for rest timer
        NotificationHelper.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
}
