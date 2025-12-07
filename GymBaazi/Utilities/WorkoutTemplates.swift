import Foundation

/// Pre-built workout templates for quick setup
struct WorkoutTemplates {
    
    // MARK: - Template Definitions
    
    static let pushDay = WorkoutTemplate(
        id: "push",
        name: "Push Day",
        description: "Chest, Shoulders, Triceps",
        icon: "arrow.up.forward",
        color: "orange",
        exercises: [
            TemplateExercise(name: "Bench Press", sets: 4, reps: "8-10", muscle: "Chest"),
            TemplateExercise(name: "Overhead Press", sets: 3, reps: "8-10", muscle: "Shoulders"),
            TemplateExercise(name: "Incline Dumbbell Press", sets: 3, reps: "10-12", muscle: "Upper Chest"),
            TemplateExercise(name: "Lateral Raises", sets: 3, reps: "12-15", muscle: "Side Delts"),
            TemplateExercise(name: "Tricep Pushdown", sets: 3, reps: "12-15", muscle: "Triceps"),
            TemplateExercise(name: "Overhead Tricep Extension", sets: 3, reps: "12-15", muscle: "Triceps")
        ]
    )
    
    static let pullDay = WorkoutTemplate(
        id: "pull",
        name: "Pull Day",
        description: "Back, Biceps, Rear Delts",
        icon: "arrow.down.backward",
        color: "cyan",
        exercises: [
            TemplateExercise(name: "Deadlift", sets: 3, reps: "5-6", muscle: "Back"),
            TemplateExercise(name: "Barbell Row", sets: 4, reps: "8-10", muscle: "Back"),
            TemplateExercise(name: "Lat Pulldown", sets: 3, reps: "10-12", muscle: "Lats"),
            TemplateExercise(name: "Face Pulls", sets: 3, reps: "15-20", muscle: "Rear Delts"),
            TemplateExercise(name: "Barbell Curl", sets: 3, reps: "10-12", muscle: "Biceps"),
            TemplateExercise(name: "Hammer Curls", sets: 3, reps: "12-15", muscle: "Biceps")
        ]
    )
    
    static let legDay = WorkoutTemplate(
        id: "legs",
        name: "Leg Day",
        description: "Quads, Hamstrings, Glutes, Calves",
        icon: "figure.walk",
        color: "purple",
        exercises: [
            TemplateExercise(name: "Squat", sets: 4, reps: "6-8", muscle: "Quadriceps"),
            TemplateExercise(name: "Romanian Deadlift", sets: 3, reps: "8-10", muscle: "Hamstrings"),
            TemplateExercise(name: "Leg Press", sets: 3, reps: "10-12", muscle: "Quadriceps"),
            TemplateExercise(name: "Walking Lunges", sets: 3, reps: "12 each", muscle: "Glutes"),
            TemplateExercise(name: "Leg Curl", sets: 3, reps: "12-15", muscle: "Hamstrings"),
            TemplateExercise(name: "Calf Raises", sets: 4, reps: "15-20", muscle: "Calves")
        ]
    )
    
    static let upperBody = WorkoutTemplate(
        id: "upper",
        name: "Upper Body",
        description: "Full upper body workout",
        icon: "figure.arms.open",
        color: "blue",
        exercises: [
            TemplateExercise(name: "Bench Press", sets: 4, reps: "8-10", muscle: "Chest"),
            TemplateExercise(name: "Barbell Row", sets: 4, reps: "8-10", muscle: "Back"),
            TemplateExercise(name: "Overhead Press", sets: 3, reps: "8-10", muscle: "Shoulders"),
            TemplateExercise(name: "Lat Pulldown", sets: 3, reps: "10-12", muscle: "Lats"),
            TemplateExercise(name: "Barbell Curl", sets: 3, reps: "10-12", muscle: "Biceps"),
            TemplateExercise(name: "Tricep Pushdown", sets: 3, reps: "12-15", muscle: "Triceps")
        ]
    )
    
    static let lowerBody = WorkoutTemplate(
        id: "lower",
        name: "Lower Body",
        description: "Full lower body workout",
        icon: "figure.run",
        color: "green",
        exercises: [
            TemplateExercise(name: "Squat", sets: 4, reps: "6-8", muscle: "Quadriceps"),
            TemplateExercise(name: "Romanian Deadlift", sets: 4, reps: "8-10", muscle: "Hamstrings"),
            TemplateExercise(name: "Leg Press", sets: 3, reps: "10-12", muscle: "Quadriceps"),
            TemplateExercise(name: "Leg Curl", sets: 3, reps: "12-15", muscle: "Hamstrings"),
            TemplateExercise(name: "Hip Thrust", sets: 3, reps: "10-12", muscle: "Glutes"),
            TemplateExercise(name: "Calf Raises", sets: 4, reps: "15-20", muscle: "Calves")
        ]
    )
    
