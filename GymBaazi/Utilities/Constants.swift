import Foundation

/// App-wide constants to replace magic numbers throughout the codebase
enum Constants {
    
    // MARK: - Workout
    
    enum Workout {
        /// Time window (in seconds) for recovering interrupted workouts (2 hours)
        static let recoveryWindowSeconds = 2 * 60 * 60
        
        /// Time window (in seconds) before workout session data expires (4 hours)
        static let sessionExpirySeconds = 4 * 60 * 60
        
        /// Maximum exercises to load per body part for performance
        static let maxExercisesToLoad = 100
        
        /// Maximum days in the past that a workout can be logged
        static let pastLogMaxDays = 30
    }
    
    // MARK: - Cache
    
    enum Cache {
        /// TTL for cached exercise data (1 hour)
        static let exerciseTTL: TimeInterval = 3600
        
        /// TTL for cached body part counts (24 hours)
        static let bodyPartCountsTTL: TimeInterval = 86400
        
        /// TTL for cached muscle/equipment lists (24 hours)
        static let listsTTL: TimeInterval = 86400
        
        /// Cache directory name
        static let directoryName = "GymBaaziCache"
    }
    
    // MARK: - API
    
    enum API {
        /// Maximum API requests per minute (generous for free API)
        static let maxRequestsPerMinute = 100
        
        /// Rate limit time window in seconds
        static let rateLimitWindow: TimeInterval = 60
        
        /// Default request timeout
        static let defaultTimeout: TimeInterval = 30
        
        /// Search debounce delay in nanoseconds (300ms)
        static let searchDebounceNs: UInt64 = 300_000_000
        
        /// Default page limit for API calls
        static let defaultPageLimit = 25
    }
    
    // MARK: - Validation
    
    enum Validation {
        /// Minimum name length
        static let nameMinLength = 2
        
        /// Maximum name length
        static let nameMaxLength = 50
        
        /// Minimum age
        static let ageMin = 13
        
        /// Maximum age
        static let ageMax = 100
        
        /// Minimum height in inches (4 feet)
        static let heightMinInches = 48
        
        /// Maximum height in inches (7 feet)
        static let heightMaxInches = 84
        
        /// Minimum weight in kg
        static let weightMinKg: Double = 20.0
        
        /// Maximum weight in kg
        static let weightMaxKg: Double = 300.0
        
        /// Minimum workout day name length
        static let workoutNameMinLength = 2
        
        /// Maximum workout day name length
        static let workoutNameMaxLength = 30
    }
}
