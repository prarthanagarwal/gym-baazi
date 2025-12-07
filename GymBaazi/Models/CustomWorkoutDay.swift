import Foundation

/// User-defined workout day (replaces fixed PPL system)
struct CustomWorkoutDay: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String  // e.g., "Chest & Arms", "Back Day", "Full Body"
    var dayOfWeek: Int?  // 1=Sunday, 2=Monday, etc. nil = not scheduled
    var exercises: [Exercise] = []
    var createdAt: Date = Date()
    
    init(name: String, dayOfWeek: Int? = nil, exercises: [Exercise] = []) {
        self.name = name
        self.dayOfWeek = dayOfWeek
        self.exercises = exercises
    }
    
    /// Display name for the day of week
    var scheduledDayName: String? {
        guard let day = dayOfWeek else { return nil }
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[safe: day]
    }
}

/// User's weekly workout schedule
struct WorkoutSchedule: Codable {
    var days: [CustomWorkoutDay] = []
    
    /// Get workout for a specific day of week (1-7)
    func getWorkout(for dayOfWeek: Int) -> CustomWorkoutDay? {
        days.first { $0.dayOfWeek == dayOfWeek }
    }
    
    /// Get today's workout
    var todayWorkout: CustomWorkoutDay? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return getWorkout(for: weekday)
    }
    
    /// Check if a day has a workout scheduled
    func hasWorkout(on dayOfWeek: Int) -> Bool {
        days.contains { $0.dayOfWeek == dayOfWeek }
    }
}
