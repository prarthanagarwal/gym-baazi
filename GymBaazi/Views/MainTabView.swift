import SwiftUI

/// Main tab navigation for the app (5 tabs)
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            WorkoutTabView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(1)
            
            ExerciseLibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(3)
        }
        .tint(.orange)
        .onChange(of: selectedTab) { _, _ in
            HapticService.shared.light()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
