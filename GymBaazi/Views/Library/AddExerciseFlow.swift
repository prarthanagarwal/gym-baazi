import SwiftUI

/// Multi-step flow for adding an exercise to a workout routine
struct AddExerciseFlow: View {
    let workoutType: WorkoutType
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    
    @State private var selectedExercise: ExerciseDBExercise?
    @State private var customSets: Int = 3
    @State private var customReps: String = "8-10"
    @State private var restSeconds: Int = 90
    @State private var step: AddExerciseStep = .browse
    @State private var searchText = ""
    
    enum AddExerciseStep {
        case browse      // Browse/search exercises
        case configure   // Set sets, reps, rest time
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .browse:
                    browseView
                case .configure:
                    if let exercise = selectedExercise {
                        configureView(exercise: exercise)
                    }
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await viewModel.loadExercises()
        }
    }
    
    private var stepTitle: String {
        switch step {
        case .browse: return "Add Exercise"
        case .configure: return "Configure"
        }
    }
    
    // MARK: - Browse View
    
    private var browseView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            // Exercise list
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                List(viewModel.filteredExercises(searchText)) { exercise in
                    Button(action: {
                        selectedExercise = exercise
                        step = .configure
                        HapticService.shared.light()
                    }) {
                        ExercisePickerRow(exercise: exercise)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.count >= 2 {
                Task {
                    await viewModel.searchExercises(query: newValue)
                }
            } else if newValue.isEmpty {
                Task {
                    await viewModel.loadExercises()
                }
            }
        }
    }
    
    // MARK: - Configure View
    
    private func configureView(exercise: ExerciseDBExercise) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise header
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.title2.bold())
                    
                    HStack {
                        ForEach(exercise.targetMuscles, id: \.self) { muscle in
                            MuscleBadge(muscle: muscle.capitalized, isPrimary: true)
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Sets picker
                configSection(title: "Number of Sets") {
                    Stepper(value: $customSets, in: 1...10) {
                        HStack {
                            Text("\(customSets)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text("sets")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: customSets) { _, _ in HapticService.shared.light() }
                }
                
                // Reps picker
                configSection(title: "Rep Range") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(["4-6", "6-8", "8-10", "10-12", "12-15", "15-20"], id: \.self) { option in
                            Button(option) {
                                customReps = option
                                HapticService.shared.light()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(customReps == option ? .orange : .gray)
                        }
                    }
                }
                
                // Rest time picker
                configSection(title: "Rest Time") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach([30, 60, 90, 120, 180, 240], id: \.self) { seconds in
                            Button(formatRest(seconds)) {
                                restSeconds = seconds
                                HapticService.shared.light()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(restSeconds == seconds ? .cyan : .gray)
                        }
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button("Back") {
                    step = .browse
                    HapticService.shared.light()
                }
                .buttonStyle(.bordered)
                
                Button("Add Exercise") {
                    addExerciseToRoutine(exercise)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    private func configSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func formatRest(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        return "\(mins)m"
    }
    
    private func addExerciseToRoutine(_ apiExercise: ExerciseDBExercise) {
        let newExercise = Exercise(
            id: "custom_\(UUID().uuidString.prefix(8))",
            name: apiExercise.name,
            sets: customSets,
            reps: customReps,
            isCompound: false, // ExerciseDB doesn't have mechanic field
            restTime: formatRestTime(restSeconds),
            restSeconds: restSeconds,
            exerciseDbId: apiExercise.exerciseId
        )
        
        appState.addExerciseToRoutine(newExercise, for: workoutType)
        dismiss()
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        let mins = seconds / 60
        let secs = seconds % 60
        return secs > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(mins) min"
    }
}

// MARK: - Exercise Picker Row

struct ExercisePickerRow: View {
    let exercise: ExerciseDBExercise
    
    var body: some View {
        HStack(spacing: 12) {
            ExerciseGifThumbnail(gifUrl: exercise.gifUrl, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(exercise.targetMuscles.joined(separator: ", ").capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "plus.circle")
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddExerciseFlow(workoutType: .push)
        .environmentObject(AppState())
}
