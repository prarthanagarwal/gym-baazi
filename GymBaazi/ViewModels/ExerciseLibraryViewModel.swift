import SwiftUI

/// ViewModel for exercise library with API loading and filtering
@MainActor
class ExerciseLibraryViewModel: ObservableObject {
    @Published var exercises: [MuscleWikiExercise] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedCategory: String?
    @Published var categories: [MuscleCategory] = []
    
    private let service = MuscleWikiService.shared
    
    /// Load exercises for a workout type
    func loadExercises(for workoutType: WorkoutType) async {
        isLoading = true
        error = nil
        
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
            // Use mock data as fallback
            exercises = MuscleWikiService.mockExercises(for: workoutType)
        }
        
        isLoading = false
    }
    
    /// Search exercises by query
    func searchExercises(query: String) async {
        guard query.count >= 2 else {
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await service.searchExercises(query: query)
            exercises = response.results
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Load with mock data (for development/offline)
    func loadMockData(for workoutType: WorkoutType) {
        exercises = MuscleWikiService.mockExercises(for: workoutType)
    }
    
    /// Filter exercises by search text
    func filteredExercises(_ searchText: String) -> [MuscleWikiExercise] {
        guard !searchText.isEmpty else { return exercises }
        
        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(searchText) ||
            (exercise.primaryMuscles?.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ?? false) ||
            (exercise.category?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    /// Select a category filter
    func selectCategory(_ category: String?) {
        selectedCategory = category
        // Could trigger additional filtering here
    }
}
