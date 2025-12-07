import Foundation

/// Individual set data within an exercise
struct ExerciseSet: Codable, Identifiable {
    var id: UUID = UUID()
    var exerciseId: String
    var exerciseName: String
    var setNumber: Int
    var reps: Int
    var weight: Double // kg
    var completed: Bool = false
    
    init(exerciseId: String, exerciseName: String, setNumber: Int, reps: Int = 0, weight: Double = 0) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
    }
}
