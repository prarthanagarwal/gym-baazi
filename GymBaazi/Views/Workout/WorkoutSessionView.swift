import SwiftUI

/// Active workout session view with exercise tracking
struct WorkoutSessionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WorkoutSessionViewModel()
    @Environment(\.dismiss) var dismiss
    
    // Optional: pass a custom day, otherwise uses today's scheduled workout
    var customDay: CustomWorkoutDay?
    
    @State private var showRestTimer = false
    @State private var currentRestDuration = 90
    @State private var selectedExerciseIndex: Int?
    @State private var selectedSetIndex: Int?
    @State private var showSetPicker = false
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
                                        selectedExerciseIndex = exIndex
                                        selectedSetIndex = setIndex
                                        showSetPicker = true
                                        HapticService.shared.light()
                                    },
                                    onSetComplete: { setIndex in
                                        viewModel.completeSet(exerciseId: exercise.id, setIndex: setIndex)
                                        HapticService.shared.medium()
                                        
                                        // Show rest timer after completing a set
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
            .sheet(isPresented: $showSetPicker) {
                if let exIndex = selectedExerciseIndex,
                   let setIndex = selectedSetIndex,
                   exIndex < exercises.count {
                    SetInputSheet(
                        exercise: exercises[exIndex],
                        setIndex: setIndex,
                        currentWeight: viewModel.getWeight(for: exercises[exIndex].id, setIndex: setIndex),
                        currentReps: viewModel.getReps(for: exercises[exIndex].id, setIndex: setIndex),
                        onSave: { weight, reps in
                            viewModel.updateSet(
                                exerciseId: exercises[exIndex].id,
                                setIndex: setIndex,
                                weight: weight,
                                reps: reps
                            )
                            HapticService.shared.success()
                        }
                    )
                    .presentationDetents([.medium])
                }
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
    
    private func completeWorkout() {
        let log = WorkoutLog(
            date: Date(),
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
