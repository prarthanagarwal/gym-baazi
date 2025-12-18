import SwiftUI
import AVFoundation

/// Main app entry point
@main
struct GymBaaziApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Request notification permission for rest timer
        NotificationHelper.requestPermission()
        
        // Configure audio session to not interrupt music
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
    
    /// Configure audio session to mix with other audio (don't interrupt music)
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
}
