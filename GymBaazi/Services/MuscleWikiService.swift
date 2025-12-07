import Foundation

/// MuscleWiki API client for exercise data and videos
class MuscleWikiService {
    static let shared = MuscleWikiService()
    
    private let baseURL = "https://musclewiki-api.p.rapidapi.com"
    let rapidAPIKey = "33fe9f1a18msh5f0b640ad83fa5fp19fe7djsnc8186c835ebc"
    let rapidAPIHost = "musclewiki-api.p.rapidapi.com"
    
    private var headers: [String: String] {
        [
            "X-RapidAPI-Key": rapidAPIKey,
            "X-RapidAPI-Host": rapidAPIHost
        ]
    }
    
    private init() {}
    
    // MARK: - Endpoints
    
    /// Get exercises with optional filters
    func getExercises(
        limit: Int = 20,
        category: String? = nil,
        muscles: String? = nil,
        difficulty: String? = nil,
        force: String? = nil // "push" or "pull"
    ) async throws -> ExerciseListResponse {
        var components = URLComponents(string: "\(baseURL)/exercises")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let muscles = muscles {
            queryItems.append(URLQueryItem(name: "muscles", value: muscles))
        }
        if let difficulty = difficulty {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }
        if let force = force {
            queryItems.append(URLQueryItem(name: "force", value: force))
        }
        
        components.queryItems = queryItems
        
        return try await request(url: components.url!)
    }
    
    /// Get detailed exercise by ID
    func getExercise(id: Int, detail: Bool = true) async throws -> MuscleWikiExercise {
        var components = URLComponents(string: "\(baseURL)/exercises/\(id)")!
        components.queryItems = [URLQueryItem(name: "detail", value: String(detail))]
        return try await request(url: components.url!)
    }
    
    /// Search exercises
    func searchExercises(query: String, limit: Int = 20) async throws -> ExerciseListResponse {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        // /search returns an array directly, not wrapped
        let exercises: [MuscleWikiExercise] = try await request(url: components.url!)
        return ExerciseListResponse(total: exercises.count, limit: limit, offset: 0, count: exercises.count, results: exercises)
    }
    
    /// Get push exercises (for Push day)
    func getPushExercises(limit: Int = 20) async throws -> ExerciseListResponse {
        var components = URLComponents(string: "\(baseURL)/workouts/push")!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        return try await request(url: components.url!)
    }
    
    /// Get pull exercises (for Pull day)
    func getPullExercises(limit: Int = 20) async throws -> ExerciseListResponse {
        var components = URLComponents(string: "\(baseURL)/workouts/pull")!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        return try await request(url: components.url!)
    }
    
    /// Get available muscle groups
    func getMuscles() async throws -> [MuscleCategory] {
        let url = URL(string: "\(baseURL)/muscles")!
        return try await request(url: url)
    }
    
    /// Get equipment categories
    func getCategories() async throws -> [EquipmentCategory] {
        let url = URL(string: "\(baseURL)/categories")!
        return try await request(url: url)
    }
    
    /// Get random exercise
    func getRandomExercise(category: String? = nil) async throws -> MuscleWikiExercise {
        var components = URLComponents(string: "\(baseURL)/random")!
        if let category = category {
            components.queryItems = [URLQueryItem(name: "category", value: category)]
        }
        return try await request(url: components.url!)
    }
    
    // MARK: - Video Streaming URLs
    
    func getBrandedVideoURL(filename: String) -> URL? {
        URL(string: "\(baseURL)/stream/videos/branded/\(filename)")
    }
    
    func getUnbrandedVideoURL(filename: String) -> URL? {
        URL(string: "\(baseURL)/stream/videos/unbranded/\(filename)")
    }
    
    // MARK: - Private helpers
    
    private func request<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Debug: Print raw response
        if let rawString = String(data: data, encoding: .utf8) {
            print("📦 API Response (\(url.path)): \(rawString.prefix(500))")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("⚠️ Decoding error: \(error)")
                throw APIError.decodingError
            }
        case 401, 403:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimited
        default:
            throw APIError.invalidResponse
        }
    }
}

// MARK: - Mock Data for Development (when API key not available)

