import Foundation

/// PPL Workout scheduler based on day of week
struct WorkoutScheduler {
    // Day-based workout schedule
    // Monday (2) & Thursday (5) = LEGS
    // Tuesday (3) & Friday (6) = PUSH
    // Wednesday (4) & Saturday (7) = PULL
    // Sunday (1) = REST
    
    /// Get workout type for a given date
    static func getWorkoutType(for date: Date = Date()) -> WorkoutType {
        let weekday = Calendar.current.component(.weekday, from: date)
        
        switch weekday {
        case 1: return .rest      // Sunday
        case 2, 5: return .legs   // Monday, Thursday
        case 3, 6: return .push   // Tuesday, Friday
        case 4, 7: return .pull   // Wednesday, Saturday
        default: return .rest
        }
    }
    
    /// Get full week schedule
    static func getWeekSchedule() -> [(day: String, type: WorkoutType)] {
        [
            ("Mon", .legs),
            ("Tue", .push),
            ("Wed", .pull),
            ("Thu", .legs),
            ("Fri", .push),
            ("Sat", .pull),
            ("Sun", .rest)
        ]
    }
    
    /// Get workout type for next n days
    static func getUpcomingWorkouts(days: Int = 7) -> [(date: Date, type: WorkoutType)] {
        let calendar = Calendar.current
        return (0..<days).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: Date()) else { return nil }
            return (date, getWorkoutType(for: date))
        }
    }
    
    /// Check if user has worked out today
    static func hasWorkedOutToday() -> Bool {
        let today = Date()
        return StorageService.shared.getWorkoutLog(for: today)?.completed ?? false
    }
}
