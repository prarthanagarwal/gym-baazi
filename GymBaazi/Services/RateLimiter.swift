import Foundation

/// Rate limiter to prevent excessive API calls
/// Uses sliding window algorithm to track request frequency
/// Configured generously for free API usage
actor RateLimiter {
    
    private var requestTimestamps: [Date] = []
    private let maxRequests: Int
    private let window: TimeInterval
    
    // MARK: - Initialization
    
    /// Creates a new rate limiter
    /// - Parameters:
    ///   - maxRequests: Maximum number of requests allowed in the window
    ///   - window: Time window in seconds
    init(maxRequests: Int = Constants.API.maxRequestsPerMinute,
         window: TimeInterval = Constants.API.rateLimitWindow) {
        self.maxRequests = maxRequests
        self.window = window
    }
    
    // MARK: - Public API
    
    /// Checks if a new request can be made within rate limits
    var canProceed: Bool {
        cleanupOldRequests()
        return requestTimestamps.count < maxRequests
    }
    
    /// Number of available requests remaining
    var remainingRequests: Int {
        cleanupOldRequests()
        return max(0, maxRequests - requestTimestamps.count)
    }
    
    /// Time until the next request slot becomes available (in seconds)
    var timeUntilNextSlot: TimeInterval? {
        cleanupOldRequests()
        guard !canProceed, let oldestRequest = requestTimestamps.first else {
            return nil
        }
        return window - Date().timeIntervalSince(oldestRequest)
    }
    
    /// Records a new request
    func recordRequest() {
        requestTimestamps.append(Date())
        
        #if DEBUG
        print("🚦 Rate Limiter: \(remainingRequests)/\(maxRequests) requests remaining")
        #endif
    }
    
    /// Waits if necessary until a request can be made, then records it
    /// - Throws: CancellationError if the task is cancelled while waiting
    func waitAndRecord() async throws {
        while !canProceed {
            guard let waitTime = timeUntilNextSlot else { break }
            
            #if DEBUG
            print("🚦 Rate Limiter: waiting \(String(format: "%.1f", waitTime))s...")
            #endif
            
            // Wait in small increments to allow cancellation
            let waitNanoseconds = UInt64(min(waitTime, 0.5) * 1_000_000_000)
            try await Task.sleep(nanoseconds: waitNanoseconds)
        }
        
        recordRequest()
    }
    
    /// Resets the rate limiter (useful for testing)
    func reset() {
        requestTimestamps.removeAll()
    }
    
    // MARK: - Private
    
    private func cleanupOldRequests() {
        let cutoff = Date().addingTimeInterval(-window)
        requestTimestamps = requestTimestamps.filter { $0 > cutoff }
    }
}

// MARK: - Shared Instance

extension RateLimiter {
    /// Shared rate limiter for ExerciseDB API
    static let exerciseDB = RateLimiter()
}
