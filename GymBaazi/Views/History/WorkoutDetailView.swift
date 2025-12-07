import SwiftUI

/// Detailed workout view for history (placeholder - redirects to log card)
struct WorkoutDetailView: View {
    let log: WorkoutLog
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(log.type.emoji)
                            .font(.system(size: 48))
                        
                        Text(log.type.displayName)
                            .font(.title.bold())
                        
                        Text(log.date.formatted(date: .complete, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Stats grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatDetailCard(title: "Duration", value: log.formattedDuration, icon: "clock", color: .orange)
                        StatDetailCard(title: "Sets", value: "\(log.completedSetsCount)", icon: "number", color: .cyan)
                        StatDetailCard(title: "Volume", value: "\(Int(log.totalVolume)) kg", icon: "scalemass", color: .purple)
                        StatDetailCard(title: "Exercises", value: "\(Set(log.sets.map { $0.exerciseName }).count)", icon: "figure.strengthtraining.traditional", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // Exercise breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Exercises Completed")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        let groupedSets = Dictionary(grouping: log.sets) { $0.exerciseName }
                        
                        ForEach(Array(groupedSets.keys.sorted()), id: \.self) { exerciseName in
                            if let sets = groupedSets[exerciseName] {
                                ExerciseBreakdownRow(
                                    name: exerciseName,
                                    sets: sets.filter { $0.completed }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatDetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ExerciseBreakdownRow: View {
    let name: String
    let sets: [ExerciseSet]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(sets) { set in
                    VStack(spacing: 2) {
                        Text("\(Int(set.weight))kg")
                            .font(.caption.bold())
                        Text("×\(set.reps)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkoutDetailView(log: WorkoutLog(
        date: Date(),
        type: .push,
        completed: true,
        duration: 3600,
        sets: [
            ExerciseSet(exerciseId: "1", exerciseName: "Bench Press", setNumber: 1, reps: 8, weight: 60),
            ExerciseSet(exerciseId: "1", exerciseName: "Bench Press", setNumber: 2, reps: 8, weight: 60)
        ]
    ))
}
