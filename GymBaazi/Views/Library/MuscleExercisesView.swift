import SwiftUI
import AVKit

/// View showing exercises for a specific muscle group
struct MuscleExercisesView: View {
    let muscle: MuscleCategory
    @StateObject private var viewModel = MuscleExercisesViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var selectedExercise: MuscleWikiExercise?
    @State private var showAddToDaySheet = false
    
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
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Equipment filter
                        Menu {
                            Button("All Equipment") { selectedCategory = nil }
                            ForEach(viewModel.categories, id: \.id) { cat in
                                Button(cat.name) { selectedCategory = cat.name }
                            }
                        } label: {
                            FilterChip(
                                title: selectedCategory ?? "Equipment",
                                isActive: selectedCategory != nil
                            )
                        }
                        
                        // Difficulty filter
                        Menu {
                            Button("All Levels") { selectedDifficulty = nil }
                            Button("Novice") { selectedDifficulty = "novice" }
                            Button("Intermediate") { selectedDifficulty = "intermediate" }
                            Button("Advanced") { selectedDifficulty = "advanced" }
                        } label: {
                            FilterChip(
                                title: selectedDifficulty?.capitalized ?? "Difficulty",
                                isActive: selectedDifficulty != nil
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
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
                    },
                    onAddToWorkout: {
                        showAddToDaySheet = true
                    }
                )
            }
        }
        .navigationTitle(muscle.displayName ?? muscle.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(selectedExercise != nil)
        .task {
            await viewModel.loadExercises(for: muscle.name)
            await viewModel.loadCategories()
        }
        .sheet(isPresented: $showAddToDaySheet) {
            if let exercise = selectedExercise {
                AddToDaySheet(exercise: exercise)
            }
        }
    }
    
    private var filteredExercises: [MuscleWikiExercise] {
        var result = viewModel.exercises
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Category filter
        if let cat = selectedCategory {
            result = result.filter { $0.category?.lowercased() == cat.lowercased() }
        }
        
        // Difficulty filter
        if let diff = selectedDifficulty {
            result = result.filter { $0.difficulty?.lowercased() == diff.lowercased() }
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

// MARK: - Exercise Row (Simple)

struct ExerciseRow: View {
    let exercise: MuscleWikiExercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.orange)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let category = exercise.category {
                        Text(category)
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
    let exercise: MuscleWikiExercise
    let onDismiss: () -> Void
    let onAddToWorkout: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var detailedExercise: MuscleWikiExercise?
    @State private var isLoadingDetails = true
    
    var videoURL: URL? {
        // Use detailed exercise if available
        let ex = detailedExercise ?? exercise
        
        // First try to get video URL from API response
        if let videos = ex.videos, !videos.isEmpty {
            // Prefer male video with front angle
            let maleVideo = videos.first { $0.gender?.lowercased() == "male" }
            if let urlString = (maleVideo ?? videos.first)?.url, let url = URL(string: urlString) {
                print("🎬 Using API video URL: \(urlString)")
                return url
            }
        }
        
        // Fallback: Construct video URL from exercise name and category
        guard let category = ex.category else {
            print("🎬 No category for video URL")
            return nil
        }
        
        let slug = ex.name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        let urlString = "https://musclewiki-api.p.rapidapi.com/stream/videos/branded/male-\(category.capitalized)-\(slug)-front.mp4"
        print("🎬 Constructed video URL: \(urlString)")
        return URL(string: urlString)
    }
    
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
                
                // Video Player or Loading
                if isLoadingDetails {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                        ProgressView("Loading...")
                    }
                } else if let url = videoURL {
                    ExerciseVideoPlayer(videoURL: url)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Fallback icon if no video
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                            .frame(height: 150)
                        
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                    }
                }
                
                // Muscle tags
                if let muscles = (detailedExercise ?? exercise).primaryMuscles, !muscles.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(muscles.prefix(3), id: \.self) { muscle in
                            Text(muscle)
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
                    if let category = (detailedExercise ?? exercise).category {
                        Label(category, systemImage: "dumbbell.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let difficulty = (detailedExercise ?? exercise).difficulty {
                        Label(difficulty.capitalized, systemImage: "chart.bar.fill")
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
        .task {
            await loadExerciseDetails()
        }
    }
    
    private func loadExerciseDetails() async {
        let exerciseId = exercise.id
        print("📥 Fetching details for exercise ID: \(exerciseId)")
        
        do {
            let details = try await MuscleWikiService.shared.getExercise(id: exerciseId, detail: true)
            print("✅ Got details: category=\(details.category ?? "nil")")
            detailedExercise = details
        } catch {
            print("❌ Failed to load details: \(error)")
        }
        
        isLoadingDetails = false
    }
}

// MARK: - Exercise Video Player

struct ExerciseVideoPlayer: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        ZStack {
            if let player = player, !hasError {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            }
            
            if isLoading {
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray6))
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            
            if hasError {
                ZStack {
                    Rectangle()
                        .fill(Color.orange.opacity(0.1))
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Video unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        print("🎥 Loading video from: \(videoURL)")
        
        // Create asset with authentication headers
        let headers = [
            "X-RapidAPI-Key": MuscleWikiService.shared.rapidAPIKey,
            "X-RapidAPI-Host": MuscleWikiService.shared.rapidAPIHost
        ]
        
        let asset = AVURLAsset(url: videoURL, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let playerItem = AVPlayerItem(asset: asset)
        
        // Observe status changes
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: playerItem, queue: .main) { _ in
            print("❌ Video failed to play")
            hasError = true
            isLoading = false
        }
        
        // Check if playable using modern async API
        Task {
            do {
                let isPlayable = try await asset.load(.isPlayable)
                await MainActor.run {
                    if isPlayable {
                        print("✅ Asset is playable")
                        let newPlayer = AVPlayer(playerItem: playerItem)
                        newPlayer.isMuted = false
                        player = newPlayer
                        isLoading = false
                        newPlayer.play()
                    } else {
                        print("❌ Asset not playable")
                        hasError = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    print("❌ Failed to load asset: \(error.localizedDescription)")
                    hasError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Add to Day Sheet

struct AddToDaySheet: View {
    let exercise: MuscleWikiExercise
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var selectedDayId: UUID?
    @State private var sets: Int = 3
    @State private var reps: Int = 10
    
    var body: some View {
        NavigationStack {
            Form {
                // Exercise info
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "dumbbell.fill")
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            if let muscles = exercise.primaryMuscles?.joined(separator: ", ") {
                                Text(muscles)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Sets and reps
                Section("Configuration") {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...30)
                }
                
                // Select day
                Section("Add to Day") {
                    if appState.workoutSchedule.days.isEmpty {
                        Text("No workout days created yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appState.workoutSchedule.days) { day in
                            Button(action: { selectedDayId = day.id }) {
                                HStack {
                                    Text(day.name)
                                    Spacer()
                                    if selectedDayId == day.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExercise()
                    }
                    .disabled(selectedDayId == nil)
                }
            }
        }
    }
    
    private func addExercise() {
        guard let dayId = selectedDayId,
              let dayIndex = appState.workoutSchedule.days.firstIndex(where: { $0.id == dayId }) else {
            return
        }
        
        let newExercise = Exercise(
            name: exercise.name,
            sets: sets,
            reps: "\(reps)",
            isCompound: exercise.mechanic == "compound",
            restTime: sets >= 4 ? "2-3 min" : "60-90 sec",
            restSeconds: sets >= 4 ? 150 : 90,
            muscleWikiId: Int(exercise.id)
        )
        
        var updatedDay = appState.workoutSchedule.days[dayIndex]
        updatedDay.exercises.append(newExercise)
        appState.updateWorkoutDay(updatedDay)
        
        HapticService.shared.success()
        dismiss()
    }
}

// MARK: - ViewModel

@MainActor
class MuscleExercisesViewModel: ObservableObject {
    @Published var exercises: [MuscleWikiExercise] = []
    @Published var categories: [EquipmentCategory] = []
    @Published var isLoading = false
    
    func loadExercises(for muscle: String) async {
        isLoading = true
        
        do {
            let response = try await MuscleWikiService.shared.getExercises(
                limit: 100,
                muscles: muscle
            )
            exercises = response.results
        } catch {
            exercises = MuscleWikiService.mockExercises(for: .push)
        }
        
        isLoading = false
    }
    
    func loadCategories() async {
        do {
            categories = try await MuscleWikiService.shared.getCategories()
        } catch {
            categories = []
        }
    }
}

extension MuscleWikiExercise: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: MuscleWikiExercise, rhs: MuscleWikiExercise) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    NavigationStack {
        MuscleExercisesView(muscle: MuscleCategory(name: "chest", displayName: "Chest", count: 50))
            .environmentObject(AppState())
    }
}
