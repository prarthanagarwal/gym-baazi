import SwiftUI

/// Full-screen exercise detail modal with GIF, badges, and instructions
struct ExerciseDetailModal: View {
    let exercise: ExerciseDBExercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // GIF Animation
                    ExerciseGifPlayer(gifUrl: exercise.gifUrl, height: 280)
                        .frame(maxWidth: .infinity)
                    
                    // Exercise name
                    Text(exercise.name.capitalized)
                        .font(.outfit(28, weight: .bold))
                        .padding(.horizontal)
                    
                    // Body Part Badges (Orange)
                    if !exercise.bodyParts.isEmpty {
                        badgeSection(
                            title: "Body Parts",
                            items: exercise.bodyParts,
                            color: .orange
                        )
                    }
                    
                    // Equipment Badges (Cyan)
                    if !exercise.equipments.isEmpty {
                        badgeSection(
                            title: "Equipment",
                            items: exercise.equipments,
                            color: .cyan
                        )
                    }
                    
                    // Target Muscles (Purple)
                    if !exercise.targetMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Target Muscles", systemImage: "target")
                                .font(.outfit(18, weight: .semiBold))
                                .foregroundColor(.purple)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(exercise.targetMuscles, id: \.self) { muscle in
                                    Text(muscle.capitalized)
                                        .font(.outfit(14, weight: .medium))
                                        .foregroundColor(.purple)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Secondary Muscles (Gray)
                    if !exercise.secondaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary Muscles")
                                .font(.outfit(18, weight: .semiBold))
                                .foregroundColor(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                                    Text(muscle.capitalized)
                                        .font(.outfit(14, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Instructions
                    if !exercise.instructions.isEmpty {
                        instructionsSection
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.outfit(28, weight: .semiBold))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Badge Section
    
    private func badgeSection(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.outfit(18, weight: .semiBold))
                .foregroundColor(color)
            
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item.capitalized)
                        .font(.outfit(14, weight: .medium))
                        .foregroundColor(color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How to Perform")
                .font(.outfit(18, weight: .semiBold))
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number
                        Text("\(index + 1)")
                            .font(.outfit(14, weight: .semiBold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.orange)
                            .clipShape(Circle())
                        
                        // Instruction text (clean up "Step:X" prefix if present)
                        Text(cleanInstruction(instruction))
                            .font(.outfit(16, weight: .regular))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func cleanInstruction(_ text: String) -> String {
        // Remove "Step:1 ", "Step:2 " etc. prefixes
        if let range = text.range(of: "^Step:\\d+\\s*", options: .regularExpression) {
            return String(text[range.upperBound...])
        }
        return text
    }
}

#Preview {
    ExerciseDetailModal(
        exercise: ExerciseDBExercise(
            exerciseId: "preview_1",
            name: "barbell bench press",
            gifUrl: "https://static.exercisedb.dev/media/ztAa1RK.gif",
            targetMuscles: ["pectorals"],
            secondaryMuscles: ["triceps", "anterior deltoids"],
            bodyParts: ["chest"],
            equipments: ["barbell"],
            instructions: [
                "Step:1 Lie on a flat bench with your feet flat on the floor.",
                "Step:2 Grip the barbell with hands slightly wider than shoulder-width.",
                "Step:3 Lower the bar to your mid-chest.",
                "Step:4 Press the bar back up to the starting position."
            ]
        )
    )
}
