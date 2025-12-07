import SwiftUI

/// ViewModel for workout session
@MainActor
class WorkoutSessionViewModel: ObservableObject {
    @Published var sets: [String: [ExerciseSet]] = [:] // exerciseId -> sets
    @Published var expandedExerciseId: String?
    
    /// Initialize sets from a custom workout day
    func initializeSetsFromCustomDay(_ day: CustomWorkoutDay) {
        for exercise in day.exercises {
            var exerciseSets: [ExerciseSet] = []
            for i in 0..<exercise.sets {
                exerciseSets.append(ExerciseSet(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    setNumber: i + 1,
                    reps: parseTargetReps(exercise.reps),
                    weight: 0
                ))
            }
            sets[exercise.id] = exerciseSets
        }
    }
    
    /// Initialize sets from routine (legacy support)
    func initializeSets(from routine: WorkoutRoutine) {
        for exercise in routine.exercises {
            var exerciseSets: [ExerciseSet] = []
            for i in 0..<exercise.sets {
                exerciseSets.append(ExerciseSet(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    setNumber: i + 1,
                    reps: parseTargetReps(exercise.reps),
                    weight: 0
                ))
            }
            sets[exercise.id] = exerciseSets
        }
    }
    
    /// Get sets for an exercise
    func getSets(for exerciseId: String) -> [ExerciseSet] {
        sets[exerciseId] ?? []
    }
    
    /// Get weight for specific set
    func getWeight(for exerciseId: String, setIndex: Int) -> Double {
        sets[exerciseId]?[safe: setIndex]?.weight ?? 0
    }
    
    /// Get reps for specific set
    func getReps(for exerciseId: String, setIndex: Int) -> Int {
        sets[exerciseId]?[safe: setIndex]?.reps ?? 8
    }
    
    /// Update a set with new weight/reps
    func updateSet(exerciseId: String, setIndex: Int, weight: Double, reps: Int) {
        guard var exerciseSets = sets[exerciseId],
              setIndex < exerciseSets.count else { return }
        
        exerciseSets[setIndex].weight = weight
        exerciseSets[setIndex].reps = reps
        sets[exerciseId] = exerciseSets
    }
    
    /// Toggle set completion
    func toggleSetCompletion(exerciseId: String, setIndex: Int) {
        guard var exerciseSets = sets[exerciseId],
              setIndex < exerciseSets.count else { return }
        
        exerciseSets[setIndex].completed.toggle()
        sets[exerciseId] = exerciseSets
    }
    
    /// Mark set as completed
    func completeSet(exerciseId: String, setIndex: Int) {
        guard var exerciseSets = sets[exerciseId],
              setIndex < exerciseSets.count else { return }
        
        exerciseSets[setIndex].completed = true
        sets[exerciseId] = exerciseSets
    }
    
    /// Get all completed sets as flat array
    func getAllSets() -> [ExerciseSet] {
        sets.values.flatMap { $0 }
    }
    
    /// Check if all sets are completed
    var allSetsCompleted: Bool {
        let allSets = getAllSets()
        guard !allSets.isEmpty else { return false }
        return allSets.allSatisfy { $0.completed }
    }
    
    /// Completion progress (0-1)
    var completionProgress: Double {
        let allSets = getAllSets()
        guard !allSets.isEmpty else { return 0 }
        let completed = allSets.filter { $0.completed }.count
        return Double(completed) / Double(allSets.count)
    }
    
    /// Parse target reps from string like "8-10"
    private func parseTargetReps(_ reps: String) -> Int {
        let parts = reps.split(separator: "-").compactMap { Int($0) }
        if parts.count == 2 {
            return (parts[0] + parts[1]) / 2  // Return middle value
        } else if let first = parts.first {
            return first
        }
        return 10
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
