import SwiftUI

/// Global app state container - manages all shared state
@MainActor
class AppState: ObservableObject {
    // MARK: - Onboarding State
    @Published var isOnboarded: Bool = false
    @Published var userProfile: UserProfile?
    
    // MARK: - Workout State
    @Published var workoutLogs: [WorkoutLog] = []
    @Published var workoutSchedule: WorkoutSchedule = WorkoutSchedule()
    @Published var customRoutines: [String: WorkoutRoutine] = [:]  // Legacy, kept for compatibility
    
    // MARK: - Timer State
    @Published var isWorkoutStarted: Bool = false
    @Published var isPaused: Bool = false
    @Published var elapsedTime: Int = 0
    @Published var workoutStartTime: Date?
    @Published var currentSets: [ExerciseSet] = []
    @Published var currentWorkoutDay: CustomWorkoutDay?
    
    // MARK: - User Settings
    @Published var userSettings: UserSettings = UserSettings()
    
    private var timer: Timer?
    
    // MARK: - Theme
    
    /// Preferred color scheme based on user settings
    /// nil = system, false = light, true = dark
    var preferredColorScheme: ColorScheme? {
        guard let darkMode = userSettings.darkModeOverride else { return nil }
        return darkMode ? .dark : .light
    }
    
    /// Update theme preference
    func setThemeMode(_ mode: ThemeMode) {
        switch mode {
        case .system:
            userSettings.darkModeOverride = nil
        case .light:
            userSettings.darkModeOverride = false
        case .dark:
            userSettings.darkModeOverride = true
        }
        StorageService.shared.userSettings = userSettings
    }
    
    /// Get current theme mode
    var currentThemeMode: ThemeMode {
        guard let darkMode = userSettings.darkModeOverride else { return .system }
        return darkMode ? .dark : .light
    }
    
    // MARK: - Computed Properties
    
    var todayWorkoutType: WorkoutType {
        WorkoutScheduler.getWorkoutType()
    }
    
    var todayRoutine: WorkoutRoutine {
        getRoutine(for: todayWorkoutType)
    }
    
    var hasCompletedTodayWorkout: Bool {
        workoutLogs.first { Calendar.current.isDateInToday($0.date) }?.completed ?? false
    }
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    // MARK: - Initialization
    
    init() {
        loadFromStorage()
    }
    
    private func loadFromStorage() {
        isOnboarded = StorageService.shared.isOnboarded
        userProfile = StorageService.shared.userProfile
        workoutLogs = StorageService.shared.workoutLogs
        workoutSchedule = StorageService.shared.workoutSchedule
        customRoutines = StorageService.shared.customRoutines
        userSettings = StorageService.shared.userSettings
        
        // Try to recover interrupted workout
        recoverActiveWorkout()
    }
    
    // MARK: - Workout Schedule Management
    
    func addWorkoutDay(_ day: CustomWorkoutDay) {
        workoutSchedule.days.append(day)
        saveSchedule()
    }
    
    func updateWorkoutDay(_ day: CustomWorkoutDay) {
        if let index = workoutSchedule.days.firstIndex(where: { $0.id == day.id }) {
            workoutSchedule.days[index] = day
            saveSchedule()
        }
    }
    
    func deleteWorkoutDay(id: UUID) {
        workoutSchedule.days.removeAll { $0.id == id }
        saveSchedule()
        HapticService.shared.warning()
    }
    
