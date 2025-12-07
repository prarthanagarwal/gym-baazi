import Foundation

/// Workout type following PPL (Push/Pull/Legs) rotation
enum WorkoutType: String, Codable, CaseIterable {
    case push = "PUSH"
    case pull = "PULL"
    case legs = "LEGS"
    case rest = "REST"
    
    var displayName: String {
        switch self {
        case .push: return "Push Day"
        case .pull: return "Pull Day"
        case .legs: return "Leg Day"
        case .rest: return "Rest Day"
        }
    }
    
    var emoji: String {
        switch self {
        case .push: return "💪"
        case .pull: return "🏋️"
        case .legs: return "🦵"
        case .rest: return "😴"
        }
    }
    
    var description: String {
        switch self {
        case .push: return "Chest, Shoulders & Triceps"
        case .pull: return "Back & Biceps"
        case .legs: return "Quads, Hamstrings & Glutes"
        case .rest: return "Recovery & Stretching"
        }
    }
}

/// A day's workout plan with exercises
struct WorkoutRoutine: Codable, Identifiable {
    var id: String { type.rawValue }
    var type: WorkoutType
    var title: String
    var subtitle: String
    var exercises: [Exercise]
    var warmup: [String]
    var cooldown: [String]
    
    init(type: WorkoutType, title: String, subtitle: String, exercises: [Exercise], warmup: [String] = [], cooldown: [String] = []) {
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.exercises = exercises
        self.warmup = warmup
        self.cooldown = cooldown
    }
}