extension MuscleWikiService {
    /// Returns mock exercises for development/testing
    static func mockExercises(for type: WorkoutType) -> [MuscleWikiExercise] {
        switch type {
        case .push:
            return [
                MuscleWikiExercise(id: 1, name: "Bench Press", primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps", "Shoulders"], category: "Barbell", force: "push", grips: nil, mechanic: "compound", difficulty: "intermediate", steps: ["Lie on bench", "Grip bar", "Lower to chest", "Press up"], videos: nil),
                MuscleWikiExercise(id: 2, name: "Overhead Press", primaryMuscles: ["Shoulders"], secondaryMuscles: ["Triceps"], category: "Barbell", force: "push", grips: nil, mechanic: "compound", difficulty: "intermediate", steps: nil, videos: nil),
                MuscleWikiExercise(id: 3, name: "Incline Dumbbell Press", primaryMuscles: ["Upper Chest"], secondaryMuscles: ["Shoulders", "Triceps"], category: "Dumbbell", force: "push", grips: nil, mechanic: "compound", difficulty: "beginner", steps: nil, videos: nil),
                MuscleWikiExercise(id: 4, name: "Tricep Pushdown", primaryMuscles: ["Triceps"], secondaryMuscles: nil, category: "Cable", force: "push", grips: nil, mechanic: "isolation", difficulty: "beginner", steps: nil, videos: nil),
                MuscleWikiExercise(id: 5, name: "Lateral Raises", primaryMuscles: ["Side Delts"], secondaryMuscles: nil, category: "Dumbbell", force: "push", grips: nil, mechanic: "isolation", difficulty: "beginner", steps: nil, videos: nil)
            ]
        case .pull:
            return [
                MuscleWikiExercise(id: 6, name: "Deadlift", primaryMuscles: ["Back", "Hamstrings"], secondaryMuscles: ["Glutes", "Traps"], category: "Barbell", force: "pull", grips: nil, mechanic: "compound", difficulty: "advanced", steps: nil, videos: nil),
                MuscleWikiExercise(id: 7, name: "Barbell Row", primaryMuscles: ["Back"], secondaryMuscles: ["Biceps"], category: "Barbell", force: "pull", grips: nil, mechanic: "compound", difficulty: "intermediate", steps: nil, videos: nil),
                MuscleWikiExercise(id: 8, name: "Lat Pulldown", primaryMuscles: ["Lats"], secondaryMuscles: ["Biceps"], category: "Cable", force: "pull", grips: nil, mechanic: "compound", difficulty: "beginner", steps: nil, videos: nil),
                MuscleWikiExercise(id: 9, name: "Face Pulls", primaryMuscles: ["Rear Delts"], secondaryMuscles: ["Traps"], category: "Cable", force: "pull", grips: nil, mechanic: "isolation", difficulty: "beginner", steps: nil, videos: nil),
                MuscleWikiExercise(id: 10, name: "Barbell Curl", primaryMuscles: ["Biceps"], secondaryMuscles: nil, category: "Barbell", force: "pull", grips: nil, mechanic: "isolation", difficulty: "beginner", steps: nil, videos: nil)
            ]
        case .legs:
            return [
                MuscleWikiExercise(id: 11, name: "Squat", primaryMuscles: ["Quadriceps"], secondaryMuscles: ["Glutes", "Hamstrings"], category: "Barbell", force: nil, grips: nil, mechanic: "compound", difficulty: "intermediate", steps: nil, videos: nil),
                MuscleWikiExercise(id: 12, name: "Romanian Deadlift", primaryMuscles: ["Hamstrings"], secondaryMuscles: ["Glutes", "Lower Back"], category: "Barbell", force: nil, grips: nil, mechanic: "compound", difficulty: "intermediate", steps: nil, videos: nil),
                MuscleWikiExercise(id: 13, name: "Leg Press", primaryMuscles: ["Quadriceps"], secondaryMuscles: ["Glutes"], category: "Machine", force: nil, grips: nil, mechanic: "compound", difficulty: "beginner", steps: nil, videos: nil),
                MuscleWikiExercise(id: 14, name: "Leg Curl", primaryMuscles: ["Hamstrings"], secondaryMuscles: nil, category: "Machine", force: nil, grips: nil, mechanic: "isolation", difficulty: "beginner", steps: nil, videos: nil),
                MuscleWikiExercise(id: 15, name: "Calf Raises", primaryMuscles: ["Calves"], secondaryMuscles: nil, category: "Machine", force: nil, grips: nil, mechanic: "isolation", difficulty: "beginner", steps: nil, videos: nil)
            ]
        case .rest:
            return []
        }
    }
}