    private func saveSchedule() {
        StorageService.shared.workoutSchedule = workoutSchedule
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding(profile: UserProfile) {
        userProfile = profile
        isOnboarded = true
        StorageService.shared.userProfile = profile
        StorageService.shared.isOnboarded = true
    }
    
    // MARK: - Timer Management
    
    func startWorkout() {
        guard !isWorkoutStarted else { return }
        
        isWorkoutStarted = true
        isPaused = false
        workoutStartTime = Date()
        elapsedTime = 0
        currentSets = []
        
        startTimer()
        saveWorkoutState()
        HapticService.shared.success()
    }
    
    func pauseWorkout() {
        isPaused = true
        timer?.invalidate()
        saveWorkoutState()
        HapticService.shared.medium()
    }
    
    func resumeWorkout() {
        isPaused = false
        startTimer()
        saveWorkoutState()
        HapticService.shared.medium()
    }
    
    func resetWorkout() {
        timer?.invalidate()
        timer = nil
        isWorkoutStarted = false
        isPaused = false
        elapsedTime = 0
        workoutStartTime = nil
        currentSets = []
        StorageService.shared.clearActiveWorkoutState()
        HapticService.shared.warning()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }
    
    func saveWorkoutState() {
        guard isWorkoutStarted, let startTime = workoutStartTime else { return }
        StorageService.shared.saveActiveWorkoutState(
            workoutType: todayWorkoutType,
            startTime: startTime,
            elapsedTime: elapsedTime,
            completedSets: currentSets
        )
    }
    
    func recoverActiveWorkout() {
        guard let state = StorageService.shared.lastActiveWorkout else { return }
        
        // Only recover if less than 2 hours old
        let age = Date().timeIntervalSince(state.savedAt)
        guard age < 2 * 60 * 60 else {
            StorageService.shared.clearActiveWorkoutState()
            return
        }
        
        // Restore state (start paused, let user resume)
        isWorkoutStarted = true
        isPaused = true
        workoutStartTime = state.startTime
        elapsedTime = state.elapsedTime + Int(age)
        currentSets = state.completedSets
    }
    
    func recalculateElapsedTime() {
        guard let startTime = workoutStartTime, !isPaused else { return }
        elapsedTime = Int(Date().timeIntervalSince(startTime))
    }
    
    // MARK: - Workout Log Management
    
    func saveWorkoutLog(_ log: WorkoutLog) {
        var newLog = log
        newLog.completed = true
        workoutLogs.insert(newLog, at: 0)
        StorageService.shared.addWorkoutLog(newLog)
        resetWorkout()
        HapticService.shared.success()
    }
    
    func deleteWorkoutLog(id: UUID) {
        workoutLogs.removeAll { $0.id == id }
        StorageService.shared.deleteWorkoutLog(id: id)
    }
    
    // MARK: - Routine Management
    
    func getRoutine(for type: WorkoutType) -> WorkoutRoutine {
        customRoutines[type.rawValue] ?? DefaultWorkoutData.routines[type]!
    }
    
    func addExerciseToRoutine(_ exercise: Exercise, for type: WorkoutType) {
        var routine = getRoutine(for: type)
        routine.exercises.append(exercise)
        customRoutines[type.rawValue] = routine
        saveRoutines()
        HapticService.shared.success()
    }
    
    func removeExercise(at index: Int, from type: WorkoutType) {
        guard var routine = customRoutines[type.rawValue] else { return }
        routine.exercises.remove(at: index)
        customRoutines[type.rawValue] = routine
        saveRoutines()
        HapticService.shared.medium()
    }
    
    func moveExercise(from source: IndexSet, to destination: Int, in type: WorkoutType) {
        guard var routine = customRoutines[type.rawValue] else { return }
        routine.exercises.move(fromOffsets: source, toOffset: destination)
        customRoutines[type.rawValue] = routine
        saveRoutines()
    }
    
    func resetRoutine(for type: WorkoutType) {
        customRoutines[type.rawValue] = DefaultWorkoutData.routines[type]
        saveRoutines()
    }
    
    private func saveRoutines() {
        StorageService.shared.customRoutines = customRoutines
    }
    
    // MARK: - Stats
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Check backwards from today
        while true {
            let dayWorkoutType = WorkoutScheduler.getWorkoutType(for: currentDate)
            
            // Skip rest days in streak calculation
            if dayWorkoutType == .rest {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
                continue
            }
            
            // Check if user worked out on this day
            if let log = workoutLogs.first(where: { calendar.isDate($0.date, inSameDayAs: currentDate) }),
               log.completed {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Formatted elapsed time string
    var formattedElapsedTime: String {
        let hours = elapsedTime / 3600
        let minutes = (elapsedTime % 3600) / 60
        let seconds = elapsedTime % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
