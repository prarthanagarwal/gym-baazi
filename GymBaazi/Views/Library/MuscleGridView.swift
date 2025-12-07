import SwiftUI

/// Grid view of muscle groups for browsing exercises
struct MuscleGridView: View {
    @StateObject private var viewModel = MuscleGridViewModel()
    @State private var selectedMuscle: MuscleCategory?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Loading muscles...")
                    .padding(.top, 100)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.muscles) { muscle in
                        MuscleCell(muscle: muscle)
                            .onTapGesture {
                                selectedMuscle = muscle
                                HapticService.shared.light()
                            }
                    }
                }
                .padding()
            }
        }
        .navigationDestination(item: $selectedMuscle) { muscle in
            MuscleExercisesView(muscle: muscle)
        }
        .task {
            await viewModel.loadMuscles()
        }
    }
}

// MARK: - Muscle Cell

struct MuscleCell: View {
    let muscle: MuscleCategory
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                
                Image(systemName: muscleIcon)
                    .font(.title2)
                    .foregroundColor(.orange)
            }
            
            // Name
            Text(muscle.displayName ?? muscle.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Count
            Text("\(muscle.count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var muscleIcon: String {
        let name = muscle.name.lowercased()
        switch name {
        case let n where n.contains("chest"): return "heart.fill"
        case let n where n.contains("bicep"): return "figure.arms.open"
        case let n where n.contains("tricep"): return "figure.arms.open"
        case let n where n.contains("shoulder"), let n where n.contains("delt"): return "figure.wave"
        case let n where n.contains("back"), let n where n.contains("lat"): return "figure.stand"
        case let n where n.contains("quad"): return "figure.walk"
        case let n where n.contains("hamstring"): return "figure.run"
        case let n where n.contains("glute"): return "figure.cooldown"
        case let n where n.contains("calf"): return "figure.step.training"
        case let n where n.contains("core"), let n where n.contains("ab"): return "figure.core.training"
        case let n where n.contains("forearm"): return "hand.raised"
        case let n where n.contains("trap"): return "figure.climbing"
        default: return "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - ViewModel

@MainActor
class MuscleGridViewModel: ObservableObject {
    @Published var muscles: [MuscleCategory] = []
    @Published var isLoading = false
    @Published var error: String?
    
    func loadMuscles() async {
        isLoading = true
        error = nil
        
        do {
            muscles = try await MuscleWikiService.shared.getMuscles()
        } catch {
            self.error = error.localizedDescription
            // Use fallback mock data
            muscles = Self.mockMuscles
        }
        
        isLoading = false
    }
    
    static let mockMuscles: [MuscleCategory] = [
        MuscleCategory(name: "Chest", displayName: "Chest", count: 45),
        MuscleCategory(name: "Biceps", displayName: "Biceps", count: 38),
        MuscleCategory(name: "Triceps", displayName: "Triceps", count: 42),
        MuscleCategory(name: "Shoulders", displayName: "Shoulders", count: 52),
        MuscleCategory(name: "Back", displayName: "Back", count: 48),
        MuscleCategory(name: "Lats", displayName: "Lats", count: 24),
        MuscleCategory(name: "Quadriceps", displayName: "Quadriceps", count: 35),
        MuscleCategory(name: "Hamstrings", displayName: "Hamstrings", count: 28),
        MuscleCategory(name: "Glutes", displayName: "Glutes", count: 32),
        MuscleCategory(name: "Calves", displayName: "Calves", count: 18),
        MuscleCategory(name: "Core", displayName: "Core", count: 45),
        MuscleCategory(name: "Forearms", displayName: "Forearms", count: 22)
    ]
}

#Preview {
    NavigationStack {
        MuscleGridView()
    }
}
