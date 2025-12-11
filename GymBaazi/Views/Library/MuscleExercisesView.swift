import SwiftUI

/// View showing exercises for a specific muscle group
struct MuscleExercisesView: View {
    let muscle: ExerciseDBMuscle
    @StateObject private var viewModel = MuscleExercisesViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedExercise: ExerciseDBExercise?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Exercise list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading exercises...")
                    Spacer()
                } else if filteredExercises.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No exercises found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredExercises) { exercise in
                                ExerciseRow(exercise: exercise) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        selectedExercise = exercise
                                    }
                                    HapticService.shared.light()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            
            // Popup overlay
            if let exercise = selectedExercise {
                ExercisePopup(
                    exercise: exercise,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedExercise = nil
                        }
                    }
                )
            }
        }
        .navigationTitle(muscle.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(selectedExercise != nil)
        .task {
            await viewModel.loadExercises(for: muscle.name)
        }
    }
    
    private var filteredExercises: [ExerciseDBExercise] {
        var result = viewModel.exercises
        
        // Search filter (client-side)
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return result
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(.subheadline)
        .foregroundColor(isActive ? .white : .primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? Color.orange : Color(.systemGray5))
        .clipShape(Capsule())
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: ExerciseDBExercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // GIF Thumbnail
                ExerciseGifThumbnail(gifUrl: exercise.gifUrl)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let equipment = exercise.primaryEquipment {
                        Text(equipment.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Popup

struct ExercisePopup: View {
    let exercise: ExerciseDBExercise
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Popup card
            VStack(spacing: 12) {
                // Header with close button
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                        .lineLimit(2)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
                
                // GIF Player
                ExerciseGifPlayer(gifUrl: exercise.gifUrl, height: 180)
                
                // Muscle tags
                if !exercise.targetMuscles.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(exercise.targetMuscles.prefix(3), id: \.self) { muscle in
                            Text(muscle.capitalized)
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
                
                // Info row
                HStack(spacing: 16) {
                    if let equipment = exercise.primaryEquipment {
                        Label(equipment.capitalized, systemImage: "dumbbell.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let bodyPart = exercise.bodyParts.first {
                        Label(bodyPart.capitalized, systemImage: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(24)
        }
    }
}

// MARK: - ViewModel

@MainActor
class MuscleExercisesViewModel: ObservableObject {
    @Published var exercises: [ExerciseDBExercise] = []
    @Published var equipments: [ExerciseDBEquipment] = []
    @Published var isLoading = false
    
    func loadExercises(for muscle: String) async {
        isLoading = true
        
        do {
            let result = try await ExerciseDBService.shared.getExercisesByMuscle(muscle: muscle, limit: 25)
            exercises = result.exercises
        } catch {
            exercises = ExerciseDBService.mockExercises
        }
        
        isLoading = false
    }
    
    func loadExercisesFiltered(muscle: String, equipment: String) async {
        isLoading = true
        
        do {
            let result = try await ExerciseDBService.shared.filterExercises(
                muscles: [muscle],
                equipment: [equipment],
                limit: 25
            )
            exercises = result.exercises
        } catch {
            exercises = []
        }
        
        isLoading = false
    }
    
    func loadEquipments() async {
        do {
            equipments = try await ExerciseDBService.shared.getEquipments()
        } catch {
            equipments = []
        }
    }
}

extension ExerciseDBExercise: @unchecked Sendable {}

#Preview {
    NavigationStack {
        MuscleExercisesView(muscle: ExerciseDBMuscle(name: "chest"))
            .environmentObject(AppState())
    }
}
