import Foundation

/// ExerciseDB API client for exercise data
/// Free, open-source API - no authentication required
/// Now with caching and rate limiting for better performance
class ExerciseDBService {
    static let shared = ExerciseDBService()
    
    private let baseURL = "https://www.exercisedb.dev/api/v1"
    private let defaultLimit = Constants.API.defaultPageLimit
    
    // Cache and rate limiter are actor-based for thread safety
    private let cache = CacheService.shared
    private let rateLimiter = RateLimiter.exerciseDB
    
    private init() {}
    
    // MARK: - Exercises
    
    /// Get all exercises with optional search and pagination
    func getExercises(
        offset: Int = 0,
        limit: Int = 25,
        search: String? = nil,
        sortBy: String = "targetMuscles",
        sortOrder: String = "asc"
    ) async throws -> (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?) {
        var components = URLComponents(string: "\(baseURL)/exercises")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, defaultLimit))),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "sortOrder", value: sortOrder)
        ]
        
        if let search = search, !search.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }
        
        let response: ExerciseDBResponse<[ExerciseDBExercise]> = try await request(url: components.url!)
        return (response.data, response.metadata)
    }
    
    /// Search exercises with fuzzy matching
    func searchExercises(
        query: String,
        offset: Int = 0,
        limit: Int = 25,
        threshold: Double = 0.3
    ) async throws -> (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?) {
        var components = URLComponents(string: "\(baseURL)/exercises/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, defaultLimit))),
            URLQueryItem(name: "threshold", value: String(threshold))
        ]
        
        let response: ExerciseDBResponse<[ExerciseDBExercise]> = try await request(url: components.url!)
        return (response.data, response.metadata)
    }
    
    /// Get exercise by ID
    func getExercise(id: String) async throws -> ExerciseDBExercise {
        let url = URL(string: "\(baseURL)/exercises/\(id)")!
        let response: ExerciseDBResponse<ExerciseDBExercise> = try await request(url: url)
        return response.data
    }
    
    /// Filter exercises by multiple criteria
    func filterExercises(
        muscles: [String]? = nil,
        equipment: [String]? = nil,
        bodyParts: [String]? = nil,
        search: String? = nil,
        offset: Int = 0,
        limit: Int = 25
    ) async throws -> (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?) {
        var components = URLComponents(string: "\(baseURL)/exercises/filter")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, defaultLimit)))
        ]
        
        if let muscles = muscles, !muscles.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "muscles", value: muscles.joined(separator: ",")))
        }
        if let equipment = equipment, !equipment.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "equipment", value: equipment.joined(separator: ",")))
        }
        if let bodyParts = bodyParts, !bodyParts.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "bodyParts", value: bodyParts.joined(separator: ",")))
        }
        if let search = search, !search.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "search", value: search))
        }
        
        let response: ExerciseDBResponse<[ExerciseDBExercise]> = try await request(url: components.url!)
        return (response.data, response.metadata)
    }
    
    // MARK: - By Muscle
    
    /// Get exercises targeting a specific muscle
    func getExercisesByMuscle(
        muscle: String,
        includeSecondary: Bool = false,
        offset: Int = 0,
        limit: Int = 25
    ) async throws -> (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?) {
        let encodedMuscle = muscle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? muscle
        var components = URLComponents(string: "\(baseURL)/muscles/\(encodedMuscle)/exercises")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, defaultLimit))),
            URLQueryItem(name: "includeSecondary", value: String(includeSecondary))
        ]
        
        let response: ExerciseDBResponse<[ExerciseDBExercise]> = try await request(url: components.url!)
        return (response.data, response.metadata)
    }
    
    // MARK: - By Equipment
    
    /// Get exercises using specific equipment
    func getExercisesByEquipment(
        equipment: String,
        offset: Int = 0,
        limit: Int = 25
    ) async throws -> (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?) {
        let encodedEquipment = equipment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? equipment
        var components = URLComponents(string: "\(baseURL)/equipments/\(encodedEquipment)/exercises")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, defaultLimit)))
        ]
        
        let response: ExerciseDBResponse<[ExerciseDBExercise]> = try await request(url: components.url!)
        return (response.data, response.metadata)
    }
    
    // MARK: - By Body Part
    
    /// Get exercises for a specific body part (with caching)
    func getExercisesByBodyPart(
        bodyPart: String,
        offset: Int = 0,
        limit: Int = 25,
        useCache: Bool = true
    ) async throws -> (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?) {
        let cacheKey = CacheService.Keys.bodyPartExercises(bodyPart)
        let countCacheKey = "\(cacheKey)_count"
        
        // Only use cache for full page requests (not count queries with limit=1)
        let isFullPageRequest = limit >= defaultLimit
        
        // Check cache for first page of FULL requests only
        if useCache && offset == 0 && isFullPageRequest {
            if let cached: [ExerciseDBExercise] = await cache.get(cacheKey, as: [ExerciseDBExercise].self) {
                // Also get cached count to create pseudo-metadata
                let cachedCount: Int? = await cache.get(countCacheKey, as: Int.self)
                let pseudoMetadata = cachedCount.map { 
                    ExerciseDBMetadata(totalExercises: $0, totalPages: 1, currentPage: 1, previousPage: nil, nextPage: nil)
                }
                return (cached, pseudoMetadata)
            }
        }
        
        let encodedBodyPart = bodyPart.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? bodyPart
        var components = URLComponents(string: "\(baseURL)/bodyparts/\(encodedBodyPart)/exercises")!
        components.queryItems = [
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "limit", value: String(min(limit, defaultLimit)))
        ]
        
        let response: ExerciseDBResponse<[ExerciseDBExercise]> = try await request(url: components.url!)
        
        // Cache only first page of full requests
        if offset == 0 && isFullPageRequest {
            await cache.set(response.data, forKey: cacheKey, ttl: Constants.Cache.exerciseTTL)
        }
        
        // Always cache the count (useful for library grid)
        if let count = response.metadata?.totalExercises {
            await cache.set(count, forKey: countCacheKey, ttl: Constants.Cache.exerciseTTL)
        }
        
        return (response.data, response.metadata)
    }
    
    // MARK: - Lists (cached for 24 hours)
    
    /// Get all available muscles (cached)
    func getMuscles() async throws -> [ExerciseDBMuscle] {
        let cacheKey = CacheService.Keys.muscles
        
        // Check cache first
        if let cached: [ExerciseDBMuscle] = await cache.get(cacheKey, as: [ExerciseDBMuscle].self) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/muscles")!
        let response: ExerciseDBResponse<[ExerciseDBMuscle]> = try await request(url: url)
        
        // Cache for 24 hours
        await cache.set(response.data, forKey: cacheKey, ttl: Constants.Cache.listsTTL)
        
        return response.data
    }
    
    /// Get all available equipment (cached)
    func getEquipments() async throws -> [ExerciseDBEquipment] {
        let cacheKey = CacheService.Keys.equipments
        
        // Check cache first
        if let cached: [ExerciseDBEquipment] = await cache.get(cacheKey, as: [ExerciseDBEquipment].self) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/equipments")!
        let response: ExerciseDBResponse<[ExerciseDBEquipment]> = try await request(url: url)
        
        // Cache for 24 hours
        await cache.set(response.data, forKey: cacheKey, ttl: Constants.Cache.listsTTL)
        
        return response.data
    }
    
    /// Get all body parts (cached)
    func getBodyParts() async throws -> [ExerciseDBBodyPart] {
        let cacheKey = CacheService.Keys.bodyParts
        
        // Check cache first
        if let cached: [ExerciseDBBodyPart] = await cache.get(cacheKey, as: [ExerciseDBBodyPart].self) {
            return cached
        }
        
        let url = URL(string: "\(baseURL)/bodyparts")!
        let response: ExerciseDBResponse<[ExerciseDBBodyPart]> = try await request(url: url)
        
        // Cache for 24 hours
        await cache.set(response.data, forKey: cacheKey, ttl: Constants.Cache.listsTTL)
        
        return response.data
    }
    
    // MARK: - Private Helpers
    
    private func request<T: Decodable>(url: URL) async throws -> T {
        // Wait for rate limiter before making request
        try await rateLimiter.waitAndRecord()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Constants.API.defaultTimeout
        // No authentication headers needed - it's a free API!
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExerciseDBError.invalidResponse
        }
        
        // Debug: Print raw response in development
        #if DEBUG
        if let rawString = String(data: data, encoding: .utf8) {
            print("📦 ExerciseDB Response (\(url.path)): \(rawString.prefix(500))")
        }
        #endif
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("⚠️ ExerciseDB Decoding error: \(error)")
                throw ExerciseDBError.decodingError(error)
            }
        case 404:
            throw ExerciseDBError.notFound
        case 429:
            throw ExerciseDBError.rateLimited
        default:
            throw ExerciseDBError.serverError(httpResponse.statusCode)
        }
    }
    
    /// Clears all cached exercise data
    func clearCache() async {
        await cache.invalidatePrefix("bodypart_")
        await cache.invalidatePrefix("search_")
        await cache.invalidate(CacheService.Keys.muscles)
        await cache.invalidate(CacheService.Keys.equipments)
        await cache.invalidate(CacheService.Keys.bodyParts)
        
        #if DEBUG
        print("🗑️ ExerciseDB cache cleared")
        #endif
    }
}