    static let fullBody = WorkoutTemplate(
        id: "full",
        name: "Full Body",
        description: "Complete full body workout",
        icon: "figure.strengthtraining.traditional",
        color: "red",
        exercises: [
            TemplateExercise(name: "Squat", sets: 3, reps: "8-10", muscle: "Quadriceps"),
            TemplateExercise(name: "Bench Press", sets: 3, reps: "8-10", muscle: "Chest"),
            TemplateExercise(name: "Barbell Row", sets: 3, reps: "8-10", muscle: "Back"),
            TemplateExercise(name: "Overhead Press", sets: 3, reps: "8-10", muscle: "Shoulders"),
            TemplateExercise(name: "Romanian Deadlift", sets: 3, reps: "10-12", muscle: "Hamstrings"),
            TemplateExercise(name: "Barbell Curl", sets: 2, reps: "10-12", muscle: "Biceps"),
            TemplateExercise(name: "Tricep Pushdown", sets: 2, reps: "12-15", muscle: "Triceps")
        ]
    )
    
    // MARK: - All Templates
    
    static let all: [WorkoutTemplate] = [pushDay, pullDay, legDay, upperBody, lowerBody, fullBody]
    
    // MARK: - Suggested Schedules by Frequency
    
    static func suggestedSchedule(forDaysPerWeek days: Int) -> [DaySuggestion] {
        switch days {
        case 1:
            return [DaySuggestion(dayOfWeek: 3, template: fullBody)] // Wednesday
        case 2:
            return [
                DaySuggestion(dayOfWeek: 2, template: upperBody), // Monday
                DaySuggestion(dayOfWeek: 5, template: lowerBody)  // Thursday
            ]
        case 3:
            return [
                DaySuggestion(dayOfWeek: 2, template: pushDay),   // Monday
                DaySuggestion(dayOfWeek: 4, template: pullDay),   // Wednesday
                DaySuggestion(dayOfWeek: 6, template: legDay)     // Friday
            ]
        case 4:
            return [
                DaySuggestion(dayOfWeek: 2, template: upperBody), // Monday
                DaySuggestion(dayOfWeek: 3, template: lowerBody), // Tuesday
                DaySuggestion(dayOfWeek: 5, template: upperBody), // Thursday
                DaySuggestion(dayOfWeek: 6, template: lowerBody)  // Friday
            ]
        case 5:
            return [
                DaySuggestion(dayOfWeek: 2, template: pushDay),   // Monday
                DaySuggestion(dayOfWeek: 3, template: pullDay),   // Tuesday
                DaySuggestion(dayOfWeek: 4, template: legDay),    // Wednesday
                DaySuggestion(dayOfWeek: 6, template: upperBody), // Friday
                DaySuggestion(dayOfWeek: 7, template: lowerBody)  // Saturday
            ]
        case 6, 7:
            return [
                DaySuggestion(dayOfWeek: 2, template: pushDay),   // Monday
                DaySuggestion(dayOfWeek: 3, template: pullDay),   // Tuesday
                DaySuggestion(dayOfWeek: 4, template: legDay),    // Wednesday
                DaySuggestion(dayOfWeek: 5, template: pushDay),   // Thursday
                DaySuggestion(dayOfWeek: 6, template: pullDay),   // Friday
                DaySuggestion(dayOfWeek: 7, template: legDay)     // Saturday
            ]
        default:
            return []
        }
    }
}

// MARK: - Supporting Types

struct WorkoutTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let exercises: [TemplateExercise]
    
    /// Convert to CustomWorkoutDay
    func toCustomWorkoutDay(forDayOfWeek day: Int? = nil) -> CustomWorkoutDay {
        CustomWorkoutDay(
            name: name,
            dayOfWeek: day,
            exercises: exercises.map { $0.toExercise() }
        )
    }
}

struct TemplateExercise {
    let name: String
    let sets: Int
    let reps: String
    let muscle: String
    
    func toExercise() -> Exercise {
        Exercise(
            name: name,
            sets: sets,
            reps: reps,
            isCompound: sets >= 4,
            restTime: sets >= 4 ? "2-3 min" : "60-90 sec",
            restSeconds: sets >= 4 ? 150 : 90
        )
    }
}

struct DaySuggestion {
    let dayOfWeek: Int  // 1=Sunday, 2=Monday, etc.
    let template: WorkoutTemplate
    
    var dayName: String {
        ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][dayOfWeek]
    }
    
    var fullDayName: String {
        ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][dayOfWeek]
    }
}
