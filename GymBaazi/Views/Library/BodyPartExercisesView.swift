import SwiftUI

/// View showing exercises for a specific body part with filters
struct BodyPartExercisesView: View {
    let bodyPart: BodyPart
    @StateObject private var viewModel = BodyPartExercisesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedMuscle: String? = nil
    @State private var selectedEquipmentFilter: String? = nil
    @State private var selectedExercise: ExerciseDBExercise?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter bar
                filterBar
                
                // Exercise grid
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading exercises...")
                    Spacer()
                } else if filteredExercises.isEmpty {
                    emptyState
                } else {
                    exerciseGrid
                }
            }
        }
        .navigationTitle(bodyPart.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailModal(exercise: exercise)
        }
        .task {
            await viewModel.loadExercises(for: bodyPart.rawValue)
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search exercises...", text: $searchText)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    HapticService.shared.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: 8) {
            // Muscles dropdown
            if !viewModel.availableMuscles.isEmpty {
                Menu {
                    Button("All Muscles") {
                        selectedMuscle = nil
                        HapticService.shared.light()
                    }
                    Divider()
                    ForEach(viewModel.availableMuscles, id: \.self) { muscle in
                        Button(muscle.capitalized) {
                            selectedMuscle = muscle
                            HapticService.shared.light()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMuscle?.capitalized ?? "Muscle")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(selectedMuscle != nil ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedMuscle != nil ? Color.purple : Color(.systemGray5))
                    .clipShape(Capsule())
                }
            }
            
            // Equipment dropdown
            if !viewModel.availableEquipment.isEmpty {
                Menu {
                    Button("All Equipment") {
                        selectedEquipmentFilter = nil
                        HapticService.shared.light()
                    }
                    Divider()
                    ForEach(viewModel.availableEquipment, id: \.self) { equipment in
                        Button(equipment.capitalized) {
                            selectedEquipmentFilter = equipment
                            HapticService.shared.light()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedEquipmentFilter?.capitalized ?? "Equipment")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(selectedEquipmentFilter != nil ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedEquipmentFilter != nil ? Color.cyan : Color(.systemGray5))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Exercise Grid
    
    private var exerciseGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filteredExercises) { exercise in
                    ExerciseCard(exercise: exercise)
                        .onTapGesture {
                            selectedExercise = exercise
                            HapticService.shared.light()
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No exercises found")
                .font(.headline)
                .foregroundColor(.secondary)
            if hasActiveFilters {
                Button("Clear Filters") {
                    selectedMuscle = nil
                    selectedEquipmentFilter = nil
                    HapticService.shared.light()
                }
                .font(.subheadline)
                .foregroundColor(.orange)
            }
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private var hasActiveFilters: Bool {
        selectedMuscle != nil || selectedEquipmentFilter != nil
    }
    
    private var filteredExercises: [ExerciseDBExercise] {
        var result = viewModel.exercises
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.targetMuscles.joined().localizedCaseInsensitiveContains(searchText) ||
                exercise.equipments.joined().localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Muscle filter (single selection)
        if let muscle = selectedMuscle {
            result = result.filter { exercise in
                exercise.targetMuscles.contains(muscle) ||
                exercise.secondaryMuscles.contains(muscle)
            }
        }
        
        // Equipment filter (single selection)
        if let equipment = selectedEquipmentFilter {
            result = result.filter { exercise in
                exercise.equipments.contains(equipment)
            }
        }
        
        return result
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
            }
        }
        .font(.caption)
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    let availableMuscles: [String]
    let availableEquipment: [String]
    @Binding var selectedMuscles: Set<String>
    @Binding var selectedEquipment: Set<String>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Muscles Section
                    if !availableMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Target Muscles")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(availableMuscles, id: \.self) { muscle in
                                    FilterChipToggle(
                                        title: muscle.capitalized,
                                        isSelected: selectedMuscles.contains(muscle),
                                        color: .purple
                                    ) {
                                        if selectedMuscles.contains(muscle) {
                                            selectedMuscles.remove(muscle)
                                        } else {
                                            selectedMuscles.insert(muscle)
                                        }
                                        HapticService.shared.light()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Equipment Section
                    if !availableEquipment.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Equipment")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(availableEquipment, id: \.self) { equipment in
                                    FilterChipToggle(
                                        title: equipment.capitalized,
                                        isSelected: selectedEquipment.contains(equipment),
                                        color: .cyan
                                    ) {
                                        if selectedEquipment.contains(equipment) {
                                            selectedEquipment.remove(equipment)
                                        } else {
                                            selectedEquipment.insert(equipment)
                                        }
                                        HapticService.shared.light()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    if !selectedMuscles.isEmpty || !selectedEquipment.isEmpty {
                        Button("Clear All") {
                            selectedMuscles.removeAll()
                            selectedEquipment.removeAll()
                            HapticService.shared.light()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Filter Chip Toggle

struct FilterChipToggle: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxHeight = max(maxHeight, y + size.height)
        }
        
        return (CGSize(width: maxWidth, height: maxHeight), frames)
    }
}

// MARK: - ViewModel

@MainActor
class BodyPartExercisesViewModel: ObservableObject {
    @Published var exercises: [ExerciseDBExercise] = []
    @Published var isLoading = false
    @Published var availableMuscles: [String] = []
    @Published var availableEquipment: [String] = []
    
    func loadExercises(for bodyPart: String) async {
        isLoading = true
        
        do {
            // Load all exercises for this body part (paginate to get more)
            var allExercises: [ExerciseDBExercise] = []
            var offset = 0
            let limit = 25
            
            while true {
                let result = try await ExerciseDBService.shared.getExercisesByBodyPart(
                    bodyPart: bodyPart,
                    offset: offset,
                    limit: limit
                )
                allExercises.append(contentsOf: result.exercises)
                
                // Check if we have more pages
                if let metadata = result.metadata, metadata.currentPage < metadata.totalPages {
                    offset += limit
                } else {
                    break
                }
                
                // Limit to 100 exercises for performance
                if allExercises.count >= 100 { break }
            }
            
            exercises = allExercises
            
            // Extract available filters from exercises
            extractFilters()
        } catch {
            print("Error loading exercises: \(error)")
            exercises = []
        }
        
        isLoading = false
    }
    
    private func extractFilters() {
        var muscles = Set<String>()
        var equipment = Set<String>()
        
        for exercise in exercises {
            muscles.formUnion(exercise.targetMuscles)
            muscles.formUnion(exercise.secondaryMuscles)
            equipment.formUnion(exercise.equipments)
        }
        
        availableMuscles = muscles.sorted()
        availableEquipment = equipment.sorted()
    }
}

#Preview {
    NavigationStack {
        BodyPartExercisesView(bodyPart: .chest)
    }
}
