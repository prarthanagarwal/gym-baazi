import SwiftUI

/// Expandable exercise card with set circles for workout session
struct ExerciseSessionCard: View {
    let exercise: Exercise
    let sets: [ExerciseSet]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onSetTap: (Int) -> Void
    let onSetComplete: (Int) -> Void
    
    var completedSets: Int {
        sets.filter { $0.completed }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onToggleExpand) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text("\(exercise.sets) sets × \(exercise.reps)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if exercise.isCompound {
                                Text("Compound")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundColor(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    HStack(spacing: 4) {
                        Text("\(completedSets)/\(exercise.sets)")
                            .font(.headline)
                            .foregroundColor(completedSets == exercise.sets ? .green : .secondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expandable content
            if isExpanded {
                Divider()
                
                VStack(spacing: 16) {
                    // Set circles
                    HStack(spacing: 12) {
                        ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                            SetCircle(
                                setNumber: index + 1,
                                weight: set.weight,
                                reps: set.reps,
                                isCompleted: set.completed,
                                onTap: { onSetTap(index) },
                                onLongPress: { onSetComplete(index) }
                            )
                        }
                    }
                    
                    // Rest time info
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.secondary)
                        Text("Rest: \(exercise.restTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Set Circle

struct SetCircle: View {
    let setNumber: Int
    let weight: Double
    let reps: Int
    let isCompleted: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color(.systemGray5))
                        .frame(width: 50, height: 50)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    } else {
                        Text("\(setNumber)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if weight > 0 || reps > 0 {
                    VStack(spacing: 0) {
                        Text(weight > 0 ? "\(Int(weight))kg" : "-")
                            .font(.caption2)
                        Text("\(reps)×")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Tap")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
    }
}

#Preview {
    VStack {
        ExerciseSessionCard(
            exercise: Exercise(name: "Bench Press", sets: 4, reps: "6-8", isCompound: true),
            sets: [
                ExerciseSet(exerciseId: "1", exerciseName: "Bench Press", setNumber: 1, reps: 8, weight: 60),
                ExerciseSet(exerciseId: "1", exerciseName: "Bench Press", setNumber: 2, reps: 8, weight: 60),
                ExerciseSet(exerciseId: "1", exerciseName: "Bench Press", setNumber: 3),
                ExerciseSet(exerciseId: "1", exerciseName: "Bench Press", setNumber: 4)
            ],
            isExpanded: true,
            onToggleExpand: {},
            onSetTap: { _ in },
            onSetComplete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
