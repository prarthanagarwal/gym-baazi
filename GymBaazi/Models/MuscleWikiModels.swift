import Foundation

// MARK: - MuscleWiki API Response Models

/// Exercise from MuscleWiki API
struct MuscleWikiExercise: Codable, Identifiable {
    let id: Int
    let name: String
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let category: String?
    let force: String?
    let grips: [String]?
    let mechanic: String?
    let difficulty: String?
    let steps: [String]?
    let videos: [ExerciseVideo]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, category, force, grips, mechanic, difficulty, steps, videos
        case primaryMuscles = "primary_muscles"
        case secondaryMuscles = "secondary_muscles"
    }
    
    struct ExerciseVideo: Codable {
        let url: String?
        let gender: String?
        let angle: String?
        let og_image: String?
    }
}

/// API list response wrapper
struct ExerciseListResponse: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let count: Int
    let results: [MuscleWikiExercise]
}

/// Muscle category from API
struct MuscleCategory: Codable, Identifiable, Hashable {
    let name: String
    let displayName: String?
    let count: Int
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name, count
        case displayName = "display_name"
    }
}

/// Equipment category from API
struct EquipmentCategory: Codable, Identifiable {
    let name: String
    let displayName: String?
    let count: Int
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name, count
        case displayName = "display_name"
    }
}

/// API Error types
enum APIError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case networkError(Error)
    case unauthorized
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to parse response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "API key is invalid or missing"
        case .rateLimited:
            return "Too many requests. Please wait."
        }
    }
}
