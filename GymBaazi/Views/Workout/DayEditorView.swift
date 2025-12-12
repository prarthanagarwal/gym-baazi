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
    
    // Validation state
    @State private var nameError: ValidationError?
    @State private var hasAttemptedSave = false
    
    /// Whether the form is valid
    private var isFormValid: Bool {
        FormValidator.validateWorkoutDayName(dayName) == nil
    }
    
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
                // Day name with validation
                Section("Workout Name") {
                    TextField("e.g., Chest & Triceps", text: $dayName)
                        .onChange(of: dayName) { _, newValue in
                            if hasAttemptedSave {
                                nameError = FormValidator.validateWorkoutDayName(newValue)
                            }
                        }
                    
                    // Show validation error inline in section
                    if let error = nameError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text(error.message)
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
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
                    Button("Save") { attemptSave() }
                        .disabled(!isFormValid)
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
    
    private func attemptSave() {
        hasAttemptedSave = true
        
        // Validate workout name
        nameError = FormValidator.validateWorkoutDayName(dayName)
        
        guard isFormValid else {
            HapticService.shared.error()
            return
        }
        
        saveDay()
    }
    
    private func saveDay() {
        let trimmedName = dayName.trimmed
        
        if let existingDay = existingDay {
            var updated = existingDay
            updated.name = trimmedName
            updated.dayOfWeek = selectedDayOfWeek
            updated.exercises = selectedExercises
            appState.updateWorkoutDay(updated)
        } else {
            let newDay = CustomWorkoutDay(
                name: trimmedName,
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
    @StateObject private var viewModel = AddExerciseViewModel()
    @State private var searchText = ""
    @State private var exerciseToConfig: ExerciseDBExercise?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter bar
                filterBar
                
                // Results with lazy loading
                exerciseList
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .sheet(item: $exerciseToConfig) { exercise in
                ExerciseConfigSheet(exercise: exercise) { configuredExercise in
                    selectedExercises.insert(configuredExercise, at: 0)
                    exerciseToConfig = nil
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search exercises...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    Task { await viewModel.clearSearch() }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 8)
        .onChange(of: searchText) { _, newValue in
            Task { await viewModel.search(query: newValue) }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Body Part filter
                filterMenu(
                    title: viewModel.selectedBodyPart ?? "Body Part",
                    icon: "figure.strengthtraining.traditional",
                    options: viewModel.bodyParts,
                    selection: $viewModel.selectedBodyPart
                )
                
                // Equipment filter
                filterMenu(
                    title: viewModel.selectedEquipment ?? "Equipment",
                    icon: "dumbbell.fill",
                    options: viewModel.equipment,
                    selection: $viewModel.selectedEquipment
                )
                
                // Muscle filter
                filterMenu(
                    title: viewModel.selectedMuscle ?? "Muscle",
                    icon: "figure.arms.open",
                    options: viewModel.muscles,
                    selection: $viewModel.selectedMuscle
                )
                
                // Clear filters button
                if viewModel.hasActiveFilters {
                    Button(action: { 
                        viewModel.clearFilters()
                        Task { await viewModel.loadExercises() }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Clear")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func filterMenu(
        title: String,
        icon: String,
        options: [String],
        selection: Binding<String?>
    ) -> some View {
        Menu {
            Button("All") {
                selection.wrappedValue = nil
                Task { await viewModel.applyFilters() }
            }
            ForEach(options, id: \.self) { option in
                Button(option.capitalized) {
                    selection.wrappedValue = option
                    Task { await viewModel.applyFilters() }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title.capitalized)
                    .font(.caption.bold())
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(selection.wrappedValue != nil ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selection.wrappedValue != nil ? Color.orange : Color(.systemGray5))
            .clipShape(Capsule())
        }
    }
    
    private var exerciseList: some View {
        Group {
            if viewModel.isLoading && viewModel.exercises.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("Loading exercises...")
                    Spacer()
                }
            } else if viewModel.exercises.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No exercises found")
                        .font(.headline)
                    Text("Try adjusting your filters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                // Sort so already-selected appear at top
                let sortedExercises = viewModel.exercises.sorted { ex1, ex2 in
                    let ex1Added = selectedExercises.contains { $0.name == ex1.name }
                    let ex2Added = selectedExercises.contains { $0.name == ex2.name }
                    if ex1Added == ex2Added { return false }
                    return ex1Added
                }
                
                List {
                    ForEach(sortedExercises) { apiExercise in
                        let isAlreadyAdded = selectedExercises.contains { $0.name == apiExercise.name }
                        
                        Button(action: {
                            if !isAlreadyAdded {
                                exerciseToConfig = apiExercise
                                HapticService.shared.light()
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(apiExercise.name)
                                        .font(.headline)
                                        .foregroundColor(isAlreadyAdded ? .secondary : .primary)
                                    
                                    if !apiExercise.targetMuscles.isEmpty {
                                        Text(apiExercise.targetMuscles.joined(separator: ", ").capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if isAlreadyAdded {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .disabled(isAlreadyAdded)
                        .onAppear {
                            // Lazy load more when reaching end
                            if apiExercise.id == viewModel.exercises.last?.id {
                                Task { await viewModel.loadMoreExercises() }
                            }
                        }
                    }
                    
                    // Loading indicator at bottom
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    // Exercise count
                    if !viewModel.isLoading {
                        Text("\(viewModel.exercises.count) exercises loaded")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}


// MARK: - Exercise Config Sheet

struct ExerciseConfigSheet: View {
    let exercise: ExerciseDBExercise
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
                    
                    if let muscles = exercise.targetMuscles.first {
                        Text(muscles.capitalized)
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
            isCompound: false, // ExerciseDB doesn't have mechanic field
            restTime: restSeconds >= 120 ? "\(restSeconds/60) min" : "\(restSeconds) sec",
            restSeconds: restSeconds,
            exerciseDbId: exercise.exerciseId
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

// MARK: - ViewModel for Exercise Picker

@MainActor
class AddExerciseViewModel: ObservableObject {
    @Published var exercises: [ExerciseDBExercise] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    
    // Filter options
    @Published var bodyParts: [String] = []
    @Published var muscles: [String] = []
    @Published var equipment: [String] = []
    
    // Selected filters
    @Published var selectedBodyPart: String?
    @Published var selectedMuscle: String?
    @Published var selectedEquipment: String?
    
    private var currentOffset = 0
    private let pageSize = 50
    private var searchQuery = ""
    private var loadTask: Task<Void, Never>?
    private let service = ExerciseDBService.shared
    
    var hasActiveFilters: Bool {
        selectedBodyPart != nil || selectedMuscle != nil || selectedEquipment != nil
    }
    
    // MARK: - Initial Load
    
    func loadInitialData() async {
        async let exercisesTask: () = loadExercises()
        async let filtersTask: () = loadFilterOptions()
        
        _ = await (exercisesTask, filtersTask)
    }
    
    private func loadFilterOptions() async {
        do {
            async let bodyPartsResult = service.getBodyParts()
            async let musclesResult = service.getMuscles()
            async let equipmentResult = service.getEquipments()
            
            let (bp, m, eq) = try await (bodyPartsResult, musclesResult, equipmentResult)
            
            bodyParts = bp.map { $0.name }
            muscles = m.map { $0.name }
            equipment = eq.map { $0.name }
        } catch {
            print("Error loading filter options: \(error)")
        }
    }
    
    // MARK: - Load Exercises
    
    func loadExercises() async {
        currentOffset = 0
        hasMorePages = true
        exercises = []
        
        await fetchExercises()
    }
    
    func loadMoreExercises() async {
        guard !isLoading && hasMorePages else { return }
        await fetchExercises()
    }
    
    private func fetchExercises() async {
        loadTask?.cancel()
        
        loadTask = Task {
            isLoading = true
            
            do {
                let result: (exercises: [ExerciseDBExercise], metadata: ExerciseDBMetadata?)
                
                if let bodyPart = selectedBodyPart {
                    result = try await service.getExercisesByBodyPart(
                        bodyPart: bodyPart,
                        offset: currentOffset,
                        limit: pageSize,
                        useCache: currentOffset == 0
                    )
                } else if !searchQuery.isEmpty {
                    result = try await service.searchExercises(query: searchQuery, limit: pageSize)
                    hasMorePages = false
                } else {
                    result = try await service.getExercises(offset: currentOffset, limit: pageSize)
                }
                
                guard !Task.isCancelled else { return }
                
                var newExercises = result.exercises
                
                // Apply local filters for muscle and equipment
                if let muscle = selectedMuscle {
                    newExercises = newExercises.filter { 
                        $0.targetMuscles.contains(where: { $0.lowercased() == muscle.lowercased() }) ||
                        $0.secondaryMuscles.contains(where: { $0.lowercased() == muscle.lowercased() })
                    }
                }
                
                if let equip = selectedEquipment {
                    newExercises = newExercises.filter { 
                        $0.equipments.contains(where: { $0.lowercased() == equip.lowercased() })
                    }
                }
                
                if currentOffset == 0 {
                    exercises = newExercises
                } else {
                    exercises.append(contentsOf: newExercises)
                }
                
                currentOffset += pageSize
                
                if let metadata = result.metadata {
                    hasMorePages = metadata.currentPage < metadata.totalPages
                } else {
                    hasMorePages = result.exercises.count >= pageSize
                }
                
            } catch {
                print("Error loading exercises: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Search
    
    func search(query: String) async {
        searchQuery = query
        
        if query.count >= 2 {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            
            await loadExercises()
        } else if query.isEmpty {
            await clearSearch()
        }
    }
    
    func clearSearch() async {
        searchQuery = ""
        await loadExercises()
    }
    
    // MARK: - Filters
    
    func applyFilters() async {
        await loadExercises()
    }
    
    func clearFilters() {
        selectedBodyPart = nil
        selectedMuscle = nil
        selectedEquipment = nil
    }
}
