import Foundation

/// Centralized storage service using UserDefaults for persistence
class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Storage Keys
    private enum Keys {
        static let isOnboarded = "gymbaazi_isOnboarded"
        static let userProfile = "gymbaazi_userProfile"
        static let workoutLogs = "gymbaazi_workoutLogs"
        static let customRoutines = "gymbaazi_customRoutines"
        static let workoutSchedule = "gymbaazi_workoutSchedule"
        static let userSettings = "gymbaazi_userSettings"
        static let lastActiveWorkout = "gymbaazi_lastActiveWorkout"
    }
    
    private init() {}
    
    // MARK: - Onboarding State
    
    var isOnboarded: Bool {
        get { defaults.bool(forKey: Keys.isOnboarded) }
        set {
            defaults.set(newValue, forKey: Keys.isOnboarded)
            defaults.synchronize()
        }
    }
    
    // MARK: - User Profile
    
    var userProfile: UserProfile? {
        get { load(key: Keys.userProfile) }
        set { save(newValue, key: Keys.userProfile) }
    }
    
    func updateProfile(name: String? = nil, age: Int? = nil, height: Double? = nil, weight: Double? = nil) {
        guard var profile = userProfile else { return }
        if let name = name { profile.name = name }
        if let age = age { profile.age = age }
        if let height = height { profile.heightCm = height }
        if let weight = weight { profile.weightKg = weight }
        userProfile = profile
    }
    
    // MARK: - Workout Logs (CRUD)
    
    var workoutLogs: [WorkoutLog] {
        get { load(key: Keys.workoutLogs) ?? [] }
        set { save(newValue, key: Keys.workoutLogs) }
    }
    
    func addWorkoutLog(_ log: WorkoutLog) {
        var logs = workoutLogs
        
        // Check if log for this date already exists
        if let existingIndex = logs.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: log.date)
        }) {
            // Replace existing log
            logs[existingIndex] = log
        } else {
            // Add new log
            logs.append(log)
        }
        
        // Sort by date descending
        logs.sort { $0.date > $1.date }
        
        workoutLogs = logs
    }
    
    func deleteWorkoutLog(id: UUID) {
        workoutLogs = workoutLogs.filter { $0.id != id }
    }
    
    func getWorkoutLog(for date: Date) -> WorkoutLog? {
        workoutLogs.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func getWorkoutLogs(from startDate: Date, to endDate: Date) -> [WorkoutLog] {
        workoutLogs.filter { log in
            log.date >= startDate && log.date <= endDate
        }
    }
    
    // MARK: - Custom Routines
    
    var customRoutines: [String: WorkoutRoutine] {
        get { load(key: Keys.customRoutines) ?? [:] }
        set { save(newValue, key: Keys.customRoutines) }
    }
    
    func getRoutine(for type: WorkoutType) -> WorkoutRoutine {
        if let custom = customRoutines[type.rawValue] {
            return custom
        }
        return DefaultWorkoutData.routines[type]!
    }
    
    func updateRoutine(_ routine: WorkoutRoutine) {
        var routines = customRoutines
        routines[routine.type.rawValue] = routine
        customRoutines = routines
    }
    
    func resetRoutine(for type: WorkoutType) {
        var routines = customRoutines
        routines.removeValue(forKey: type.rawValue)
        customRoutines = routines
    }
    
    // MARK: - Workout Schedule
    
    var workoutSchedule: WorkoutSchedule {
        get { load(key: Keys.workoutSchedule) ?? WorkoutSchedule() }
        set { save(newValue, key: Keys.workoutSchedule) }
    }
    
    // MARK: - User Settings
    
    var userSettings: UserSettings {
        get { load(key: Keys.userSettings) ?? UserSettings() }
        set { save(newValue, key: Keys.userSettings) }
    }
    
    // MARK: - Active Workout State (for recovery after app kill)
    
    var lastActiveWorkout: ActiveWorkoutState? {
        get { load(key: Keys.lastActiveWorkout) }
        set { save(newValue, key: Keys.lastActiveWorkout) }
    }
    
    func saveActiveWorkoutState(
        workoutType: WorkoutType,
        startTime: Date,
        elapsedTime: Int,
        completedSets: [ExerciseSet]
    ) {
        lastActiveWorkout = ActiveWorkoutState(
            workoutType: workoutType,
            startTime: startTime,
            elapsedTime: elapsedTime,
            completedSets: completedSets,
            savedAt: Date()
        )
    }
    
    func clearActiveWorkoutState() {
        lastActiveWorkout = nil
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        isOnboarded = false
        userProfile = nil
        workoutLogs = []
        customRoutines = [:]
        userSettings = UserSettings()
        lastActiveWorkout = nil
    }
    
    // MARK: - Private Helpers
    
    private func save<T: Encodable>(_ value: T?, key: String) {
        guard let value = value else {
            defaults.removeObject(forKey: key)
            return
        }
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
            defaults.synchronize()
        }
    }
    
    private func load<T: Decodable>(key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}

// MARK: - Supporting Types

struct ActiveWorkoutState: Codable {
    let workoutType: WorkoutType
    let startTime: Date
    let elapsedTime: Int
    let completedSets: [ExerciseSet]
    let savedAt: Date
}

struct UserSettings: Codable {
    var notificationsEnabled: Bool = true
    var restTimerSound: Bool = true
    var hapticFeedback: Bool = true
    var darkModeOverride: Bool? = nil // nil = system
}
