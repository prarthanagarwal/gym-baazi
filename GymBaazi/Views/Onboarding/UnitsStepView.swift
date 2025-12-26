import SwiftUI

/// Step 2: Unit selection screen - Smaller kg/lbs buttons with auto-advance
struct UnitsStepView: View {
    @Binding var selectedUnit: WeightUnit
    let onNext: () -> Void
    
    @State private var hasAppeared = false
    @State private var hasSelected = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            Text("Choose your units")
                .font(.outfit(32, weight: .bold))
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                .padding(.bottom, 12)
            
            Text("For tracking your weight")
                .font(.outfit(16, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                .padding(.bottom, 48)
            
            // Unit buttons (smaller, side by side)
            HStack(spacing: 16) {
                // Kilograms button
                UnitButton(
                    unit: "kg",
                    subtitle: "Kilograms",
                    isSelected: selectedUnit == .kg,
                    action: {
                        selectUnit(.kg)
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
                
                // Pounds button
                UnitButton(
                    unit: "lbs",
                    subtitle: "Pounds",
                    isSelected: selectedUnit == .lbs,
                    action: {
                        selectUnit(.lbs)
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            hasAppeared = true
        }
    }
    
    private func selectUnit(_ unit: WeightUnit) {
        guard !hasSelected else { return }
        hasSelected = true
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedUnit = unit
        }
        HapticService.shared.success()
        
        // Auto-advance after 0.8 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onNext()
        }
    }
}

// MARK: - Unit Button (Smaller version)

struct UnitButton: View {
    let unit: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(unit)
                    .font(.outfit(36, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(subtitle)
                    .font(.outfit(12, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ?
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.orange : Color.gray.opacity(0.2), lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: isSelected ? .orange.opacity(0.3) : .clear, radius: 10, x: 0, y: 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UnitsStepView(selectedUnit: .constant(.kg), onNext: {})
}
