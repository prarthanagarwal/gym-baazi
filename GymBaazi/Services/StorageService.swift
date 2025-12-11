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
        static let workoutSessionSetData = "gymbaazi_workoutSessionSetData"
    }
    
    private init() {}
    
    // MARK: - Onboarding State
    
    var isOnboarded: Bool {
        get { defaults.bool(forKey: Keys.isOnboarded) }
        set {
            defaults.set(newValue, forKey: Keys.isOnboarded)
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
    
    // MARK: - Workout Session Set Data (for in-progress workouts)
    
    /// Wrapper struct to hold set data with date for expiration
    struct WorkoutSessionData: Codable {
        let setData: [String: [SetEntryData]]
        let savedAt: Date
    }
    
    /// Simplified set entry for storage (matches SetEntry from WorkoutTabView)
    struct SetEntryData: Codable {
        var id: String
        var setNumber: Int
        var kg: Double
        var reps: Int
        var completed: Bool
    }
    
    var workoutSessionSetData: WorkoutSessionData? {
        get { load(key: Keys.workoutSessionSetData) }
        set { save(newValue, key: Keys.workoutSessionSetData) }
    }
    
    func saveWorkoutSessionSets(_ data: [String: [[String: Any]]]) {
        // Convert to Codable format
        var codableData: [String: [SetEntryData]] = [:]
        for (exerciseId, sets) in data {
            codableData[exerciseId] = sets.compactMap { dict -> SetEntryData? in
                guard let id = dict["id"] as? String,
                      let setNumber = dict["setNumber"] as? Int,
                      let kg = dict["kg"] as? Double,
                      let reps = dict["reps"] as? Int,
                      let completed = dict["completed"] as? Bool else { return nil }
                return SetEntryData(id: id, setNumber: setNumber, kg: kg, reps: reps, completed: completed)
            }
        }
        workoutSessionSetData = WorkoutSessionData(setData: codableData, savedAt: Date())
    }
    
    func loadWorkoutSessionSets() -> [String: [[String: Any]]]? {
        guard let sessionData = workoutSessionSetData else { return nil }
        
        // Only restore if less than 4 hours old
        let age = Date().timeIntervalSince(sessionData.savedAt)
        guard age < 4 * 60 * 60 else {
            clearWorkoutSessionSets()
            return nil
        }
        
        // Convert back to dictionary format
        var result: [String: [[String: Any]]] = [:]
        for (exerciseId, sets) in sessionData.setData {
            result[exerciseId] = sets.map { entry in
                [
                    "id": entry.id,
                    "setNumber": entry.setNumber,
                    "kg": entry.kg,
                    "reps": entry.reps,
                    "completed": entry.completed
                ]
            }
        }
        return result
    }
    
    func clearWorkoutSessionSets() {
        workoutSessionSetData = nil
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        isOnboarded = false
        userProfile = nil
        workoutLogs = []
        customRoutines = [:]
        userSettings = UserSettings()
        lastActiveWorkout = nil
        workoutSessionSetData = nil
    }
    
    // MARK: - Private Helpers
    
    private func save<T: Encodable>(_ value: T?, key: String) {
        guard let value = value else {
            defaults.removeObject(forKey: key)
            return
        }
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
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

/// Theme mode for the app appearance
enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
