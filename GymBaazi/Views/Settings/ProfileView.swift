import SwiftUI

/// Profile view (renamed from Settings) with user info and preferences
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showResetConfirmation = false
    @State private var showClearDataConfirmation = false
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
                
                // Appearance Section
                Section("Appearance") {
                    Picker(selection: Binding(
                        get: { appState.currentThemeMode },
                        set: { appState.setThemeMode($0) }
                    )) {
                        ForEach(ThemeMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush.fill")
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
                        Text("1.1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer")
                        Link(destination: URL(string: "https://www.prarthanagarwal.me")!) {
                            HStack {
                                Text("Prarthan Agarwal")
                                    .foregroundColor(.orange)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditingProfile) {
                EditProfileSheet()
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

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var age: Int = 25
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Info") {
                    TextField("Name", text: $name)
                    
                    Stepper("Age: \(age) years", value: $age, in: 13...100)
                }
                
                Section("Body Metrics") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height: \(Int(heightCm)) cm")
                        Slider(value: $heightCm, in: 100...250, step: 1)
                            .tint(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight: \(String(format: "%.1f", weightKg)) kg")
                        Slider(value: $weightKg, in: 30...200, step: 0.5)
                            .tint(.orange)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let profile = appState.userProfile {
                    name = profile.name
                    age = profile.age
                    heightCm = profile.heightCm
                    weightKg = profile.weightKg
                }
            }
        }
    }
    
    private func saveProfile() {
        StorageService.shared.updateProfile(
            name: name,
            age: age,
            height: heightCm,
            weight: weightKg
        )
        
        // Update appState
        appState.userProfile?.name = name
        appState.userProfile?.age = age
        appState.userProfile?.heightCm = heightCm
        appState.userProfile?.weightKg = weightKg
        
        HapticService.shared.success()
        dismiss()
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
