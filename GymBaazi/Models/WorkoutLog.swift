import Foundation

/// Workout session log saved to history
struct WorkoutLog: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var type: WorkoutType
    var dayName: String?  // Custom day name (e.g., "Chest & Arms")
    var completed: Bool = false
    var duration: Int = 0 // seconds
    var sets: [ExerciseSet] = []
    
    init(date: Date = Date(), type: WorkoutType, dayName: String? = nil, completed: Bool = false, duration: Int = 0, sets: [ExerciseSet] = []) {
        self.date = date
        self.type = type
        self.dayName = dayName
        self.completed = completed
        self.duration = duration
        self.sets = sets
    }
    
    /// Total volume (weight × reps) for all sets
    var totalVolume: Double {
        sets.filter { $0.completed }.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    /// Number of completed sets
    var completedSetsCount: Int {
        sets.filter { $0.completed }.count
    }
    
    /// Formatted duration string
    var formattedDuration: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
