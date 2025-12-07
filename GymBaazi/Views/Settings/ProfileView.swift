import SwiftUI

/// Profile view (renamed from Settings) with user info and preferences
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetConfirmation = false
    @State private var showClearDataConfirmation = false
    @State private var editedName = ""
    @State private var isEditingProfile = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient.push)
                                .frame(width: 60, height: 60)
                            
                            Text(appState.userProfile?.name.prefix(1).uppercased() ?? "?")
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.userProfile?.name ?? "Champ")
                                .font(.headline)
                            
                            if let profile = appState.userProfile {
                                Text("\(profile.age) years • \(Int(profile.heightCm)) cm • \(String(format: "%.1f", profile.weightKg)) kg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Edit") {
                            editedName = appState.userProfile?.name ?? ""
                            isEditingProfile = true
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
                
                // Stats Section
                Section("Your Progress") {
                    HStack {
                        StatItem(title: "Workouts", value: "\(appState.workoutLogs.filter { $0.completed }.count)", icon: "flame.fill", color: .orange)
                        Divider()
                        StatItem(title: "Streak", value: "\(appState.currentStreak) days", icon: "bolt.fill", color: .yellow)
                        Divider()
                        StatItem(title: "Days", value: "\(appState.workoutSchedule.days.count)", icon: "calendar", color: .cyan)
                    }
                }
                
                // Preferences Section
                Section("Preferences") {
                    Toggle(isOn: Binding(
                        get: { StorageService.shared.userSettings.hapticFeedback },
                        set: { newValue in
                            var settings = StorageService.shared.userSettings
                            settings.hapticFeedback = newValue
                            StorageService.shared.userSettings = settings
                        }
                    )) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                    }
                    
                    Toggle(isOn: Binding(
                        get: { StorageService.shared.userSettings.restTimerSound },
                        set: { newValue in
                            var settings = StorageService.shared.userSettings
                            settings.restTimerSound = newValue
                            StorageService.shared.userSettings = settings
                        }
                    )) {
                        Label("Rest Timer Sound", systemImage: "speaker.wave.2")
                    }
                }
                
                // Data Section
                Section("Data") {
                    NavigationLink {
                        WorkoutStatsView()
                    } label: {
                        Label("Workout Statistics", systemImage: "chart.bar")
                    }
                    
                    Button(role: .destructive, action: { showClearDataConfirmation = true }) {
                        Label("Clear All Data", systemImage: "trash")
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Edit Name", isPresented: $isEditingProfile) {
                TextField("Name", text: $editedName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if !editedName.isEmpty {
                        StorageService.shared.updateProfile(name: editedName)
                        appState.userProfile?.name = editedName
                    }
                }
            }
            .confirmationDialog("Clear All Data?", isPresented: $showClearDataConfirmation) {
                Button("Clear Everything", role: .destructive) {
                    StorageService.shared.clearAllData()
                    HapticService.shared.error()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your workout history, custom routines, and personal data. This cannot be undone.")
            }
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Stats View

struct WorkoutStatsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            Section("Overview") {
                StatRow(title: "Total Workouts", value: "\(appState.workoutLogs.filter { $0.completed }.count)")
                StatRow(title: "Current Streak", value: "\(appState.currentStreak) days")
                StatRow(title: "Total Time", value: formatTotalTime())
                StatRow(title: "Workout Days Created", value: "\(appState.workoutSchedule.days.count)")
            }
            
            Section("Total Volume") {
                let totalVolume = appState.workoutLogs.reduce(0.0) { $0 + $1.totalVolume }
                StatRow(title: "Lifetime Volume", value: "\(Int(totalVolume)) kg")
            }
        }
        .navigationTitle("Statistics")
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = appState.workoutLogs.reduce(0) { $0 + $1.duration }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
