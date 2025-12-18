import SwiftUI

/// Sheet for inputting weight and reps for a set
struct SetInputSheet: View {
    let exercise: Exercise
    let setIndex: Int
    @State var currentWeight: Double
    @State var currentReps: Int
    let onSave: (Double, Int) -> Void
    @Environment(\.dismiss) var dismiss
    
    // Presets based on exercise type
    var weightPresets: [Double] {
        exercise.isCompound
            ? [20, 40, 60, 80, 100, 120]
            : [5, 10, 15, 20, 25, 30]
    }
    
    var repPresets: [Int] {
        let range = parseRepRange(exercise.reps)
        return Array(stride(from: max(range.lower - 2, 1), through: range.upper + 4, by: 2))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with exercise info
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.outfit(28, weight: .bold))
                    
                    HStack(spacing: 4) {
                        Text("Set")
                        Text("\(setIndex + 1)")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("of \(exercise.sets)")
                    }
                    .font(.outfit(14, weight: .medium))
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Weight section
                        VStack(spacing: 12) {
                            // Section header
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(.orange)
                                Text("Weight")
                                    .font(.outfit(18, weight: .semiBold))
                                Spacer()
                                Text("kg")
                                    .font(.outfit(12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Weight display with +/- buttons
                            HStack(spacing: 16) {
                                Button(action: {
                                    if currentWeight >= 2.5 {
                                        currentWeight -= 2.5
                                        HapticService.shared.light()
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.outfit(22, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                        .background(Color.orange)
                                        .clipShape(Circle())
                                }
                                
                                Text(String(format: "%.1f", currentWeight))
                                    .font(.outfit(44, weight: .bold))
                                    .frame(minWidth: 120)
                                
                                Button(action: {
                                    currentWeight += 2.5
                                    HapticService.shared.light()
                                }) {
                                    Image(systemName: "plus")
                                        .font(.outfit(22, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                        .background(Color.orange)
                                        .clipShape(Circle())
                                }
                            }
                            
                            // Quick presets
                            HStack(spacing: 8) {
                                ForEach(weightPresets, id: \.self) { weight in
                                    Button(action: {
                                        currentWeight = weight
                                        HapticService.shared.medium()
                                    }) {
                                        Text("\(Int(weight))")
                                            .font(.outfit(12, weight: .semiBold))
                                            .foregroundColor(currentWeight == weight ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(currentWeight == weight ? Color.orange : Color(.systemGray5))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Reps section
                        VStack(spacing: 16) {
                            // Section header
                            HStack {
                                Image(systemName: "repeat")
                                    .foregroundColor(.cyan)
                                Text("Reps")
                                    .font(.outfit(18, weight: .semiBold))
                                Spacer()
                                Text("Target: \(exercise.reps)")
                                    .font(.outfit(12, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Reps display with +/- buttons
                            HStack(spacing: 24) {
                                Button(action: {
                                    if currentReps > 1 {
                                        currentReps -= 1
                                        HapticService.shared.light()
                                    }
                                }) {
                                    Image(systemName: "minus")
                                        .font(.outfit(28, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.cyan)
                                        .clipShape(Circle())
                                }
                                
                                Text("\(currentReps)")
                                    .font(.outfit(56, weight: .bold))
                                    .frame(minWidth: 100)
                                
                                Button(action: {
                                    currentReps += 1
                                    HapticService.shared.light()
                                }) {
                                    Image(systemName: "plus")
                                        .font(.outfit(28, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.cyan)
                                        .clipShape(Circle())
                                }
                            }
                            
                            // Quick presets
                            HStack(spacing: 10) {
                                ForEach(repPresets, id: \.self) { rep in
                                    Button(action: {
                                        currentReps = rep
                                        HapticService.shared.medium()
                                    }) {
                                        Text("\(rep)")
                                            .font(.outfit(14, weight: .semiBold))
                                            .foregroundColor(currentReps == rep ? .white : .primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(currentReps == rep ? Color.cyan : Color(.systemGray5))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding()
                }
                
                // Save button
                Button(action: {
                    onSave(currentWeight, currentReps)
                    HapticService.shared.success()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save Set")
                            .fontWeight(.semibold)
                    }
                    .font(.outfit(18, weight: .semiBold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func parseRepRange(_ reps: String) -> (lower: Int, upper: Int) {
        let parts = reps.split(separator: "-").compactMap { Int($0) }
        if parts.count == 2 {
            return (parts[0], parts[1])
        }
        return (8, 12)
    }
}

#Preview {
    SetInputSheet(
        exercise: Exercise(name: "Bench Press", sets: 4, reps: "6-8", isCompound: true),
        setIndex: 0,
        currentWeight: 60,
        currentReps: 8,
        onSave: { _, _ in }
    )
}
