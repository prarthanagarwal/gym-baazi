import SwiftUI

/// Expandable exercise card with set circles for workout session
struct ExerciseSessionCard: View {
    @Environment(\.colorScheme) var colorScheme
    let exercise: Exercise
    let sets: [ExerciseSet]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onSetTap: (Int) -> Void
    let onSetComplete: (Int) -> Void
    
    var completedSets: Int {
        sets.filter { $0.completed }.count
    }
    
    /// Border color adapts to color scheme for better visibility
    private var borderColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.2) 
            : Color.black.opacity(0.05)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: onToggleExpand) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.outfit(18, weight: .semiBold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Text("\(exercise.sets) sets × \(exercise.reps)")
                                .font(.outfit(14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if exercise.isCompound {
                                Text("Compound")
                                    .font(.outfit(11, weight: .semiBold))
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
                            .font(.outfit(18, weight: .semiBold))
                            .foregroundColor(completedSets == exercise.sets ? .green : .secondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.outfit(12, weight: .regular))
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
                            .font(.outfit(12, weight: .regular))
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: colorScheme == .dark ? 1 : 0.5)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 5, x: 0, y: 2)
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
    
    var hasData: Bool {
        weight > 0 && reps > 0  // Require BOTH weight and reps to be filled
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : Color(.systemGray5))
                            .frame(width: 50, height: 50)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.outfit(18, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(setNumber)")
                                .font(.outfit(18, weight: .semiBold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if hasData {
                        VStack(spacing: 0) {
                            Text(weight > 0 ? "\(Int(weight))kg" : "-")
                                .font(.outfit(11, weight: .regular))
                            Text("\(reps)×")
                                .font(.outfit(11, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Tap")
                            .font(.outfit(11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Tick button - appears when data entered but not completed
            if hasData && !isCompleted {
                Button(action: {
                    onLongPress()
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.outfit(20, weight: .regular))
                        .foregroundColor(.green)
                        .background(Circle().fill(Color(.systemBackground)).padding(2))
                }
                .offset(x: 6, y: -6)
            }
        }
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
