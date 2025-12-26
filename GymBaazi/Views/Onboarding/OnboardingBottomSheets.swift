import SwiftUI

// MARK: - Onboarding Row Card (Tap to reveal)

struct OnboardingRowCard: View {
    let icon: String
    let title: String
    let value: String?
    let isSet: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(icon)
                    .font(.system(size: 24))
                    .frame(width: 32)
                
                Text(title)
                    .font(.outfit(18, weight: .semiBold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = value, isSet {
                    HStack(spacing: 8) {
                        Text(value)
                            .font(.outfit(16, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                    }
                } else {
                    HStack(spacing: 4) {
                        Text("Tap to set")
                            .font(.outfit(14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(18)
            .background(Color(.systemGray6))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSet ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Name Input Sheet

struct NameInputSheet: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("What should we call you?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            TextField("Your name", text: $name)
                .font(.outfit(28, weight: .semiBold))
                .multilineTextAlignment(.center)
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { dismiss() }
            
            Text("Leave empty to use 'Champ'")
                .font(.outfit(14, weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Slider with Min/Max Labels

struct LabeledSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let minLabel: String
    let maxLabel: String
    
    var body: some View {
        VStack(spacing: 4) {
            Slider(value: $value, in: range, step: step)
                .tint(.orange)
            
            HStack {
                Text(minLabel)
                    .font(.outfit(10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(maxLabel)
                    .font(.outfit(10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Age Picker Sheet (No +/- buttons, just slider)

struct AgePickerSheet: View {
    @Binding var age: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("How old are you?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            Text("\(age)")
                .font(.outfit(80, weight: .bold))
                .foregroundColor(.orange)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: age)
            
            Text("years old")
                .font(.outfit(18, weight: .medium))
                .foregroundColor(.secondary)
            
            // Slider with min/max labels
            LabeledSlider(
                value: Binding(get: { Double(age) }, set: { age = Int($0); HapticService.shared.light() }),
                range: 13...80,
                step: 1,
                minLabel: "13",
                maxLabel: "80"
            )
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Height Picker Sheet (Words instead of symbols, inches smaller)

struct HeightPickerSheet: View {
    @Binding var heightCm: Double
    @Environment(\.dismiss) private var dismiss
    
    private var totalInches: Double { heightCm / 2.54 }
    private var feet: Int { Int(totalInches) / 12 }
    private var inches: Int { Int(totalInches) % 12 }
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("How tall are you?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            // Height display with words (feet/inches smaller)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(feet)")
                    .font(.outfit(80, weight: .bold))
                    .foregroundColor(.orange)
                Text("ft")
                    .font(.outfit(24, weight: .medium))
                    .foregroundColor(.orange.opacity(0.7))
                Text("\(inches)")
                    .font(.outfit(50, weight: .bold))
                    .foregroundColor(.orange.opacity(0.8))
                Text("in")
                    .font(.outfit(18, weight: .medium))
                    .foregroundColor(.orange.opacity(0.6))
            }
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3), value: Int(totalInches))
            
            // Slider with min/max labels
            LabeledSlider(
                value: Binding(
                    get: { totalInches },
                    set: { heightCm = $0 * 2.54; HapticService.shared.light() }
                ),
                range: 48...84,
                step: 1,
                minLabel: "4 ft",
                maxLabel: "7 ft"
            )
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Weight Picker Sheet

struct WeightPickerSheet: View {
    @Binding var weightKg: Double
    let unit: WeightUnit
    @Environment(\.dismiss) private var dismiss
    
    private var displayValue: Int {
        unit == .lbs ? Int(weightKg * 2.20462) : Int(weightKg)
    }
    
    private var range: ClosedRange<Double> {
        unit == .lbs ? 66...440 : 30...200
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("What's your weight?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(displayValue)")
                    .font(.outfit(80, weight: .bold))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: displayValue)
                
                Text(unit.symbol)
                    .font(.outfit(24, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Slider with min/max labels
            LabeledSlider(
                value: unit == .lbs ?
                    Binding(
                        get: { weightKg * 2.20462 },
                        set: { weightKg = $0 / 2.20462; HapticService.shared.light() }
                    ) : Binding(get: { weightKg }, set: { weightKg = $0; HapticService.shared.light() }),
                range: range,
                step: 1,
                minLabel: unit == .lbs ? "66 lbs" : "30 kg",
                maxLabel: unit == .lbs ? "440 lbs" : "200 kg"
            )
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Frequency Picker Sheet

struct FrequencyPickerSheet: View {
    @Binding var daysPerWeek: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("How often do you train?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            Text("\(daysPerWeek)")
                .font(.outfit(100, weight: .bold))
                .foregroundColor(.orange)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: daysPerWeek)
            
            Text("days per week")
                .font(.outfit(20, weight: .medium))
                .foregroundColor(.secondary)
            
            // Slider with min/max labels
            LabeledSlider(
                value: Binding(get: { Double(daysPerWeek) }, set: { daysPerWeek = Int($0); HapticService.shared.light() }),
                range: 1...7,
                step: 1,
                minLabel: "1",
                maxLabel: "7"
            )
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Optional Age Picker Sheet

struct AgePickerSheetOptional: View {
    @Binding var age: Int?
    @Binding var tempAge: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("How old are you?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            Text("\(tempAge)")
                .font(.outfit(80, weight: .bold))
                .foregroundColor(.orange)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: tempAge)
            
            Text("years old")
                .font(.outfit(18, weight: .medium))
                .foregroundColor(.secondary)
            
            LabeledSlider(
                value: Binding(get: { Double(tempAge) }, set: { tempAge = Int($0); HapticService.shared.light() }),
                range: 13...80,
                step: 1,
                minLabel: "13",
                maxLabel: "80"
            )
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { 
                age = tempAge
                dismiss() 
            }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Optional Height Picker Sheet (Words instead of symbols)

struct HeightPickerSheetOptional: View {
    @Binding var heightCm: Double?
    @Binding var tempHeightCm: Double
    @Environment(\.dismiss) private var dismiss
    
    private var totalInches: Double { tempHeightCm / 2.54 }
    private var feet: Int { Int(totalInches) / 12 }
    private var inches: Int { Int(totalInches) % 12 }
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("How tall are you?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            // Height display with words (inches smaller)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(feet)")
                    .font(.outfit(80, weight: .bold))
                    .foregroundColor(.orange)
                Text("ft")
                    .font(.outfit(24, weight: .medium))
                    .foregroundColor(.orange.opacity(0.7))
                Text("\(inches)")
                    .font(.outfit(50, weight: .bold))
                    .foregroundColor(.orange.opacity(0.8))
                Text("in")
                    .font(.outfit(18, weight: .medium))
                    .foregroundColor(.orange.opacity(0.6))
            }
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3), value: Int(totalInches))
            
            LabeledSlider(
                value: Binding(
                    get: { totalInches },
                    set: { tempHeightCm = $0 * 2.54; HapticService.shared.light() }
                ),
                range: 48...84,
                step: 1,
                minLabel: "4 ft",
                maxLabel: "7 ft"
            )
            
            Spacer()
            
            Button(action: { 
                heightCm = tempHeightCm
                dismiss() 
            }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Optional Weight Picker Sheet

struct WeightPickerSheetOptional: View {
    @Binding var weightKg: Double?
    @Binding var tempWeightKg: Double
    let unit: WeightUnit
    @Environment(\.dismiss) private var dismiss
    
    private var displayValue: Int {
        unit == .lbs ? Int(tempWeightKg * 2.20462) : Int(tempWeightKg)
    }
    
    private var range: ClosedRange<Double> {
        unit == .lbs ? 66...440 : 30...200
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("What's your weight?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(displayValue)")
                    .font(.outfit(80, weight: .bold))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: displayValue)
                
                Text(unit.symbol)
                    .font(.outfit(24, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            LabeledSlider(
                value: unit == .lbs ?
                    Binding(
                        get: { tempWeightKg * 2.20462 },
                        set: { tempWeightKg = $0 / 2.20462; HapticService.shared.light() }
                    ) : Binding(get: { tempWeightKg }, set: { tempWeightKg = $0; HapticService.shared.light() }),
                range: range,
                step: 1,
                minLabel: unit == .lbs ? "66 lbs" : "30 kg",
                maxLabel: unit == .lbs ? "440 lbs" : "200 kg"
            )
            
            Spacer()
            
            Button(action: { 
                weightKg = tempWeightKg
                dismiss() 
            }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Optional Frequency Picker Sheet

struct FrequencyPickerSheetOptional: View {
    @Binding var daysPerWeek: Int?
    @Binding var tempDays: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("How often do you train?")
                .font(.outfit(24, weight: .bold))
                .padding(.top, 8)
            
            Text("\(tempDays)")
                .font(.outfit(100, weight: .bold))
                .foregroundColor(.orange)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: tempDays)
            
            Text("days per week")
                .font(.outfit(20, weight: .medium))
                .foregroundColor(.secondary)
            
            LabeledSlider(
                value: Binding(get: { Double(tempDays) }, set: { tempDays = Int($0); HapticService.shared.light() }),
                range: 1...7,
                step: 1,
                minLabel: "1",
                maxLabel: "7"
            )
            
            Spacer()
            
            Button(action: { 
                daysPerWeek = tempDays
                dismiss() 
            }) {
                Text("Done")
                    .font(.outfit(18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.orange)
                    .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    OnboardingRowCard(
        icon: "👤",
        title: "Name",
        value: nil,
        isSet: false,
        action: {}
    )
    .padding()
}
