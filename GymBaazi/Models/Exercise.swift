import Foundation

/// Exercise definition with sets, reps, and rest time
struct Exercise: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var sets: Int
    var reps: String // e.g., "6-8", "8-10"
    var isCompound: Bool
    var restTime: String // e.g., "2-4 min"
    var restSeconds: Int
    var exerciseDbId: String? // For API lookup (ExerciseDB)
    
    init(id: String? = nil, name: String, sets: Int, reps: String, isCompound: Bool = false, restTime: String = "90 sec", restSeconds: Int = 90, exerciseDbId: String? = nil) {
        self.id = id ?? "ex_\(UUID().uuidString.prefix(8))"
        self.name = name
        self.sets = sets
        self.reps = reps
        self.isCompound = isCompound
        self.restTime = restTime
        self.restSeconds = restSeconds
        self.exerciseDbId = exerciseDbId
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}
