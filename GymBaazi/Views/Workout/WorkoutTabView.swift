import SwiftUI

// MARK: - Design Constants
private enum DesignConstants {
    static let innerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 12
    static let outerRadius: CGFloat = innerRadius + cardPadding // 20
}

/// Workout tab - shows today's workout with expandable exercise cards
struct WorkoutTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddDay = false
    @State private var showDayPicker = false
    @State private var selectedDay: CustomWorkoutDay?
    @State private var expandedExercises: Set<String> = []
    @State private var setData: [String: [SetEntry]] = [:] // exerciseId -> sets
    
    var todayWorkout: CustomWorkoutDay? {
        appState.workoutSchedule.todayWorkout
    }
    
    var totalSets: Int {
        todayWorkout?.exercises.reduce(0) { $0 + $1.sets } ?? 0
    }
    
    var completedSets: Int {
        setData.values.flatMap { $0 }.filter { $0.completed }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header card
                    if let workout = todayWorkout {
                        headerCard(workout)
                    } else {
                        restDayCard
                    }
                    
                    // Exercises
                    if let workout = todayWorkout {
                        exercisesList(workout)
                        
                        // Complete workout button (only visible when workout is active)
                        if appState.isWorkoutStarted {
                            completeWorkoutButton
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showDayPicker = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("\(appState.workoutSchedule.days.count)")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showDayPicker) {
                WorkoutDaysPicker(
                    days: appState.workoutSchedule.days,
                    onAdd: { showAddDay = true },
                    onEdit: { day in selectedDay = day }
                )
            }
            .sheet(isPresented: $showAddDay) {
                DayEditorView(day: nil, existingDays: appState.workoutSchedule.days)
            }
            .sheet(item: $selectedDay) { day in
                DayEditorView(day: day, existingDays: appState.workoutSchedule.days)
            }
            .onAppear {
                initializeSetData()
            }
        }
    }
    
    // MARK: - Initialize Set Data
    
    private func initializeSetData() {
        guard let workout = todayWorkout else { return }
        for exercise in workout.exercises {
            if setData[exercise.id] == nil {
                setData[exercise.id] = (0..<exercise.sets).map { SetEntry(setNumber: $0 + 1) }
            }
        }
    }
    
    // MARK: - Header Card
    
    private func headerCard(_ workout: CustomWorkoutDay) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.name)
                        .font(.title2.bold())
                    
                    Text("\(workout.exercises.count) exercises today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress badge
                Text("\(completedSets)/\(totalSets)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            
            // Timer section (shows when workout is active)
            if appState.isWorkoutStarted {
                timerSection
            } else {
                // Start button
                Button(action: {
                    appState.startWorkout()
                    HapticService.shared.success()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Workout")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                }
            }
        }
        .padding(DesignConstants.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.outerRadius))
    }
    
    // MARK: - Timer Section
    
    private var timerSection: some View {
        VStack(spacing: 12) {
            // Timer display
            Text(appState.formattedElapsedTime)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            
            // Timer controls
            HStack(spacing: 16) {
                // Pause / Resume
                Button(action: {
                    appState.isPaused ? appState.resumeWorkout() : appState.pauseWorkout()
                    HapticService.shared.medium()
                }) {
                    Image(systemName: appState.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                
                // Cancel
                Button(action: {
                    appState.resetWorkout()
                    setData.removeAll()
                    initializeSetData()
                    HapticService.shared.warning()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
    }
    
    // MARK: - Complete Workout Button
    
    private var completeWorkoutButton: some View {
        Button(action: finishWorkout) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Workout")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
        }
    }
    
    // MARK: - Rest Day Card
    
    private var restDayCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Rest Day")
                .font(.title2.bold())
            
            Text("No workout scheduled")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showDayPicker = true }) {
                Text("Manage Workouts")
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.outerRadius))
    }
    
    // MARK: - Exercises List
    
    private func exercisesList(_ workout: CustomWorkoutDay) -> some View {
        VStack(spacing: 12) {
            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                ExpandableExerciseCard(
                    number: index + 1,
                    exercise: exercise,
                    sets: Binding(
                        get: { setData[exercise.id] ?? [] },
                        set: { setData[exercise.id] = $0 }
                    ),
                    isExpanded: expandedExercises.contains(exercise.id),
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if expandedExercises.contains(exercise.id) {
                                expandedExercises.remove(exercise.id)
                            } else {
                                expandedExercises.insert(exercise.id)
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Finish Workout
    
    private func finishWorkout() {
        guard let workout = todayWorkout else { return }
        
        let completedSetsList = setData.flatMap { exerciseId, sets -> [ExerciseSet] in
            guard let exercise = workout.exercises.first(where: { $0.id == exerciseId }) else { return [] }
            return sets.filter { $0.completed }.map { entry in
                ExerciseSet(
                    exerciseId: exerciseId,
                    exerciseName: exercise.name,
                    setNumber: entry.setNumber,
                    reps: entry.reps,
                    weight: entry.kg
                )
            }
        }
        
        let log = WorkoutLog(
            type: .push,
            dayName: workout.name,
            completed: true,
            duration: appState.elapsedTime,
            sets: completedSetsList
        )
        
        appState.saveWorkoutLog(log)
        setData.removeAll()
        initializeSetData()
    }
}

// MARK: - Set Entry Model

struct SetEntry: Identifiable {
    let id = UUID()
    var setNumber: Int
    var kg: Double = 0
    var reps: Int = 0
    var completed: Bool = false
}

// MARK: - Expandable Exercise Card

struct ExpandableExerciseCard: View {
    let number: Int
    let exercise: Exercise
    @Binding var sets: [SetEntry]
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var completedCount: Int {
        sets.filter { $0.completed }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Number badge
                    Text("\(number)")
                        .font(.headline.bold())
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                    
                    // Exercise info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text("\(exercise.sets) × \(exercise.reps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if exercise.isCompound {
                                HStack(spacing: 2) {
                                    Image(systemName: "bolt.fill")
                                        .font(.caption2)
                                    Text("COMPOUND")
                                        .font(.caption2.bold())
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Progress
                    Text("\(completedCount)/\(exercise.sets)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Expand arrow
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(DesignConstants.cardPadding)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    
                    // Column headers
                    HStack {
                        Text("SET")
                            .frame(width: 44)
                        Text("KG")
                            .frame(maxWidth: .infinity)
                        Text("REPS")
                            .frame(maxWidth: .infinity)
                        Text("DONE")
                            .frame(width: 50)
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignConstants.cardPadding)
                    .padding(.vertical, 10)
                    
                    // Set rows
                    ForEach($sets) { $entry in
                        SetRow(entry: $entry)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.outerRadius))
    }
}

// MARK: - Set Row

struct SetRow: View {
    @Binding var entry: SetEntry
    @State private var showKgPicker = false
    @State private var showRepsPicker = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Set number
            Text("\(entry.setNumber)")
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .frame(width: 36, height: 40)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                .frame(width: 44)
            
            // KG picker button
            Button(action: { showKgPicker = true }) {
                Text(entry.kg > 0 ? String(format: "%.1f", entry.kg) : "—")
                    .font(.subheadline)
                    .foregroundColor(entry.kg > 0 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
            }
            
            // Reps picker button
            Button(action: { showRepsPicker = true }) {
                Text(entry.reps > 0 ? "\(entry.reps)" : "—")
                    .font(.subheadline)
                    .foregroundColor(entry.reps > 0 ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
            }
            
            // Completion checkbox
            Button(action: {
                entry.completed.toggle()
                if entry.completed {
                    HapticService.shared.success()
                }
            }) {
                Image(systemName: entry.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(entry.completed ? .green : .secondary)
            }
            .frame(width: 50)
        }
        .padding(.horizontal, DesignConstants.cardPadding)
        .padding(.vertical, 4)
        .sheet(isPresented: $showKgPicker) {
            KgPickerSheet(value: $entry.kg)
        }
        .sheet(isPresented: $showRepsPicker) {
            RepsPickerSheet(value: $entry.reps)
        }
    }
}

// MARK: - KG Picker Sheet

struct KgPickerSheet: View {
    @Binding var value: Double
    @Environment(\.dismiss) var dismiss
    @State private var tempValue: Double = 0
    
    let presets: [Double] = [5, 10, 15, 20, 25, 30, 40, 50, 60, 80, 100]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current value
                Text(String(format: "%.1f kg", tempValue))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                // Stepper controls
                HStack(spacing: 16) {
                    stepperButton("-5") { tempValue = max(0, tempValue - 5) }
                    stepperButton("-2.5") { tempValue = max(0, tempValue - 2.5) }
                    stepperButton("+2.5") { tempValue += 2.5 }
                    stepperButton("+5") { tempValue += 5 }
                }
                
                // Presets
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(presets, id: \.self) { preset in
                        Button(action: { tempValue = preset }) {
                            Text("\(Int(preset))")
                                .font(.headline)
                                .foregroundColor(tempValue == preset ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(tempValue == preset ? Color.orange : Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button(action: {
                    value = tempValue
                    dismiss()
                }) {
                    Text("Set Weight")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                }
                .padding(.horizontal)
            }
            .padding(.top, 32)
            .navigationTitle("Weight (kg)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { tempValue = value }
        }
        .presentationDetents([.medium])
    }
    
    private func stepperButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            HapticService.shared.light()
        }) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(.orange)
                .frame(width: 56, height: 44)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
        }
    }
}

// MARK: - Reps Picker Sheet

struct RepsPickerSheet: View {
    @Binding var value: Int
    @Environment(\.dismiss) var dismiss
    @State private var tempValue: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Current value
                Text("\(tempValue)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                // Stepper controls
                HStack(spacing: 24) {
                    Button(action: { if tempValue > 0 { tempValue -= 1; HapticService.shared.light() } }) {
                        Image(systemName: "minus")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { tempValue += 1; HapticService.shared.light() }) {
                        Image(systemName: "plus")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
                
                // Quick presets
                HStack(spacing: 10) {
                    ForEach([6, 8, 10, 12, 15], id: \.self) { preset in
                        Button(action: { tempValue = preset }) {
                            Text("\(preset)")
                                .font(.headline)
                                .foregroundColor(tempValue == preset ? .white : .primary)
                                .frame(width: 48, height: 48)
                                .background(tempValue == preset ? Color.orange : Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                        }
                    }
                }
                
                Spacer()
                
                // Save button
                Button(action: {
                    value = tempValue
                    dismiss()
                }) {
                    Text("Set Reps")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
                }
                .padding(.horizontal)
            }
            .padding(.top, 32)
            .navigationTitle("Reps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { tempValue = value }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Workout Days Picker Sheet

struct WorkoutDaysPicker: View {
    let days: [CustomWorkoutDay]
    let onAdd: () -> Void
    let onEdit: (CustomWorkoutDay) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if days.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No workout days yet")
                            .font(.headline)
                        
                        Text("Create your first workout day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(days) { day in
                        Button(action: {
                            onEdit(day)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Text("\(day.exercises.count) exercises")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        if let scheduled = day.scheduledDayName {
                                            Text("• \(scheduled)")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Workout Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAdd()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutTabView()
        .environmentObject(AppState())
}
