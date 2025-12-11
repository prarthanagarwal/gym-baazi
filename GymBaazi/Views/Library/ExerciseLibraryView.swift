import SwiftUI

// MARK: - Body Part Definition

/// Body parts with associated styling
enum BodyPart: String, CaseIterable, Identifiable {
    case back, chest, shoulders
    case upperArms = "upper arms"
    case lowerArms = "lower arms"
    case upperLegs = "upper legs"
    case lowerLegs = "lower legs"
    case waist, cardio, neck
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .back: return "figure.strengthtraining.traditional"
        case .chest: return "heart.fill"
        case .shoulders: return "figure.arms.open"
        case .upperArms: return "figure.boxing"
        case .lowerArms: return "hand.raised.fill"
        case .upperLegs: return "figure.run"
        case .lowerLegs: return "figure.walk"
        case .waist: return "figure.core.training"
        case .cardio: return "heart.circle.fill"
        case .neck: return "person.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .back: return [Color.cyan.opacity(0.6), Color.blue.opacity(0.4)]
        case .chest: return [Color.orange.opacity(0.6), Color.red.opacity(0.4)]
        case .shoulders: return [Color.yellow.opacity(0.6), Color.orange.opacity(0.4)]
        case .upperArms: return [Color.purple.opacity(0.6), Color.pink.opacity(0.4)]
        case .lowerArms: return [Color.indigo.opacity(0.6), Color.purple.opacity(0.4)]
        case .upperLegs: return [Color.green.opacity(0.6), Color.teal.opacity(0.4)]
        case .lowerLegs: return [Color.teal.opacity(0.6), Color.cyan.opacity(0.4)]
        case .waist: return [Color.pink.opacity(0.6), Color.red.opacity(0.3)]
        case .cardio: return [Color.red.opacity(0.6), Color.orange.opacity(0.4)]
        case .neck: return [Color.gray.opacity(0.5), Color.secondary.opacity(0.3)]
        }
    }
}

// MARK: - Main Library View

/// Exercise library with body part grid and search
struct ExerciseLibraryView: View {
    @StateObject private var viewModel = ExerciseLibraryViewModel()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedBodyPart: BodyPart?
    @State private var selectedExercise: ExerciseDBExercise?
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isSearching && !searchText.isEmpty {
                    searchResultsView
                } else {
                    bodyPartGridView
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search 1500+ exercises")
            .onChange(of: searchText) { _, newValue in
                if newValue.count >= 2 {
                    Task { await viewModel.searchExercises(query: newValue) }
                }
            }
            .navigationDestination(item: $selectedBodyPart) { bodyPart in
                BodyPartExercisesView(bodyPart: bodyPart)
            }
            .task {
                await viewModel.loadBodyPartCounts()
            }
        }
    }
    
    // MARK: - Body Part Grid
    
    private var bodyPartGridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with count
                HStack {
                    Text("\(viewModel.totalExerciseCount) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                
                // 2x2 Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(BodyPart.allCases) { bodyPart in
                        BodyPartCard(
                            bodyPart: bodyPart,
                            count: viewModel.exerciseCounts[bodyPart.rawValue] ?? 0
                        )
                        .onTapGesture {
                            selectedBodyPart = bodyPart
                            HapticService.shared.light()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsView: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
            } else if viewModel.exercises.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No exercises found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.exercises) { exercise in
                            ExerciseCard(exercise: exercise)
                                .onTapGesture {
                                    selectedExercise = exercise
                                    HapticService.shared.light()
                                }
                        }
                    }
                    .padding()
                }
                .sheet(item: $selectedExercise) { exercise in
                    ExerciseDetailModal(exercise: exercise)
                }
            }
        }
    }
}

// MARK: - Body Part Card

struct BodyPartCard: View {
    let bodyPart: BodyPart
    let count: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: bodyPart.icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
            
            // Title
            Text(bodyPart.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            // Count
            Text("\(count) exercises")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(
            LinearGradient(
                colors: bodyPart.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: bodyPart.gradientColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Exercise Card (2x2 Grid)

struct ExerciseCard: View {
    let exercise: ExerciseDBExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // GIF Preview
            ExerciseGifThumbnail(gifUrl: exercise.gifUrl, size: 140)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Name
            Text(exercise.name)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Tags
            HStack(spacing: 4) {
                if let muscle = exercise.targetMuscles.first {
                    Text(muscle.capitalized)
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                if let equipment = exercise.primaryEquipment {
                    Text(equipment.capitalized)
                        .font(.caption2)
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - ViewModel

@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [ExerciseDBExercise] = []
    @Published var exerciseCounts: [String: Int] = [:]
    @Published var isLoading = false
    @Published var totalExerciseCount = 0
    
    private var searchTask: Task<Void, Never>?
    private let service = ExerciseDBService.shared
    
    // MARK: - Body Part Counts (for grid view)
    
    func loadBodyPartCounts() async {
        // Reset counts to prevent accumulation on reload
        exerciseCounts = [:]
        totalExerciseCount = 0
        
        do {
            let bodyParts = try await service.getBodyParts()
            
            // Fetch count for each body part
            for part in bodyParts {
                let result = try await service.getExercisesByBodyPart(bodyPart: part.name, limit: 1)
                if let metadata = result.metadata {
                    exerciseCounts[part.name] = metadata.totalExercises
                    totalExerciseCount += metadata.totalExercises
                }
            }
        } catch {
            print("Error loading body part counts: \(error)")
        }
    }
    
    // MARK: - Load All Exercises (for AddExerciseFlow)
    
    func loadExercises() async {
        isLoading = true
        
        do {
            let result = try await service.getExercises(limit: 25)
            exercises = result.exercises
        } catch {
            exercises = ExerciseDBService.mockExercises
        }
        
        isLoading = false
    }
    
    // MARK: - Search Exercises
    
    func searchExercises(query: String) async {
        searchTask?.cancel()
        
        searchTask = Task {
            isLoading = true
            
            try? await Task.sleep(nanoseconds: 300_000_000) // Debounce
            guard !Task.isCancelled else { return }
            
            do {
                let result = try await service.searchExercises(query: query, limit: 25)
                if !Task.isCancelled {
                    exercises = result.exercises
                }
            } catch {
                exercises = []
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Filter Exercises (client-side for search bar)
    
    func filteredExercises(_ searchText: String) -> [ExerciseDBExercise] {
        guard !searchText.isEmpty else { return exercises }
        
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            exercise.targetMuscles.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
            exercise.equipments.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
        }
    }
}

#Preview {
    ExerciseLibraryView()
}
