import SwiftUI

/// View for creating/editing a custom workout day with template picker
struct DayEditorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    let existingDay: CustomWorkoutDay?
    let existingDays: [CustomWorkoutDay]
    
    @State private var dayName: String = ""
    @State private var selectedDayOfWeek: Int? = nil
    @State private var selectedExercises: [Exercise] = []
    @State private var showTemplatePicker = false
    @State private var showExercisePicker = false
    @State private var showCopyFromExisting = false
    @State private var showDeleteConfirmation = false
    @State private var editingExerciseIndex: Int? = nil
    
    init(day: CustomWorkoutDay?, existingDays: [CustomWorkoutDay] = []) {
        self.existingDay = day
        self.existingDays = existingDays
        if let day = day {
            _dayName = State(initialValue: day.name)
            _selectedDayOfWeek = State(initialValue: day.dayOfWeek)
            _selectedExercises = State(initialValue: day.exercises)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Day name
                Section("Workout Name") {
                    TextField("e.g., Chest & Triceps", text: $dayName)
                }
                
                // Scheduled day
                Section("Schedule") {
                    Picker("Day of Week", selection: $selectedDayOfWeek) {
                        Text("Not Scheduled").tag(nil as Int?)
                        ForEach(1...7, id: \.self) { day in
                            Text(dayFullName(for: day)).tag(day as Int?)
                        }
                    }
                }
                
                // Quick start options (only when no exercises yet)
                if selectedExercises.isEmpty {
                    Section("Quick Start") {
                        // Template option
                        Button(action: { showTemplatePicker = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use a Template")
                                        .foregroundColor(.primary)
                                    Text("Push, Pull, Legs, Upper, Lower, Full Body")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // Copy from existing (only if there are existing workouts)
                        if !existingDays.isEmpty && existingDay == nil {
                            Button(action: { showCopyFromExisting = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.badge.plus")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Copy Existing Workout")
                                            .foregroundColor(.primary)
                                        Text("Use one of your workout days as a starting point")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        // Build from scratch
                        Button(action: { showExercisePicker = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Build from Scratch")
                                        .foregroundColor(.primary)
                                    Text("Browse exercises from the library")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Exercises list
                if !selectedExercises.isEmpty {
                    Section {
                        ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseRowInEditor(
                                exercise: exercise,
                                onEdit: {
                                    editingExerciseIndex = index
                                },
                                onDelete: {
                                    selectedExercises.remove(at: index)
                                }
                            )
                        }
                        .onMove(perform: moveExercise)
                        
                        Button(action: { showExercisePicker = true }) {
                            Label("Add More Exercises", systemImage: "plus")
                        }
                    } header: {
                        HStack {
                            Text("Exercises")
                            Spacer()
                            Text("\(selectedExercises.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Delete (if editing existing)
                if existingDay != nil {
                    Section {
                        Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                            Label("Delete Workout Day", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existingDay == nil ? "New Workout Day" : "Edit Workout Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDay() }
                        .disabled(dayName.isEmpty)
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplatePickerView { template in
                    dayName = template.name
                    selectedExercises = template.exercises.map { $0.toExercise() }
                    showTemplatePicker = false
                }
            }
            .sheet(isPresented: $showCopyFromExisting) {
                CopyFromExistingView(existingDays: existingDays.filter { $0.id != existingDay?.id }) { copiedDay in
                    dayName = "\(copiedDay.name) (Copy)"
                    selectedExercises = copiedDay.exercises
                    showCopyFromExisting = false
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerSheet(selectedExercises: $selectedExercises)
            }
            .sheet(item: $editingExerciseIndex) { index in
                EditExerciseSheet(exercise: selectedExercises[index]) { updated in
                    selectedExercises[index] = updated
                    editingExerciseIndex = nil
                }
            }
            .confirmationDialog("Delete Workout Day?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let day = existingDay {
                        appState.deleteWorkoutDay(id: day.id)
                    }
                    dismiss()
                }
            } message: {
                Text("This will permanently delete this workout day.")
            }
        }
    }
    
    private func dayFullName(for day: Int) -> String {
        ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day]
    }
    
    private func moveExercise(from source: IndexSet, to destination: Int) {
        selectedExercises.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveDay() {
        if let existingDay = existingDay {
            var updated = existingDay
            updated.name = dayName
            updated.dayOfWeek = selectedDayOfWeek
            updated.exercises = selectedExercises
            appState.updateWorkoutDay(updated)
        } else {
            let newDay = CustomWorkoutDay(
                name: dayName,
                dayOfWeek: selectedDayOfWeek,
                exercises: selectedExercises
            )
            appState.addWorkoutDay(newDay)
        }
        HapticService.shared.success()
        dismiss()
    }
}

// MARK: - Copy From Existing View

struct CopyFromExistingView: View {
    @Environment(\.dismiss) var dismiss
    let existingDays: [CustomWorkoutDay]
    let onSelect: (CustomWorkoutDay) -> Void
    
    var body: some View {
        NavigationStack {
            List(existingDays) { day in
                Button(action: { onSelect(day) }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(day.exercises.count) exercises")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Copy Existing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Template Picker View

struct TemplatePickerView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (WorkoutTemplate) -> Void
    
    var body: some View {
        NavigationStack {
            List(WorkoutTemplates.all) { template in
                Button(action: { onSelect(template) }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(templateColor(template.color).opacity(0.15))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: template.icon)
                                .font(.title2)
                                .foregroundColor(templateColor(template.color))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(template.exercises.count)")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(templateColor(template.color))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func templateColor(_ name: String) -> Color {
        switch name {
        case "orange": return .orange
        case "cyan": return .cyan
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        default: return .orange
        }
    }
}

// MARK: - Exercise Row in Editor

struct ExerciseRowInEditor: View {
    let exercise: Exercise
    var onEdit: (() -> Void)? = nil
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                Text("\(exercise.sets) sets × \(exercise.reps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Edit button
            Button(action: { onEdit?() }) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Edit Exercise Sheet

struct EditExerciseSheet: View {
    let exercise: Exercise
    let onSave: (Exercise) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var sets: Int
    @State private var repsMin: Int
    @State private var repsMax: Int
    @State private var restSeconds: Int
    
    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        
        // Parse existing values
        _sets = State(initialValue: exercise.sets)
        _restSeconds = State(initialValue: exercise.restSeconds)
        
        // Parse reps (e.g., "8-12" or "10")
        let repsParts = exercise.reps.split(separator: "-")
        if repsParts.count == 2 {
            _repsMin = State(initialValue: Int(repsParts[0]) ?? 8)
            _repsMax = State(initialValue: Int(repsParts[1]) ?? 12)
        } else {
            let singleReps = Int(exercise.reps) ?? 10
            _repsMin = State(initialValue: singleReps)
            _repsMax = State(initialValue: singleReps)
        }
    }
    
    var repsString: String {
        repsMin == repsMax ? "\(repsMin)" : "\(repsMin)-\(repsMax)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise name
                Text(exercise.name)
                    .font(.title2.bold())
                    .padding(.top)
                
                // Configuration
                VStack(spacing: 20) {
                    // Sets
                    VStack(spacing: 8) {
                        HStack {
                            Text("Sets")
                                .font(.headline)
                            Spacer()
                            Text("\(sets)")
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach([2, 3, 4, 5], id: \.self) { count in
                                Button(action: { sets = count }) {
                                    Text("\(count)")
                                        .font(.headline)
                                        .foregroundColor(sets == count ? .white : .primary)
                                        .frame(width: 50, height: 44)
                                        .background(sets == count ? Color.orange : Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Reps Range
                    VStack(spacing: 8) {
                        HStack {
                            Text("Reps")
                                .font(.headline)
                            Spacer()
                            Text(repsString)
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text("Min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(repsMin)", value: $repsMin, in: 1...50)
                                    .labelsHidden()
                            }
                            
                            Text("—")
                                .foregroundColor(.secondary)
                            
                            VStack {
                                Text("Max")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(repsMax)", value: $repsMax, in: repsMin...50)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Rest time
                    VStack(spacing: 8) {
                        HStack {
                            Text("Rest")
                                .font(.headline)
                            Spacer()
                            Text("\(restSeconds) sec")
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach([60, 90, 120, 180], id: \.self) { time in
                                Button(action: { restSeconds = time }) {
                                    Text(time < 120 ? "\(time)s" : "\(time/60)m")
                                        .font(.subheadline)
                                        .foregroundColor(restSeconds == time ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(restSeconds == time ? Color.orange : Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
                
                // Save button
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func saveChanges() {
        var updated = exercise
        updated.sets = sets
        updated.reps = repsString
        updated.restSeconds = restSeconds
        updated.restTime = restSeconds >= 120 ? "\(restSeconds/60) min" : "\(restSeconds) sec"
        onSave(updated)
        HapticService.shared.success()
        dismiss()
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// MARK: - Exercise Picker Sheet (with set/rep configuration)

struct ExercisePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedExercises: [Exercise]
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var searchText = ""
    @State private var exerciseToConfig: MuscleWikiExercise?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search exercises...", text: $searchText)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
                
                // Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading exercises...")
                    Spacer()
                } else {
                    List(viewModel.filteredExercises(searchText)) { apiExercise in
                        Button(action: {
                            exerciseToConfig = apiExercise
                            HapticService.shared.light()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(apiExercise.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let muscles = apiExercise.primaryMuscles {
                                        Text(muscles.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadAllExercises()
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.count >= 2 {
                    Task {
                        await viewModel.searchExercises(query: newValue)
                    }
                } else if newValue.isEmpty {
                    Task {
                        await loadAllExercises()
                    }
                }
            }
            .sheet(item: $exerciseToConfig) { exercise in
                ExerciseConfigSheet(exercise: exercise) { configuredExercise in
                    selectedExercises.append(configuredExercise)
                    exerciseToConfig = nil
                }
            }
        }
    }
    
    private func loadAllExercises() async {
        viewModel.isLoading = true
        do {
            let response = try await MuscleWikiService.shared.getExercises(limit: 100)
            viewModel.exercises = response.results
        } catch {
            viewModel.exercises = []
        }
        viewModel.isLoading = false
    }
}

// MARK: - Exercise Config Sheet

struct ExerciseConfigSheet: View {
    let exercise: MuscleWikiExercise
    let onAdd: (Exercise) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var sets = 3
    @State private var repsMin = 8
    @State private var repsMax = 12
    @State private var restSeconds = 90
    
    var repsString: String {
        repsMin == repsMax ? "\(repsMin)" : "\(repsMin)-\(repsMax)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Exercise info
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.title2.bold())
                    
                    if let muscles = exercise.primaryMuscles {
                        Text(muscles.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)
                
                // Configuration
                VStack(spacing: 20) {
                    // Sets
                    VStack(spacing: 8) {
                        HStack {
                            Text("Sets")
                                .font(.headline)
                            Spacer()
                            Text("\(sets)")
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach([2, 3, 4, 5], id: \.self) { count in
                                Button(action: { sets = count }) {
                                    Text("\(count)")
                                        .font(.headline)
                                        .foregroundColor(sets == count ? .white : .primary)
                                        .frame(width: 50, height: 44)
                                        .background(sets == count ? Color.orange : Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Reps Range
                    VStack(spacing: 8) {
                        HStack {
                            Text("Reps")
                                .font(.headline)
                            Spacer()
                            Text(repsString)
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 16) {
                            VStack {
                                Text("Min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(repsMin)", value: $repsMin, in: 1...50)
                                    .labelsHidden()
                            }
                            
                            Text("—")
                                .foregroundColor(.secondary)
                            
                            VStack {
                                Text("Max")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(repsMax)", value: $repsMax, in: repsMin...50)
                                    .labelsHidden()
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Rest time
                    VStack(spacing: 8) {
                        HStack {
                            Text("Rest")
                                .font(.headline)
                            Spacer()
                            Text("\(restSeconds) sec")
                                .font(.title3.bold())
                                .foregroundColor(.orange)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach([60, 90, 120, 180], id: \.self) { time in
                                Button(action: { restSeconds = time }) {
                                    Text(time < 120 ? "\(time)s" : "\(time/60)m")
                                        .font(.subheadline)
                                        .foregroundColor(restSeconds == time ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(restSeconds == time ? Color.orange : Color(.systemGray5))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer()
                
                // Add button
                Button(action: addExercise) {
                    Text("Add Exercise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Configure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private func addExercise() {
        let newExercise = Exercise(
            name: exercise.name,
            sets: sets,
            reps: repsString,
            isCompound: exercise.mechanic == "compound",
            restTime: restSeconds >= 120 ? "\(restSeconds/60) min" : "\(restSeconds) sec",
            restSeconds: restSeconds,
            muscleWikiId: exercise.id
        )
        onAdd(newExercise)
        HapticService.shared.success()
        dismiss()
    }
}

#Preview {
    DayEditorView(day: nil)
        .environmentObject(AppState())
}
