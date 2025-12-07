import SwiftUI

// MARK: - Color Theme

extension Color {
    // Primary gradient colors
    static let pushStart = Color(hex: "F97316")  // Orange
    static let pushEnd = Color(hex: "EF4444")    // Red
    
    static let pullStart = Color(hex: "06B6D4")  // Cyan
    static let pullEnd = Color(hex: "3B82F6")    // Blue
    
    static let legsStart = Color(hex: "A855F7")  // Purple
    static let legsEnd = Color(hex: "EC4899")    // Pink
    
    static let restStart = Color(hex: "10B981")  // Emerald
    static let restEnd = Color(hex: "14B8A6")    // Teal
    
    // UI Colors
    static let cardBackground = Color(.systemBackground).opacity(0.7)
    static let glassBorder = Color.white.opacity(0.2)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    
    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    static let push = LinearGradient(
        colors: [Color.pushStart, Color.pushEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let pull = LinearGradient(
        colors: [Color.pullStart, Color.pullEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let legs = LinearGradient(
        colors: [Color.legsStart, Color.legsEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rest = LinearGradient(
        colors: [Color.restStart, Color.restEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Get gradient for workout type
    static func gradient(for type: WorkoutType) -> LinearGradient {
        switch type {
        case .push: return .push
        case .pull: return .pull
        case .legs: return .legs
        case .rest: return .rest
        }
    }
}

// MARK: - Primary Color for Workout Type

extension WorkoutType {
    var primaryColor: Color {
        switch self {
        case .push: return .pushStart
        case .pull: return .pullStart
        case .legs: return .legsStart
        case .rest: return .restStart
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .push: return .pushEnd
        case .pull: return .pullEnd
        case .legs: return .legsEnd
        case .rest: return .restEnd
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient.gradient(for: self)
    }
}
