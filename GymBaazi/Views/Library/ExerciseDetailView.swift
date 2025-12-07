import SwiftUI
import AVKit

/// Detailed exercise view with video player and instructions
struct ExerciseDetailView: View {
    let exercise: MuscleWikiExercise
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Video player placeholder
                    videoSection
                    
                    // Exercise info
                    VStack(alignment: .leading, spacing: 16) {
                        // Title
                        Text(exercise.name)
                            .font(.title2.bold())
                        
                        // Muscle groups
                        muscleSection
                        
                        // Details grid
                        detailsGrid
                        
                        // Instructions
                        if let steps = exercise.steps, !steps.isEmpty {
                            instructionsSection(steps: steps)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Video Section
    
    private var videoSection: some View {
        ZStack {
            Rectangle()
                .fill(Color(.systemGray5))
                .aspectRatio(16/9, contentMode: .fit)
            
            // Placeholder when no video
            VStack(spacing: 8) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Video demonstration")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Muscle Section
    
    private var muscleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Muscles")
                .font(.headline)
            
            HStack(spacing: 8) {
                if let primary = exercise.primaryMuscles {
                    ForEach(primary, id: \.self) { muscle in
                        MuscleBadge(muscle: muscle, isPrimary: true)
                    }
                }
                
                if let secondary = exercise.secondaryMuscles {
                    ForEach(secondary.prefix(3), id: \.self) { muscle in
                        MuscleBadge(muscle: muscle, isPrimary: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Details Grid
    
    private var detailsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            if let category = exercise.category {
                DetailCard(title: "Equipment", value: category, icon: "dumbbell")
            }
            
            if let mechanic = exercise.mechanic {
                DetailCard(title: "Type", value: mechanic.capitalized, icon: "gearshape")
            }
            
            if let difficulty = exercise.difficulty {
                DetailCard(title: "Difficulty", value: difficulty.capitalized, icon: "speedometer")
            }
            
            if let force = exercise.force {
                DetailCard(title: "Force", value: force.capitalized, icon: "arrow.up.arrow.down")
            }
        }
    }
    
    // MARK: - Instructions Section
    
    private func instructionsSection(steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Perform")
                .font(.headline)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.orange)
                        .clipShape(Circle())
                    
                    Text(step)
                        .font(.body)
                }
            }
        }
    }
}

// MARK: - Detail Card

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ExerciseDetailView(
        exercise: MuscleWikiExercise(
            id: 1,
            name: "Bench Press",
            primaryMuscles: ["Chest"],
            secondaryMuscles: ["Triceps", "Shoulders"],
            category: "Barbell",
            force: "push",
            grips: nil,
            mechanic: "compound",
            difficulty: "intermediate",
            steps: ["Lie on the bench", "Grip the bar", "Lower to chest", "Press up"],
            videos: nil
        )
    )
}
