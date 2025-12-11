import Foundation

/// Disk-based cache service with TTL support
/// Persists cached data across app launches for improved performance
actor CacheService {
    static let shared = CacheService()
    
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Cache directory URL
    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Constants.Cache.directoryName)
    }
    
    // MARK: - Initialization
    
    private init() {
        Task { await setupCacheDirectory() }
    }
    
    private func setupCacheDirectory() {
        guard let cacheDir = cacheDirectory else { return }
        if !fileManager.fileExists(atPath: cacheDir.path) {
            try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Cache Entry
    
    private struct CacheEntry<T: Codable>: Codable {
        let value: T
        let timestamp: Date
        let ttl: TimeInterval
        
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < ttl
        }
        
        var age: TimeInterval {
            Date().timeIntervalSince(timestamp)
        }
    }
    
    // MARK: - Public API
    
    /// Retrieves a cached value if it exists and is still valid
    /// - Parameters:
    ///   - key: Cache key
    ///   - type: Type to decode
    /// - Returns: Cached value or nil if not found/expired
    func get<T: Codable>(_ key: String, as type: T.Type) -> T? {
        guard let url = fileURL(for: key) else { return nil }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        guard let entry = try? decoder.decode(CacheEntry<T>.self, from: data) else {
            // Corrupted cache, remove it
            try? fileManager.removeItem(at: url)
            return nil
        }
        
        // Check if expired
        guard entry.isValid else {
            try? fileManager.removeItem(at: url)
            return nil
        }
        
        #if DEBUG
        print("📦 Cache HIT: \(key) (age: \(Int(entry.age))s)")
        #endif
        
        return entry.value
    }
    
    /// Stores a value in cache with specified TTL
    /// - Parameters:
    ///   - value: Value to cache
    ///   - key: Cache key
    ///   - ttl: Time-to-live in seconds
    func set<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval) {
        guard let url = fileURL(for: key) else { return }
        
        let entry = CacheEntry(value: value, timestamp: Date(), ttl: ttl)
        
        guard let data = try? encoder.encode(entry) else { return }
        
        try? data.write(to: url)
        
        #if DEBUG
        print("📦 Cache SET: \(key) (TTL: \(Int(ttl))s)")
        #endif
    }
    
    /// Invalidates (removes) a specific cache entry
    func invalidate(_ key: String) {
        guard let url = fileURL(for: key) else { return }
        try? fileManager.removeItem(at: url)
        
        #if DEBUG
        print("📦 Cache INVALIDATE: \(key)")
        #endif
    }
    
    /// Invalidates all cached data matching a prefix
    func invalidatePrefix(_ prefix: String) {
        guard let cacheDir = cacheDirectory else { return }
        
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files where file.lastPathComponent.hasPrefix(prefix) {
            try? fileManager.removeItem(at: file)
        }
        
        #if DEBUG
        print("📦 Cache INVALIDATE PREFIX: \(prefix)*")
        #endif
    }
    
    /// Clears the entire cache
    func invalidateAll() {
        guard let cacheDir = cacheDirectory else { return }
        
        try? fileManager.removeItem(at: cacheDir)
        setupCacheDirectory()
        
        #if DEBUG
        print("📦 Cache CLEARED")
        #endif
    }
    
    /// Cleans up expired cache entries
    func cleanupExpired() {
        guard let cacheDir = cacheDirectory else { return }
        
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) else {
            return
        }
        
        var cleanedCount = 0
        for file in files {
            // Try to read and check expiry
            if let data = try? Data(contentsOf: file),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let timestamp = json["timestamp"] as? TimeInterval,
               let ttl = json["ttl"] as? TimeInterval {
                
                let age = Date().timeIntervalSince(Date(timeIntervalSince1970: timestamp))
                if age > ttl {
                    try? fileManager.removeItem(at: file)
                    cleanedCount += 1
                }
            }
        }
        
        #if DEBUG
        if cleanedCount > 0 {
            print("📦 Cache CLEANUP: removed \(cleanedCount) expired entries")
        }
        #endif
    }
    
    /// Returns cache statistics
    func stats() -> CacheStats {
        guard let cacheDir = cacheDirectory else {
            return CacheStats(fileCount: 0, totalSize: 0)
        }
        
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            return CacheStats(fileCount: 0, totalSize: 0)
        }
        
        var totalSize: Int64 = 0
        for file in files {
            if let attrs = try? fileManager.attributesOfItem(atPath: file.path),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return CacheStats(fileCount: files.count, totalSize: totalSize)
    }
    
    // MARK: - Private Helpers
    
    private func fileURL(for key: String) -> URL? {
        // Sanitize key for filesystem
        let sanitized = key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        return cacheDirectory?.appendingPathComponent("\(sanitized).cache")
    }
}

// MARK: - Cache Stats

struct CacheStats {
    let fileCount: Int
    let totalSize: Int64
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}

// MARK: - Convenience Keys

extension CacheService {
    enum Keys {
        static func bodyPartExercises(_ bodyPart: String) -> String {
            "bodypart_\(bodyPart.lowercased())"
        }
        
        static let bodyPartCounts = "bodypart_counts"
        static let muscles = "muscles_list"
        static let equipments = "equipments_list"
        static let bodyParts = "bodyparts_list"
        
        static func search(_ query: String) -> String {
            "search_\(query.lowercased())"
        }
        
        static func exercise(_ id: String) -> String {
            "exercise_\(id)"
        }
    }
}
