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
                                let totalInches = profile.heightCm / 2.54
                                let feet = Int(totalInches) / 12
                                let inches = Int(totalInches) % 12
                                Text("\(profile.age) years • \(feet)' \(inches)\" • \(String(format: "%.1f", profile.weightKg)) kg")
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
                    .environmentObject(appState)
                    .preferredColorScheme(appState.preferredColorScheme)
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
    
    // Validation state
    @State private var nameError: ValidationError?
    @State private var hasAttemptedSave = false
    
    /// Whether the form is valid and can be saved
    private var isFormValid: Bool {
        FormValidator.validateName(name) == nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Name with validation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                        TextField("Your name", text: $name)
                            .font(.title3)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onChange(of: name) { _, newValue in
                                // Validate on change after first save attempt
                                if hasAttemptedSave {
                                    nameError = FormValidator.validateName(newValue)
                                }
                            }
                            .validationFeedback(nameError, showBorder: true)
                    }
                    .padding(.horizontal)
                    
                    // Age
                    ProfileMetricSlider(
                        title: "Age",
                        value: Binding(get: { Double(age) }, set: { age = Int($0) }),
                        range: Double(Constants.Validation.ageMin)...Double(Constants.Validation.ageMax),
                        step: 1,
                        unit: "years",
                        displayValue: "\(age)"
                    )
                    .padding(.horizontal)
                    
                    // Height (ft/in)
                    ProfileHeightPicker(heightCm: $heightCm)
                        .padding(.horizontal)
                    
                    // Weight
                    ProfileMetricSlider(
                        title: "Weight",
                        value: $weightKg,
                        range: Constants.Validation.weightMinKg...Constants.Validation.weightMaxKg,
                        step: 0.5,
                        unit: "kg",
                        displayValue: weightKg.formattedWeight
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        attemptSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
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
    
    private func attemptSave() {
        hasAttemptedSave = true
        
        // Validate all fields
        nameError = FormValidator.validateName(name)
        
        // Only save if valid
        guard isFormValid else {
            HapticService.shared.error()
            return
        }
        
        saveProfile()
    }
    
    private func saveProfile() {
        StorageService.shared.updateProfile(
            name: name.trimmed,
            age: age,
            height: heightCm,
            weight: weightKg
        )
        
        // Update appState
        appState.userProfile?.name = name.trimmed
        appState.userProfile?.age = age
        appState.userProfile?.heightCm = heightCm
        appState.userProfile?.weightKg = weightKg
        
        HapticService.shared.success()
        dismiss()
    }
}

// MARK: - Profile Metric Slider

struct ProfileMetricSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let displayValue: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(displayValue) \(unit)")
                    .font(.title3.bold())
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
                
                Slider(value: $value, in: range, step: step)
                    .tint(.orange)
                
                Button(action: {
                    if value < range.upperBound {
                        value += step
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Profile Height Picker (ft/in)

struct ProfileHeightPicker: View {
    @Binding var heightCm: Double
    
    private var totalInches: Double {
        heightCm / 2.54
    }
    
    private var feet: Int {
        Int(totalInches) / 12
    }
    
    private var inches: Int {
        Int(totalInches) % 12
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Height")
                    .font(.headline)
                Spacer()
                Text("\(feet)' \(inches)\"")
                    .font(.title3.bold())
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    if totalInches > 48 {
                        heightCm -= 2.54
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
                
                Slider(
                    value: Binding(
                        get: { totalInches },
                        set: { heightCm = $0 * 2.54 }
                    ),
                    in: 48...84,
                    step: 1
                )
                .tint(.orange)
                
                Button(action: {
                    if totalInches < 84 {
                        heightCm += 2.54
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