// MARK: - Mock Data for Development

extension ExerciseDBService {
    /// Mock exercises for fallback/testing
    static let mockExercises: [ExerciseDBExercise] = [
        ExerciseDBExercise(
            exerciseId: "mock_1",
            name: "Bench Press",
            gifUrl: "https://via.placeholder.com/400",
            targetMuscles: ["chest"],
            secondaryMuscles: ["triceps", "shoulders"],
            bodyParts: ["chest"],
            equipments: ["barbell"],
            instructions: ["Lie on bench", "Grip bar", "Lower to chest", "Press up"]
        ),
        ExerciseDBExercise(
            exerciseId: "mock_2",
            name: "Squat",
            gifUrl: "https://via.placeholder.com/400",
            targetMuscles: ["quads"],
            secondaryMuscles: ["glutes", "hamstrings"],
            bodyParts: ["upper legs"],
            equipments: ["barbell"],
            instructions: ["Stand with bar on back", "Squat down", "Stand up"]
        ),
        ExerciseDBExercise(
            exerciseId: "mock_3",
            name: "Deadlift",
            gifUrl: "https://via.placeholder.com/400",
            targetMuscles: ["back"],
            secondaryMuscles: ["hamstrings", "glutes"],
            bodyParts: ["back"],
            equipments: ["barbell"],
            instructions: ["Stand behind bar", "Grip bar", "Lift with legs and back", "Lower controlled"]
        )
    ]
    
    static let mockMuscles: [ExerciseDBMuscle] = [
        ExerciseDBMuscle(name: "chest"),
        ExerciseDBMuscle(name: "back"),
        ExerciseDBMuscle(name: "biceps"),
        ExerciseDBMuscle(name: "triceps"),
        ExerciseDBMuscle(name: "shoulders"),
        ExerciseDBMuscle(name: "quads"),
        ExerciseDBMuscle(name: "hamstrings"),
        ExerciseDBMuscle(name: "glutes"),
        ExerciseDBMuscle(name: "calves"),
        ExerciseDBMuscle(name: "abs"),
        ExerciseDBMuscle(name: "forearms"),
        ExerciseDBMuscle(name: "lats")
    ]
}
