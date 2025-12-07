# Gym-Baazi SwiftUI Replication Guide

> **"Your No Fuss Gym Buddy"** - A comprehensive workout tracker app with PPL (Push/Pull/Legs) rotation, exercise library with video demonstrations, workout history tracking, and motivational features.

## Table of Contents
1. [App Overview](#app-overview)
2. [Architecture & Best Practices](#architecture--best-practices)
3. [Data Models](#data-models)
4. [Screens & Features](#screens--features)
5. [MuscleWiki API Integration](#musclewiki-api-integration)
6. [UI Components](#ui-components)
7. [Animations & Haptics](#animations--haptics)
8. [Local Storage (UserDefaults/SwiftData)](#local-storage)
9. [Implementation Checklist](#implementation-checklist)

---

## App Overview

### Core Features
- **Automatic PPL Rotation**: Workouts scheduled based on day of week
- **Interactive Session Tracking**: Per-set logging with weight/reps, rest timer
- **Exercise Library**: Browse exercises by muscle group with video demonstrations (MuscleWiki API)
- **Workout History**: Calendar view with detailed session logs
- **Personal Records Tracking**: Track and display PRs
- **Motivational Quotes**: Daily rotating inspirational quotes
- **Haptic Feedback**: Tactile feedback on all interactions

### New Features to Add
- **Launch Screen**: Animated logo with gradient background
- **Onboarding Flow**: Collect user's name, age, height, and weight
- **Customizable Workout Plans**: Users can add/remove exercises to their daily routines using a + button
- **MuscleWiki API Integration**: Replace ExerciseDB with MuscleWiki for exercise data and videos

---

## Architecture & Best Practices

### Project Structure
```
GymBaazi/
├── App/
│   ├── GymBaaziApp.swift          # App entry point
│   └── ContentView.swift           # Root navigation
├── Models/
│   ├── UserProfile.swift           # User data (name, age, height, weight)
│   ├── WorkoutLog.swift            # Workout session logs
│   ├── ExerciseSet.swift           # Individual set data
│   ├── Exercise.swift              # Exercise definition
│   ├── WorkoutRoutine.swift        # Day's workout plan
│   └── UserSettings.swift          # App settings
├── Views/
│   ├── Launch/
│   │   └── LaunchScreen.swift      # Animated launch screen
│   ├── Onboarding/
│   │   ├── OnboardingView.swift    # Main onboarding container
│   │   ├── NameInputView.swift     # Name collection
│   │   ├── BodyMetricsView.swift   # Age, height, weight
│   │   └── WorkoutSetupView.swift  # Initial workout customization
│   ├── Home/
│   │   └── HomeView.swift          # Dashboard with today's workout
│   ├── Workout/
│   │   ├── WorkoutSessionView.swift    # Active workout tracking
│   │   ├── ExerciseCardView.swift      # Exercise display with sets
│   │   ├── SetInputView.swift          # Weight/reps picker
│   │   └── RestTimerView.swift         # Countdown rest timer
│   ├── Library/
│   │   ├── ExerciseLibraryView.swift   # Browse exercises
│   │   ├── ExerciseDetailView.swift    # Exercise details + video
│   │   └── ExerciseSearchView.swift    # Search functionality
│   ├── History/
│   │   ├── HistoryView.swift           # Calendar + log list
│   │   └── WorkoutDetailView.swift     # Detailed session view
│   ├── Settings/
│   │   └── SettingsView.swift          # App preferences
│   └── Components/
│       ├── GlassCard.swift             # Glassmorphism card
│       ├── GradientButton.swift        # Styled buttons
│       ├── StepperPicker.swift         # Weight/reps picker
│       ├── MuscleBadge.swift           # Muscle group badge
│       └── QuoteCard.swift             # Motivational quote display
├── ViewModels/
│   ├── AppState.swift              # Global app state (ObservableObject)
│   ├── WorkoutViewModel.swift      # Workout session logic
│   ├── ExerciseLibraryViewModel.swift  # Exercise browsing
│   └── HistoryViewModel.swift      # History management
├── Services/
│   ├── MuscleWikiService.swift     # API client for MuscleWiki
│   ├── StorageService.swift        # Local persistence
│   └── HapticService.swift         # Haptic feedback manager
├── Utilities/
│   ├── WorkoutScheduler.swift      # PPL rotation logic
│   ├── DateUtils.swift             # Date formatting
│   └── Quotes.swift                # Motivational quotes data
└── Resources/
    ├── Assets.xcassets             # Images, colors, app icon
    └── LaunchScreen.storyboard     # Launch screen (or SwiftUI)
```

### SwiftUI Best Practices
1. **MVVM Architecture**: Separate Views, ViewModels, and Models
2. **ObservableObject/StateObject**: Use for shared state management
3. **Environment Objects**: Pass app-wide state through environment
4. **Async/Await**: Use for API calls and async operations
5. **Combine**: For reactive data binding where needed

### State Management
```swift
// AppState.swift - Global state container
@MainActor
class AppState: ObservableObject {
    @Published var isOnboarded: Bool = false
    @Published var userProfile: UserProfile?
    @Published var currentWorkout: WorkoutSession?
    @Published var workoutLogs: [WorkoutLog] = []
    @Published var customRoutines: [String: WorkoutRoutine] = [:]
    
    // Timer state
    @Published var isWorkoutStarted: Bool = false
    @Published var isPaused: Bool = false
    @Published var elapsedTime: Int = 0
    
    private var timer: Timer?
    
    init() {
        loadFromStorage()
    }
    
    func startWorkout() { ... }
    func pauseWorkout() { ... }
    func resumeWorkout() { ... }
    func resetWorkout() { ... }
}
```

---

## Data Models

### UserProfile
```swift
struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var createdAt: Date = Date()
}
```

### WorkoutLog
```swift
struct WorkoutLog: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var type: WorkoutType // PUSH, PULL, LEGS, REST
    var completed: Bool = false
    var duration: Int = 0 // seconds
    var sets: [ExerciseSet] = []
}
```

### ExerciseSet
```swift
struct ExerciseSet: Codable, Identifiable {
    var id: UUID = UUID()
    var exerciseId: String
    var exerciseName: String
    var setNumber: Int
    var reps: Int
    var weight: Double // kg
    var completed: Bool = false
}
```

### Exercise
```swift
struct Exercise: Codable, Identifiable {
    var id: String
    var name: String
    var sets: Int
    var reps: String // e.g., "6-8"
    var isCompound: Bool
    var restTime: String // e.g., "2-4 min"
    var restSeconds: Int
    var muscleWikiId: Int? // For API lookup
}
```

### WorkoutRoutine
```swift
struct WorkoutRoutine: Codable, Identifiable {
    var id: String { type.rawValue }
    var type: WorkoutType
    var title: String
    var subtitle: String
    var exercises: [Exercise]
    var warmup: [String]
    var cooldown: [String]
}

enum WorkoutType: String, Codable, CaseIterable {
    case push = "PUSH"
    case pull = "PULL"
    case legs = "LEGS"
    case rest = "REST"
}
```

### MuscleWiki Exercise (API Response)
```swift
struct MuscleWikiExercise: Codable, Identifiable {
    let id: Int
    let name: String
    let primaryMuscles: [String]?
    let category: String?
    let force: String?
    let grips: [String]?
    let mechanic: String?
    let difficulty: String?
    let steps: [String]?
    let videos: [ExerciseVideo]?
    
    struct ExerciseVideo: Codable {
        let url: String
        let gender: String?
        let angle: String?
    }
}
```

---

## Screens & Features

### 1. Launch Screen
- Animated logo with scale/fade animation
- Gradient background matching app theme
- Transition to onboarding or home based on `isOnboarded` state

```swift
struct LaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Image("gym-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0)
                
                Text("Gym-Baazi")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}
```

### 2. Onboarding Flow
Multi-step onboarding to collect user info:

**Step 1: Name Input**
```swift
struct NameInputView: View {
    @Binding var name: String
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What should we call you?")
                .font(.title.bold())
            
            TextField("Your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
            
            Button("Continue") { onNext() }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
        }
        .padding()
    }
}
```

**Step 2: Body Metrics**
```swift
struct BodyMetricsView: View {
    @Binding var age: Int
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Tell us about yourself")
                .font(.title.bold())
            
            Stepper("Age: \(age)", value: $age, in: 13...100)
            
            VStack {
                Text("Height: \(Int(heightCm)) cm")
                Slider(value: $heightCm, in: 100...250, step: 1)
            }
            
            VStack {
                Text("Weight: \(String(format: "%.1f", weightKg)) kg")
                Slider(value: $weightKg, in: 30...200, step: 0.5)
            }
        }
        .padding()
    }
}
```

### 3. Home Screen (Dashboard)
- Greeting with user's name
- Day streak display
- Today's workout card with gradient based on type (Push=Orange, Pull=Cyan, Legs=Purple)
- Start workout button / Timer controls if in progress
- Daily motivational quote
- Personal records grid
- Weekly progress tracker (Mon-Sun with completion indicators)

### 4. Workout Session Screen
- Compact header card: workout title, elapsed timer, progress
- Exercise list with expandable cards
- Per-set logging: tap to open picker for weight/reps
- Rest timer modal with countdown
- Complete workout button -> saves to history

### 5. Exercise Library Screen
- Tab bar for workout types (Push, Pull, Legs)
- Exercise cards showing:
  - Exercise name
  - Muscle badges (primary/secondary)
  - Video thumbnail
- Tap to expand: full video player, instructions, sets/reps info
- **+ Button**: Add exercise to current day's routine

### 6. Workout Customization
Allow users to customize their workout days:

```swift
struct WorkoutCustomizerView: View {
    @EnvironmentObject var appState: AppState
    @State var workoutType: WorkoutType
    @State private var showingExercisePicker = false
    
    var body: some View {
        List {
            ForEach(appState.customRoutines[workoutType.rawValue]?.exercises ?? []) { exercise in
                ExerciseRow(exercise: exercise)
            }
            .onDelete(perform: deleteExercise)
            .onMove(perform: moveExercise)
            
            Button(action: { showingExercisePicker = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Exercise")
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(workoutType: workoutType)
        }
    }
}
```

### 7. History Screen
- Calendar picker (highlight completed workout days)
- List of recent workouts (expandable)
- Per-workout details: sets completed, total volume, exercises breakdown
- Delete workout with confirmation dialog

### 8. Settings Screen
- User profile display/edit
- Notification preferences
- Reset workout schedule
- About/version info

---

## Detailed Workout Customization Flow

### Complete + Button Interaction Flow

The workout customization feature allows users to build their own routines. Here's the complete end-to-end flow:

#### 1. Entry Points for Adding Exercises
```swift
// From Workout Session - floating + button
struct WorkoutSessionView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddExercise = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Exercise list content...
            
            // Floating Add Button
            Button(action: {
                HapticService.shared.medium()
                showAddExercise = true
            }) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(LinearGradient.push)
                            .shadow(radius: 8)
                    )
            }
            .padding()
            .sheet(isPresented: $showAddExercise) {
                AddExerciseFlow(workoutType: appState.todayWorkoutType)
            }
        }
    }
}
```

#### 2. Add Exercise Flow (Full Implementation)
```swift
struct AddExerciseFlow: View {
    let workoutType: WorkoutType
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ExercisePickerViewModel()
    
    @State private var selectedExercise: MuscleWikiExercise?
    @State private var customSets: Int = 3
    @State private var customReps: String = "8-10"
    @State private var restSeconds: Int = 90
    @State private var step: AddExerciseStep = .browse
    
    enum AddExerciseStep {
        case browse      // Browse/search exercises
        case configure   // Set sets, reps, rest time
        case confirm     // Review and add
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .browse:
                    ExerciseBrowserView(
                        viewModel: viewModel,
                        workoutType: workoutType,
                        onSelect: { exercise in
                            selectedExercise = exercise
                            step = .configure
                        }
                    )
                case .configure:
                    ExerciseConfigureView(
                        exercise: selectedExercise!,
                        sets: $customSets,
                        reps: $customReps,
                        restSeconds: $restSeconds,
                        onConfirm: { step = .confirm },
                        onBack: { step = .browse }
                    )
                case .confirm:
                    ExerciseConfirmView(
                        exercise: selectedExercise!,
                        sets: customSets,
                        reps: customReps,
                        restSeconds: restSeconds,
                        onAdd: addExerciseToRoutine,
                        onBack: { step = .configure }
                    )
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var stepTitle: String {
        switch step {
        case .browse: return "Add Exercise"
        case .configure: return "Configure"
        case .confirm: return "Confirm"
        }
    }
    
    private func addExerciseToRoutine() {
        guard let apiExercise = selectedExercise else { return }
        
        // Create app exercise from API exercise
        let newExercise = Exercise(
            id: "custom_\(UUID().uuidString.prefix(8))",
            name: apiExercise.name,
            sets: customSets,
            reps: customReps,
            isCompound: apiExercise.mechanic == "compound",
            restTime: formatRestTime(restSeconds),
            restSeconds: restSeconds,
            muscleWikiId: apiExercise.id
        )
        
        // Add to custom routine
        appState.addExerciseToRoutine(newExercise, for: workoutType)
        
        // Haptic feedback
        HapticService.shared.success()
        
        // Dismiss
        dismiss()
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        let mins = seconds / 60
        let secs = seconds % 60
        return secs > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(mins) min"
    }
}
```

#### 3. Exercise Browser View with Search
```swift
struct ExerciseBrowserView: View {
    @ObservedObject var viewModel: ExercisePickerViewModel
    let workoutType: WorkoutType
    let onSelect: (MuscleWikiExercise) -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search exercises...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.categories, id: \.name) { category in
                        CategoryPill(
                            name: category.displayName ?? category.name,
                            isSelected: viewModel.selectedCategory == category.name,
                            action: { viewModel.selectCategory(category.name) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Divider()
            
            // Exercise list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredExercises(searchText)) { exercise in
                    ExercisePickerRow(exercise: exercise)
                        .onTapGesture {
                            HapticService.shared.light()
                            onSelect(exercise)
                        }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadExercises(for: workoutType)
        }
    }
}
```

#### 4. Exercise Configure View
```swift
struct ExerciseConfigureView: View {
    let exercise: MuscleWikiExercise
    @Binding var sets: Int
    @Binding var reps: String
    @Binding var restSeconds: Int
    let onConfirm: () -> Void
    let onBack: () -> Void
    
    private let repOptions = ["4-6", "6-8", "8-10", "10-12", "12-15", "15-20"]
    private let restOptions = [30, 60, 90, 120, 180, 240]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Exercise header
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.title2.bold())
                    
                    if let muscles = exercise.primaryMuscles {
                        HStack {
                            ForEach(muscles, id: \.self) { muscle in
                                MuscleBadge(muscle: muscle, isPrimary: true)
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // Sets picker
                VStack(spacing: 12) {
                    Text("Number of Sets")
                        .font(.headline)
                    
                    Stepper(value: $sets, in: 1...10) {
                        HStack {
                            Text("\(sets)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text("sets")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: sets) { HapticService.shared.light() }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Reps picker
                VStack(spacing: 12) {
                    Text("Rep Range")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(repOptions, id: \.self) { option in
                            Button(option) {
                                reps = option
                                HapticService.shared.light()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(reps == option ? .blue : .gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Rest time picker
                VStack(spacing: 12) {
                    Text("Rest Time")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(restOptions, id: \.self) { seconds in
                            Button(formatRest(seconds)) {
                                restSeconds = seconds
                                HapticService.shared.light()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(restSeconds == seconds ? .cyan : .gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button("Back", action: onBack)
                    .buttonStyle(.bordered)
                
                Button("Next", action: onConfirm)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    private func formatRest(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let mins = seconds / 60
        return "\(mins)m"
    }
}
```

#### 5. AppState Methods for Routine Management
```swift
// In AppState.swift
extension AppState {
    /// Add exercise to a workout type's routine
    func addExerciseToRoutine(_ exercise: Exercise, for type: WorkoutType) {
        var routine = customRoutines[type.rawValue] ?? getDefaultRoutine(for: type)
        routine.exercises.append(exercise)
        customRoutines[type.rawValue] = routine
        saveRoutines()
    }
    
    /// Remove exercise from routine
    func removeExercise(at index: Int, from type: WorkoutType) {
        guard var routine = customRoutines[type.rawValue] else { return }
        routine.exercises.remove(at: index)
        customRoutines[type.rawValue] = routine
        saveRoutines()
    }
    
    /// Reorder exercises in routine
    func moveExercise(from source: IndexSet, to destination: Int, in type: WorkoutType) {
        guard var routine = customRoutines[type.rawValue] else { return }
        routine.exercises.move(fromOffsets: source, toOffset: destination)
        customRoutines[type.rawValue] = routine
        saveRoutines()
    }
    
    /// Get routine for workout type (custom or default)
    func getRoutine(for type: WorkoutType) -> WorkoutRoutine {
        customRoutines[type.rawValue] ?? getDefaultRoutine(for: type)
    }
    
    private func saveRoutines() {
        StorageService.shared.customRoutines = customRoutines
    }
    
    private func getDefaultRoutine(for type: WorkoutType) -> WorkoutRoutine {
        DefaultWorkoutData.routines[type]!
    }
}
```

#### 6. Persisting Custom Routines
```swift
// Custom routines are automatically persisted via StorageService
// whenever addExerciseToRoutine/removeExercise/moveExercise is called

// On app launch, routines are loaded:
class AppState: ObservableObject {
    init() {
        // Load custom routines from storage
        self.customRoutines = StorageService.shared.customRoutines
        
        // If no custom routines exist, use defaults
        if customRoutines.isEmpty {
            initializeDefaultRoutines()
        }
    }
    
    private func initializeDefaultRoutines() {
        for type in WorkoutType.allCases {
            if type != .rest {
                customRoutines[type.rawValue] = DefaultWorkoutData.routines[type]
            }
        }
        saveRoutines()
    }
}
```

---

## Detailed Workout Session & Set Logging

### Complete Set Tracking Flow

```swift
struct WorkoutSessionView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WorkoutSessionViewModel()
    @State private var showRestTimer = false
    @State private var currentRestDuration = 90
    @State private var selectedExerciseIndex: Int?
    @State private var selectedSetIndex: Int?
    @State private var showSetPicker = false
    
    var routine: WorkoutRoutine {
        appState.getRoutine(for: appState.todayWorkoutType)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header card
                    WorkoutHeaderCard(
                        title: routine.title,
                        elapsedTime: appState.elapsedTime,
                        progress: viewModel.completionProgress
                    )
                    
                    // Exercise cards
                    ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { exIndex, exercise in
                        ExerciseSessionCard(
                            exercise: exercise,
                            sets: viewModel.getSets(for: exercise.id),
                            onSetTap: { setIndex in
                                selectedExerciseIndex = exIndex
                                selectedSetIndex = setIndex
                                showSetPicker = true
                                HapticService.shared.light()
                            },
                            onSetComplete: { setIndex in
                                viewModel.toggleSetCompletion(exerciseId: exercise.id, setIndex: setIndex)
                                HapticService.shared.medium()
                                
                                // Show rest timer after completing a set
                                currentRestDuration = exercise.restSeconds
                                showRestTimer = true
                            }
                        )
                    }
                    
                    // Complete workout button
                    Button(action: completeWorkout) {
                        Text("Complete Workout")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.allSetsCompleted ? Color.green : Color.gray)
                            .cornerRadius(16)
                    }
                    .disabled(!viewModel.allSetsCompleted)
                    .padding(.top, 24)
                }
                .padding()
            }
            
            // Rest timer overlay
            if showRestTimer {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { } // Prevent dismiss on tap
                
                RestTimerView(
                    duration: currentRestDuration,
                    isPresented: $showRestTimer
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSetPicker) {
            if let exIndex = selectedExerciseIndex,
               let setIndex = selectedSetIndex {
                SetInputSheet(
                    exercise: routine.exercises[exIndex],
                    setIndex: setIndex,
                    currentWeight: viewModel.getWeight(for: routine.exercises[exIndex].id, setIndex: setIndex),
                    currentReps: viewModel.getReps(for: routine.exercises[exIndex].id, setIndex: setIndex),
                    onSave: { weight, reps in
                        viewModel.updateSet(
                            exerciseId: routine.exercises[exIndex].id,
                            setIndex: setIndex,
                            weight: weight,
                            reps: reps
                        )
                        HapticService.shared.success()
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            viewModel.initializeSets(from: routine)
        }
    }
    
    private func completeWorkout() {
        // Create workout log
        let log = WorkoutLog(
            date: Date(),
            type: appState.todayWorkoutType,
            completed: true,
            duration: appState.elapsedTime,
            sets: viewModel.getAllSets()
        )
        
        // Save to storage
        appState.saveWorkoutLog(log)
        
        // Reset timer
        appState.resetWorkout()
        
        // Haptic & toast feedback
        HapticService.shared.success()
        
        // Navigate back or show completion
    }
}
```

### Set Input Sheet (Weight/Reps Picker)
```swift
struct SetInputSheet: View {
    let exercise: Exercise
    let setIndex: Int
    @State var currentWeight: Double
    @State var currentReps: Int
    let onSave: (Double, Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    // Presets based on exercise type
    var weightPresets: [Double] {
        exercise.isCompound 
            ? [20, 40, 60, 80, 100, 120]
            : [5, 10, 15, 20, 25, 30]
    }
    
    var repPresets: [Int] {
        let range = parseRepRange(exercise.reps)
        return Array(stride(from: range.lower, through: range.upper + 4, by: 2))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise info
                VStack(spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("Set \(setIndex + 1) of \(exercise.sets)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Weight picker
                VStack(spacing: 12) {
                    Text("Weight (kg)")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if currentWeight >= 2.5 {
                                currentWeight -= 2.5
                                HapticService.shared.light()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                        }
                        
                        Text(String(format: "%.1f", currentWeight))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(minWidth: 120)
                        
                        Button(action: {
                            currentWeight += 2.5
                            HapticService.shared.light()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                    
                    // Quick presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(weightPresets, id: \.self) { weight in
                                Button("\(Int(weight))") {
                                    currentWeight = weight
                                    HapticService.shared.medium()
                                }
                                .buttonStyle(.bordered)
                                .tint(currentWeight == weight ? .orange : .secondary)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Reps picker
                VStack(spacing: 12) {
                    Text("Reps")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if currentReps > 1 {
                                currentReps -= 1
                                HapticService.shared.light()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                        }
                        
                        Text("\(currentReps)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .frame(minWidth: 80)
                        
                        Button(action: {
                            currentReps += 1
                            HapticService.shared.light()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                    
                    // Quick presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(repPresets, id: \.self) { rep in
                                Button("\(rep)") {
                                    currentReps = rep
                                    HapticService.shared.medium()
                                }
                                .buttonStyle(.bordered)
                                .tint(currentReps == rep ? .cyan : .secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Log Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(currentWeight, currentReps)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func parseRepRange(_ reps: String) -> (lower: Int, upper: Int) {
        let parts = reps.split(separator: "-").compactMap { Int($0) }
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (8, 12)
    }
}
```

---

## MuscleWiki API Integration

### API Configuration
```swift
// MuscleWikiService.swift
class MuscleWikiService {
    static let shared = MuscleWikiService()
    
    private let baseURL = "https://musclewiki-api.p.rapidapi.com"
    private let apiKey = "YOUR_RAPIDAPI_KEY" // Store securely
    private let apiHost = "musclewiki-api.p.rapidapi.com"
    
    private var headers: [String: String] {
        [
            "X-RapidAPI-Key": apiKey,
            "X-RapidAPI-Host": apiHost
        ]
    }
    
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
        return try await request(url: components.url!)
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
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Response models
struct ExerciseListResponse: Codable {
    let total: Int
    let limit: Int
    let offset: Int
    let count: Int
    let results: [MuscleWikiExercise]
}

struct MuscleCategory: Codable, Identifiable {
    let name: String
    let displayName: String?
    let count: Int
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case count
    }
}

struct EquipmentCategory: Codable, Identifiable {
    let name: String
    let displayName: String?
    let count: Int
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case count
    }
}

enum APIError: Error {
    case invalidResponse
    case decodingError
    case networkError(Error)
}
```

### Usage in ViewModel
```swift
@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [MuscleWikiExercise] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service = MuscleWikiService.shared
    
    func loadExercises(for workoutType: WorkoutType) async {
        isLoading = true
        do {
            let response: ExerciseListResponse
            switch workoutType {
            case .push:
                response = try await service.getPushExercises(limit: 50)
            case .pull:
                response = try await service.getPullExercises(limit: 50)
            case .legs:
                response = try await service.getExercises(limit: 50, muscles: "Quadriceps,Hamstrings,Glutes,Calves")
            case .rest:
                response = try await service.getExercises(limit: 20, category: "stretching")
            }
            exercises = response.results
        } catch {
            self.error = error
        }
        isLoading = false
    }
    
    func searchExercises(query: String) async {
        guard query.count >= 2 else { return }
        isLoading = true
        do {
            let response = try await service.searchExercises(query: query)
            exercises = response.results
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
```

### Caching & Offline Strategy

```swift
// ExerciseCache.swift - Local caching for API responses
actor ExerciseCache {
    static let shared = ExerciseCache()
    
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 24 * 60 * 60 // 24 hours
    private var memoryCache: [String: CachedData] = [:]
    
    struct CachedData {
        let data: Data
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > ExerciseCache.shared.maxCacheAge
        }
    }
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("MuscleWikiCache")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Cache Operations
    
    func get<T: Decodable>(_ key: String) async throws -> T? {
        // Check memory cache first
        if let cached = memoryCache[key], !cached.isExpired {
            return try JSONDecoder().decode(T.self, from: cached.data)
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash + ".json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        if let modDate = attributes[.modificationDate] as? Date {
            let age = Date().timeIntervalSince(modDate)
            if age > maxCacheAge {
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }
        
        let data = try Data(contentsOf: fileURL)
        memoryCache[key] = CachedData(data: data, timestamp: Date())
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func set<T: Encodable>(_ value: T, for key: String) async throws {
        let data = try JSONEncoder().encode(value)
        memoryCache[key] = CachedData(data: data, timestamp: Date())
        
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash + ".json")
        try data.write(to: fileURL)
    }
    
    func clearExpired() async {
        memoryCache = memoryCache.filter { !$0.value.isExpired }
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        
        for file in files {
            if let date = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                if Date().timeIntervalSince(date) > maxCacheAge {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }
    }
}

extension String {
    var sha256Hash: String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash) }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
```

### Enhanced MuscleWiki Service with Caching
```swift
class MuscleWikiService {
    // ... existing code ...
    
    private let cache = ExerciseCache.shared
    
    /// Get exercises with caching
    func getExercisesCached(
        limit: Int = 20,
        category: String? = nil,
        muscles: String? = nil
    ) async throws -> ExerciseListResponse {
        let cacheKey = "exercises_\(limit)_\(category ?? "all")_\(muscles ?? "all")"
        
        // Try cache first
        if let cached: ExerciseListResponse = try? await cache.get(cacheKey) {
            return cached
        }
        
        // Fetch from API
        let response = try await getExercises(limit: limit, category: category, muscles: muscles)
        
        // Cache the result
        try? await cache.set(response, for: cacheKey)
        
        return response
    }
    
    /// Get exercise detail with caching
    func getExerciseCached(id: Int) async throws -> MuscleWikiExercise {
        let cacheKey = "exercise_\(id)"
        
        if let cached: MuscleWikiExercise = try? await cache.get(cacheKey) {
            return cached
        }
        
        let exercise = try await getExercise(id: id, detail: true)
        try? await cache.set(exercise, for: cacheKey)
        
        return exercise
    }
}
```

### Video Streaming with AVPlayer
```swift
import AVKit

struct ExerciseVideoPlayer: View {
    let exercise: MuscleWikiExercise
    @State private var player: AVPlayer?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "video.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
        .task { await loadVideo() }
    }
    
    private func loadVideo() async {
        guard let video = exercise.videos?.first,
              let videoURL = MuscleWikiService.shared.getBrandedVideoURL(filename: video.url) else {
            isLoading = false
            return
        }
        
        // Create request with auth headers
        var request = URLRequest(url: videoURL)
        request.setValue("YOUR_RAPIDAPI_KEY", forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("musclewiki-api.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        // For authenticated streaming, use AVAsset with custom resource loader
        // or proxy through your own server if needed
        
        await MainActor.run {
            player = AVPlayer(url: videoURL)
            isLoading = false
        }
    }
}
```

### Mapping API to App Screens

| Screen | API Endpoint | Usage |
|--------|-------------|-------|
| Exercise Library (Push) | `GET /workouts/push` | Load push exercises |
| Exercise Library (Pull) | `GET /workouts/pull` | Load pull exercises |
| Exercise Library (Legs) | `GET /exercises?muscles=Quadriceps,Hamstrings,Glutes,Calves` | Load leg exercises |
| Exercise Detail | `GET /exercises/{id}?detail=true` | Show full details + video |
| Add Exercise (+) | `GET /search?q={query}` | Search when adding |
| Categories Filter | `GET /categories` | Equipment filter pills |
| Muscle Filter | `GET /muscles` | Muscle group filter |

---

## Comprehensive Local Storage Plan

### Data Lifecycle Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP LAUNCH                                │
├─────────────────────────────────────────────────────────────────┤
│  1. Check isOnboarded flag                                      │
│  2. If false → Show Onboarding Flow                             │
│  3. If true → Load all data from UserDefaults                   │
│     ├─ UserProfile                                              │
│     ├─ WorkoutLogs[]                                            │
│     ├─ CustomRoutines{}                                         │
│     └─ UserSettings                                             │
│  4. Initialize AppState with loaded data                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DURING APP USE                               │
├─────────────────────────────────────────────────────────────────┤
│  • Workout Session Active:                                      │
│    - Timer state kept in memory (AppState)                      │
│    - Sets logged in memory until completion                     │
│    - On workout complete → Save WorkoutLog to storage           │
│                                                                  │
│  • Exercise Customization:                                      │
│    - Add/remove/reorder → Immediately persist CustomRoutines    │
│                                                                  │
│  • Settings Changes:                                            │
│    - Any change → Immediately persist UserSettings              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      APP BACKGROUND                              │
├─────────────────────────────────────────────────────────────────┤
│  • Timer continues if workout active (background task)          │
│  • Pending workout data auto-saved on scenePhase change         │
└─────────────────────────────────────────────────────────────────┘
```

### Complete StorageService Implementation

```swift
import Foundation

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
        static let userSettings = "gymbaazi_userSettings"
        static let lastActiveWorkout = "gymbaazi_lastActiveWorkout"
        static let exerciseCache = "gymbaazi_exerciseCache"
    }
    
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
    
    // MARK: - Data Export/Import (for backup)
    
    func exportAllData() -> Data? {
        let backup = BackupData(
            userProfile: userProfile,
            workoutLogs: workoutLogs,
            customRoutines: customRoutines,
            userSettings: userSettings,
            exportedAt: Date()
        )
        return try? encoder.encode(backup)
    }
    
    func importData(from data: Data) -> Bool {
        guard let backup = try? decoder.decode(BackupData.self, from: data) else {
            return false
        }
        
        userProfile = backup.userProfile
        workoutLogs = backup.workoutLogs
        customRoutines = backup.customRoutines
        userSettings = backup.userSettings
        
        return true
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

struct BackupData: Codable {
    let userProfile: UserProfile?
    let workoutLogs: [WorkoutLog]
    let customRoutines: [String: WorkoutRoutine]
    let userSettings: UserSettings
    let exportedAt: Date
}

struct UserSettings: Codable {
    var notificationsEnabled: Bool = true
    var restTimerSound: Bool = true
    var hapticFeedback: Bool = true
    var darkModeOverride: Bool? = nil // nil = system
}
```

### Timer State Management with Background Support

```swift
// In AppState.swift
extension AppState {
    // MARK: - Timer with Background Support
    
    func startWorkout() {
        guard !isWorkoutStarted else { return }
        
        isWorkoutStarted = true
        isPaused = false
        workoutStartTime = Date()
        elapsedTime = 0
        
        startTimer()
        saveWorkoutState()
    }
    
    func pauseWorkout() {
        isPaused = true
        timer?.invalidate()
        saveWorkoutState()
    }
    
    func resumeWorkout() {
        isPaused = false
        startTimer()
        saveWorkoutState()
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
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }
    
    private func saveWorkoutState() {
        guard isWorkoutStarted, let startTime = workoutStartTime else { return }
        StorageService.shared.saveActiveWorkoutState(
            workoutType: todayWorkoutType,
            startTime: startTime,
            elapsedTime: elapsedTime,
            completedSets: currentSets
        )
    }
    
    // Call on app launch to recover interrupted workout
    func recoverActiveWorkout() {
        guard let state = StorageService.shared.lastActiveWorkout else { return }
        
        // Only recover if less than 2 hours old
        let age = Date().timeIntervalSince(state.savedAt)
        guard age < 2 * 60 * 60 else {
            StorageService.shared.clearActiveWorkoutState()
            return
        }
        
        // Restore state
        isWorkoutStarted = true
        isPaused = true // Start paused, let user resume
        workoutStartTime = state.startTime
        elapsedTime = state.elapsedTime + Int(age) // Add time since save
        currentSets = state.completedSets
    }
}
```

### Scene Phase Handling for State Persistence

```swift
// In ContentView.swift or App entry
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        MainTabView()
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .background:
                    // Save any pending state
                    if appState.isWorkoutStarted {
                        appState.saveWorkoutState()
                    }
                case .active:
                    // Recalculate elapsed time if workout was active
                    if appState.isWorkoutStarted && !appState.isPaused {
                        appState.recalculateElapsedTime()
                    }
                case .inactive:
                    break
                @unknown default:
                    break
                }
            }
            .onAppear {
                // Try to recover interrupted workout on launch
                appState.recoverActiveWorkout()
            }
    }
}
```

---

## UI Components

### Glassmorphism Card
```swift
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
```

### Gradient Backgrounds
```swift
extension LinearGradient {
    static let push = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let pull = LinearGradient(
        colors: [Color.cyan, Color.blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let legs = LinearGradient(
        colors: [Color.purple, Color.pink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rest = LinearGradient(
        colors: [Color.green, Color.teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
```

### Stepper Picker (Weight/Reps)
```swift
struct StepperPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let label: String
    let presets: [Int]
    
    var body: some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.headline)
            
            HStack(spacing: 20) {
                Button("-") {
                    if value - step >= range.lowerBound {
                        value -= step
                        HapticService.shared.light()
                    }
                }
                .buttonStyle(.bordered)
                
                Text("\(value)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .frame(minWidth: 100)
                
                Button("+") {
                    if value + step <= range.upperBound {
                        value += step
                        HapticService.shared.light()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            // Quick presets
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button("\(preset)") {
                        value = preset
                        HapticService.shared.medium()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(value == preset ? .primary : .secondary)
                }
            }
        }
    }
}
```

### Rest Timer Modal
```swift
struct RestTimerView: View {
    let duration: Int
    @Binding var isPresented: Bool
    @State private var remainingTime: Int
    @State private var timer: Timer?
    
    init(duration: Int, isPresented: Binding<Bool>) {
        self.duration = duration
        self._isPresented = isPresented
        self._remainingTime = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Time")
                .font(.title2.bold())
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: CGFloat(remainingTime) / CGFloat(duration))
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remainingTime)
                
                Text(formatTime(remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
            }
            .frame(width: 200, height: 200)
            
            HStack(spacing: 16) {
                Button("Skip") {
                    stopTimer()
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("+30s") {
                    remainingTime += 30
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                HapticService.shared.heavy()
                stopTimer()
                isPresented = false
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
```

### Muscle Badge
```swift
struct MuscleBadge: View {
    let muscle: String
    let isPrimary: Bool
    
    var body: some View {
        Text(muscle)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPrimary ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundColor(isPrimary ? .orange : .gray)
            .clipShape(Capsule())
    }
}
```

---

## Animations & Haptics

### Haptic Service
```swift
class HapticService {
    static let shared = HapticService()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    func light() {
        lightGenerator.impactOccurred()
    }
    
    func medium() {
        mediumGenerator.impactOccurred()
    }
    
    func heavy() {
        heavyGenerator.impactOccurred()
    }
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
```

### Animation Patterns
```swift
// Staggered list animation
struct AnimatedList<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View {
    let data: Data
    let content: (Data.Element) -> Content
    
    var body: some View {
        ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
            content(item)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
                .animation(.spring(duration: 0.4).delay(Double(index) * 0.08), value: data.count)
        }
    }
}

// Button bounce effect
struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

// Card hover effect
extension View {
    func cardHover() -> some View {
        self.modifier(CardHoverModifier())
    }
}

struct CardHoverModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(radius: isHovered ? 12 : 6)
            .onTapGesture {
                withAnimation(.spring(duration: 0.2)) {
                    isHovered = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(duration: 0.2)) {
                        isHovered = false
                    }
                }
            }
    }
}
```

---

## Local Storage

### Using UserDefaults + Codable
```swift
class StorageService {
    static let shared = StorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // Keys
    private enum Keys {
        static let isOnboarded = "isOnboarded"
        static let userProfile = "userProfile"
        static let workoutLogs = "workoutLogs"
        static let customRoutines = "customRoutines"
        static let userSettings = "userSettings"
    }
    
    // MARK: - User Profile
    
    var isOnboarded: Bool {
        get { defaults.bool(forKey: Keys.isOnboarded) }
        set { defaults.set(newValue, forKey: Keys.isOnboarded) }
    }
    
    var userProfile: UserProfile? {
        get { load(key: Keys.userProfile) }
        set { save(newValue, key: Keys.userProfile) }
    }
    
    // MARK: - Workout Logs
    
    var workoutLogs: [WorkoutLog] {
        get { load(key: Keys.workoutLogs) ?? [] }
        set { save(newValue, key: Keys.workoutLogs) }
    }
    
    func addWorkoutLog(_ log: WorkoutLog) {
        var logs = workoutLogs
        // Replace if same date exists
        if let index = logs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: log.date) }) {
            logs[index] = log
        } else {
            logs.append(log)
        }
        workoutLogs = logs
    }
    
    func deleteWorkoutLog(id: UUID) {
        workoutLogs = workoutLogs.filter { $0.id != id }
    }
    
    // MARK: - Custom Routines
    
    var customRoutines: [String: WorkoutRoutine] {
        get { load(key: Keys.customRoutines) ?? [:] }
        set { save(newValue, key: Keys.customRoutines) }
    }
    
    func updateRoutine(_ routine: WorkoutRoutine) {
        var routines = customRoutines
        routines[routine.type.rawValue] = routine
        customRoutines = routines
    }
    
    // MARK: - Helpers
    
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
```

### Alternative: SwiftData (iOS 17+)
```swift
import SwiftData

@Model
class WorkoutLogModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: String
    var completed: Bool
    var duration: Int
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSetModel]
    
    init(date: Date, type: WorkoutType, completed: Bool = false) {
        self.id = UUID()
        self.date = date
        self.type = type.rawValue
        self.completed = completed
        self.duration = 0
        self.sets = []
    }
}

@Model
class ExerciseSetModel {
    var id: UUID
    var exerciseId: String
    var exerciseName: String
    var setNumber: Int
    var reps: Int
    var weight: Double
    var completed: Bool
    
    init(exerciseId: String, exerciseName: String, setNumber: Int) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.reps = 0
        self.weight = 0
        self.completed = false
    }
}

// Configure in App
@main
struct GymBaaziApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutLogModel.self, ExerciseSetModel.self])
    }
}
```

---

## PPL Workout Scheduler

```swift
struct WorkoutScheduler {
    // Day-based workout schedule
    // Monday (2) & Thursday (5) = LEGS
    // Tuesday (3) & Friday (6) = PUSH
    // Wednesday (4) & Saturday (7) = PULL
    // Sunday (1) = REST
    
    static func getWorkoutType(for date: Date = Date()) -> WorkoutType {
        let weekday = Calendar.current.component(.weekday, from: date)
        
        switch weekday {
        case 1: return .rest      // Sunday
        case 2, 5: return .legs   // Monday, Thursday
        case 3, 6: return .push   // Tuesday, Friday
        case 4, 7: return .pull   // Wednesday, Saturday
        default: return .rest
        }
    }
    
    static func getWeekSchedule() -> [(day: String, type: WorkoutType)] {
        [
            ("Mon", .legs),
            ("Tue", .push),
            ("Wed", .pull),
            ("Thu", .legs),
            ("Fri", .push),
            ("Sat", .pull),
            ("Sun", .rest)
        ]
    }
}
```

---

## Motivational Quotes

```swift
struct Quote: Identifiable {
    let id = UUID()
    let text: String
    let author: String
}

struct QuoteService {
    static let quotes: [Quote] = [
        Quote(text: "The only bad workout is the one that didn't happen.", author: "Unknown"),
        Quote(text: "Your body can stand almost anything. It's your mind you have to convince.", author: "Unknown"),
        Quote(text: "The pain you feel today will be the strength you feel tomorrow.", author: "Arnold Schwarzenegger"),
        Quote(text: "Don't count the days, make the days count.", author: "Muhammad Ali"),
        Quote(text: "Success is usually the culmination of controlling failure.", author: "Sylvester Stallone"),
        Quote(text: "The only way to define your limits is by going beyond them.", author: "Arthur C. Clarke"),
        Quote(text: "Strength does not come from the body. It comes from the will.", author: "Unknown"),
        Quote(text: "The difference between try and triumph is a little umph.", author: "Marvin Phillips"),
        Quote(text: "Push harder than yesterday if you want a different tomorrow.", author: "Unknown"),
        Quote(text: "Wake up with determination. Go to bed with satisfaction.", author: "Unknown"),
        Quote(text: "It never gets easier, you just get stronger.", author: "Unknown"),
        Quote(text: "Sweat is just fat crying.", author: "Unknown"),
        Quote(text: "The gym is my therapy.", author: "Unknown"),
        Quote(text: "Champions train, losers complain.", author: "Unknown"),
        Quote(text: "Your only limit is you.", author: "Unknown")
    ]
    
    static func getDailyQuote() -> Quote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }
}
```

---

## Implementation Checklist

### Phase 1: Core Setup
- [ ] Create Xcode project with SwiftUI
- [ ] Set up folder structure as defined
- [ ] Configure app icons and launch screen assets
- [ ] Implement data models (UserProfile, WorkoutLog, Exercise, etc.)
- [ ] Set up StorageService with UserDefaults

### Phase 2: Onboarding
- [ ] Create LaunchScreen with animation
- [ ] Implement OnboardingView container with navigation
- [ ] Build NameInputView
- [ ] Build BodyMetricsView (age, height, weight pickers)
- [ ] Save profile and transition to main app

### Phase 3: Home Screen
- [ ] Build HomeView layout with greeting
- [ ] Implement streak counter
- [ ] Create gradient workout card based on day type
- [ ] Add timer controls (start/pause/stop)
- [ ] Implement daily quote display
- [ ] Build weekly progress tracker
- [ ] Add PR cards (mock data initially)

### Phase 4: Workout Session
- [ ] Build WorkoutSessionView
- [ ] Create exercise list with expandable cards
- [ ] Implement StepperPicker for weight/reps
- [ ] Build RestTimerView modal
- [ ] Add set completion tracking
- [ ] Implement workout completion with save to history

### Phase 5: Exercise Library
- [ ] Set up MuscleWikiService
- [ ] Implement ExerciseLibraryViewModel
- [ ] Build exercise list with tab filtering
- [ ] Create ExerciseDetailView with video player
- [ ] Add muscle badges
- [ ] Implement search functionality

### Phase 6: Workout Customization
- [ ] Build WorkoutCustomizerView
- [ ] Implement add exercise picker
- [ ] Add drag-to-reorder exercises
- [ ] Enable delete exercises
- [ ] Save custom routines to storage

### Phase 7: History
- [ ] Build HistoryView with calendar
- [ ] Create expandable workout log cards
- [ ] Show per-exercise breakdown
- [ ] Implement delete with confirmation
- [ ] Calculate and display volume stats

### Phase 8: Polish
- [ ] Add haptic feedback throughout
- [ ] Implement all animations
- [ ] Test on multiple device sizes
- [ ] Handle edge cases and errors
- [ ] Prepare for TestFlight

---

## Color Theme

```swift
extension Color {
    // Primary gradients
    static let pushStart = Color(hex: "F97316")  // Orange
    static let pushEnd = Color(hex: "EF4444")    // Red
    
    static let pullStart = Color(hex: "06B6D4")  // Cyan
    static let pullEnd = Color(hex: "3B82F6")    // Blue
    
    static let legsStart = Color(hex: "A855F7")  // Purple
    static let legsEnd = Color(hex: "EC4899")    // Pink
    
    static let restStart = Color(hex: "10B981")  // Emerald
    static let restEnd = Color(hex: "14B8A6")    // Teal
    
    // UI Colors
    static let cardBackground = Color(.systemBackground).opacity(0.7)
    static let glassBorder = Color.white.opacity(0.2)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## TestFlight Notes

1. **Bundle ID**: com.yourteam.gymbaazi
2. **Minimum iOS**: 16.0 (or 17.0 if using SwiftData)
3. **Required Capabilities**: None special required
4. **API Key Management**: Store RapidAPI key securely (use Keychain for production)
5. **Privacy**: No user data leaves device (local storage only)

---

## Summary

This document provides a complete blueprint for recreating **Gym-Baazi** as a native SwiftUI iOS app with:

1. **Modern SwiftUI architecture** with MVVM pattern
2. **Local-first storage** using UserDefaults or SwiftData
3. **MuscleWiki API integration** for exercise data and videos
4. **Beautiful UI** with glassmorphism, gradients, and animations
5. **Enhanced features**: onboarding flow, customizable workouts
6. **Haptic feedback** for premium feel on iOS

Good luck building! 💪🏋️‍♂️
