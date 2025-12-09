import SwiftUI

/// Exercise library with muscle-first browsing and search
struct ExerciseLibraryView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @StateObject private var searchViewModel = ExerciseSearchViewModel()
    @State private var selectedExercise: MuscleWikiExercise?
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if isSearching && !searchText.isEmpty {
                        // Search results
                        searchResultsView
                    } else {
                        // Muscle grid
                        MuscleGridView()
                    }
                }
                .navigationTitle("Exercise Library")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search 1700+ exercises")
                .onChange(of: searchText) { _, newValue in
                    if newValue.count >= 2 {
                        Task {
                            await searchViewModel.search(query: newValue)
                        }
                    }
                }
                
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
        }
    }
    
    private var searchResultsView: some View {
        Group {
            if searchViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
            } else if searchViewModel.results.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No exercises found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if let error = searchViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                List(searchViewModel.results) { exercise in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedExercise = exercise
                        }
                        HapticService.shared.light()
                    } label: {
                        SearchResultRow(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let exercise: MuscleWikiExercise
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.orange)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                
                if let muscles = exercise.primaryMuscles {
                    Text(muscles.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Category badge
            if let category = exercise.category {
                Text(category)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Search ViewModel

@MainActor
class ExerciseSearchViewModel: ObservableObject {
    @Published var results: [MuscleWikiExercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?
    
    func search(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        searchTask = Task {
            isLoading = true
            errorMessage = nil
            
            // Small delay for debouncing
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            do {
                print("🔍 Searching for: \(query)")
                let response = try await MuscleWikiService.shared.searchExercises(query: query, limit: 30)
                print("✅ Found \(response.results.count) results")
                if !Task.isCancelled {
                    results = response.results
                }
            } catch {
                print("❌ Search error: \(error)")
                if !Task.isCancelled {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    results = []
                }
            }
            
            isLoading = false
        }
    }
}

#Preview {
    ExerciseLibraryView()
}
