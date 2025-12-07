import SwiftUI

/// Root view that handles onboarding/main app navigation
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) var scenePhase
    @State private var showLaunch = true
    
    var body: some View {
        ZStack {
            if showLaunch {
                LaunchScreen()
                    .transition(.opacity)
            } else if !appState.isOnboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showLaunch)
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboarded)
        .onAppear {
            // Show launch screen for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showLaunch = false
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // Save any pending state
            if appState.isWorkoutStarted {
                appState.saveWorkoutState()
            }
        case .active:
            // Recalculate elapsed time if workout was active
            if appState.isWorkoutStarted && !appState.isPaused {
                appState.recalculateElapsedTime()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
