import Foundation

// MARK: - ExerciseDB API Response Models

/// Exercise from ExerciseDB API
struct ExerciseDBExercise: Codable, Identifiable, Hashable {
    let exerciseId: String
    let name: String
    let gifUrl: String
    let targetMuscles: [String]
    let secondaryMuscles: [String]
    let bodyParts: [String]
    let equipments: [String]
    let instructions: [String]
    
    var id: String { exerciseId }
    
    /// Primary equipment (first in list)
    var primaryEquipment: String? {
        equipments.first
    }
    
    /// Primary target muscle (first in list)
    var primaryMuscle: String? {
        targetMuscles.first
    }
}

/// Generic API response wrapper
struct ExerciseDBResponse<T: Codable>: Codable {
    let success: Bool
    let metadata: ExerciseDBMetadata?
    let data: T
}

/// Pagination metadata
struct ExerciseDBMetadata: Codable {
    let totalExercises: Int
    let totalPages: Int
    let currentPage: Int
    let previousPage: String?
    let nextPage: String?
}

/// Muscle from API
struct ExerciseDBMuscle: Codable, Identifiable, Hashable {
    let name: String
    
    var id: String { name }
    
    /// Capitalized display name
    var displayName: String {
        name.capitalized
    }
}

/// Equipment from API
struct ExerciseDBEquipment: Codable, Identifiable, Hashable {
    let name: String
    
    var id: String { name }
    
    var displayName: String {
        name.capitalized
    }
}

/// Body part from API
struct ExerciseDBBodyPart: Codable, Identifiable, Hashable {
    let name: String
    
    var id: String { name }
    
    var displayName: String {
        name.capitalized
    }
}

// MARK: - API Error Types

enum ExerciseDBError: Error, LocalizedError {
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case notFound
    case serverError(Int)
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .notFound:
            return "Exercise not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        }
    }
}
