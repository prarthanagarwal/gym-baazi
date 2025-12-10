import SwiftUI

/// Active workout session view with exercise tracking
struct WorkoutSessionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WorkoutSessionViewModel()
    @Environment(\.dismiss) var dismiss
    
    // Optional: pass a custom day, otherwise uses today's scheduled workout
    var customDay: CustomWorkoutDay?
    
    // Optional: custom workout date for past-date logging (Feature 2)
    var workoutDate: Date = Date()
    
    @State private var showRestTimer = false
    @State private var currentRestDuration = 90
    @State private var completedExerciseIndex: Int = 0
    @State private var completedSetIndex: Int = 0
    @State private var setSelection: SetSelection? = nil  // For sheet(item:) pattern
    @State private var showCompleteConfirmation = false
    
    var exercises: [Exercise] {
        customDay?.exercises ?? []
    }
    
    var workoutTitle: String {
        customDay?.name ?? "Workout"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if exercises.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Header card
                            WorkoutHeaderCard(
                                title: workoutTitle,
                                elapsedTime: appState.formattedElapsedTime,
                                progress: viewModel.completionProgress
                            )
                            
                            // Exercise cards
                            ForEach(Array(exercises.enumerated()), id: \.element.id) { exIndex, exercise in
                                ExerciseSessionCard(
                                    exercise: exercise,
                                    sets: viewModel.getSets(for: exercise.id),
                                    isExpanded: viewModel.expandedExerciseId == exercise.id,
                                    onToggleExpand: {
                                        withAnimation(.spring(duration: 0.3)) {
                                            if viewModel.expandedExerciseId == exercise.id {
                                                viewModel.expandedExerciseId = nil
                                            } else {
                                                viewModel.expandedExerciseId = exercise.id
                                            }
                                        }
                                        HapticService.shared.light()
                                    },
                                    onSetTap: { setIndex in
                                        // Capture all data at tap time in Identifiable struct
                                        setSelection = SetSelection(
                                            exercise: exercise,
                                            setIndex: setIndex,
                                            currentWeight: viewModel.getWeight(for: exercise.id, setIndex: setIndex),
                                            currentReps: viewModel.getReps(for: exercise.id, setIndex: setIndex)
                                        )
                                        HapticService.shared.light()
                                    },
                                    onSetComplete: { setIndex in
                                        viewModel.completeSet(exerciseId: exercise.id, setIndex: setIndex)
                                        HapticService.shared.medium()
                                        
                                        // Track which set was completed for rest timer
                                        completedExerciseIndex = exIndex
                                        completedSetIndex = setIndex
                                        currentRestDuration = exercise.restSeconds
                                        showRestTimer = true
                                    }
                                )
                            }
                            
                            // Complete workout button
                            Button(action: { showCompleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Complete Workout")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.allSetsCompleted ? Color.green : Color.orange)
                                .cornerRadius(16)
                            }
                            .padding(.top, 16)
                            
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                }
                
                // Rest timer overlay
                if showRestTimer {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { }
                    
                    RestTimerView(
                        duration: currentRestDuration,
                        setNumber: completedSetIndex + 1,
                        exerciseName: exercises.indices.contains(completedExerciseIndex) ? exercises[completedExerciseIndex].name : "",
                        nextInfo: computeNextInfo(),
                        isPresented: $showRestTimer
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle(workoutTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $setSelection) { selection in
                SetInputSheet(
                    exercise: selection.exercise,
                    setIndex: selection.setIndex,
                    currentWeight: selection.currentWeight,
                    currentReps: selection.currentReps,
                    onSave: { weight, reps in
                        viewModel.updateSet(
                            exerciseId: selection.exercise.id,
                            setIndex: selection.setIndex,
                            weight: weight,
                            reps: reps
                        )
                        HapticService.shared.success()
                    }
                )
                .presentationDetents([.medium])
            }
            .confirmationDialog("Complete Workout?", isPresented: $showCompleteConfirmation) {
                Button("Complete & Save") {
                    completeWorkout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Great job! Your workout will be saved to history.")
            }
            .onAppear {
                if let day = customDay {
                    viewModel.initializeSetsFromCustomDay(day)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No exercises in this workout")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Edit the workout day to add exercises")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// Compute the "Next" display for rest timer
    private func computeNextInfo() -> String {
        guard exercises.indices.contains(completedExerciseIndex) else { return "" }
        
        let currentExercise = exercises[completedExerciseIndex]
        let setsForExercise = viewModel.getSets(for: currentExercise.id)
        let completedSetsCount = setsForExercise.filter { $0.completed }.count
        
        // Check if there are more sets for this exercise
        if completedSetsCount < currentExercise.sets {
            return "Set \(completedSetsCount + 1) of \(currentExercise.name)"
        }
        
        // All sets done - show next exercise if available
        let nextExerciseIndex = completedExerciseIndex + 1
        if exercises.indices.contains(nextExerciseIndex) {
            return exercises[nextExerciseIndex].name
        }
        
        // Last exercise - no next
        return "Workout complete!"
    }
    
    private func completeWorkout() {
        let log = WorkoutLog(
            date: workoutDate,
            type: .push,  // Default type
            dayName: customDay?.name,
            completed: true,
            duration: appState.elapsedTime,
            sets: viewModel.getAllSets()
        )
        
        appState.saveWorkoutLog(log)
        dismiss()
    }
}

// MARK: - Set Selection Model

/// Identifiable struct for sheet(item:) pattern - captures data at tap time
struct SetSelection: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let setIndex: Int
    let currentWeight: Double
    let currentReps: Int
}

#Preview {
    WorkoutSessionView(customDay: CustomWorkoutDay(
        name: "Test Day",
        exercises: [
            Exercise(name: "Bench Press", sets: 3, reps: "8-10"),
            Exercise(name: "Push Ups", sets: 3, reps: "12-15")
        ]
    ))
    .environmentObject(AppState())
}
