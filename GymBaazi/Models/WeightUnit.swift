import Foundation

/// User's preferred weight unit system (for weight only, height is always ft/in)
enum WeightUnit: String, Codable, CaseIterable {
    case kg = "kg"
    case lbs = "lbs"
    
    var displayName: String {
        switch self {
        case .kg: return "Kilograms"
        case .lbs: return "Pounds"
        }
    }
    
    var symbol: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}

