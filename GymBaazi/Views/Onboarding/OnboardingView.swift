import SwiftUI

/// Multi-step onboarding flow container (4 screens) with dot carousel
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = 25
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var workoutDaysPerWeek = 3
    @State private var appliedSchedule = false
    
    private let totalSteps = 4
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color.orange.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content - swipeable
                TabView(selection: $currentStep) {
                    OnboardingStep1(name: $name, onNext: nextStep)
                        .tag(0)
                    
                    OnboardingStep2(
                        age: $age,
                        heightCm: $heightCm,
                        weightKg: $weightKg,
                        onNext: nextStep
                    )
                    .tag(1)
                    
                    OnboardingStep3(
                        daysPerWeek: $workoutDaysPerWeek,
                        onNext: nextStep
                    )
                    .tag(2)
                    
                    OnboardingStep4(
                        daysPerWeek: workoutDaysPerWeek,
                        onComplete: { applySchedule in
                            appliedSchedule = applySchedule
                            completeOnboarding()
                        }
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                // Dot carousel
                DotIndicator(current: currentStep, total: totalSteps)
                    .padding(.bottom, 40)
            }
        }
    }
    
    private func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        HapticService.shared.light()
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }
    
    private func completeOnboarding() {
        let profile = UserProfile(
            name: name.isEmpty ? "Champ" : name,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg
        )
        
        // Apply suggested schedule if user chose to
        if appliedSchedule {
            let suggestions = WorkoutTemplates.suggestedSchedule(forDaysPerWeek: workoutDaysPerWeek)
            for suggestion in suggestions {
                let day = suggestion.template.toCustomWorkoutDay(forDayOfWeek: suggestion.dayOfWeek)
                appState.addWorkoutDay(day)
            }
        }
        
        appState.completeOnboarding(profile: profile)
    }
}

// MARK: - Dot Indicator

struct DotIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: index == current ? 10 : 8, height: index == current ? 10 : 8)
                    .scaleEffect(index == current ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }
}

// MARK: - Step 1: Name Input

struct OnboardingStep1: View {
    @Binding var name: String
    let onNext: () -> Void
    @FocusState private var isNameFocused: Bool
    
    /// Soft validation warning (doesn't block progression)
    private var nameWarning: String? {
        let trimmed = name.trimmed
        if trimmed.isEmpty {
            return nil // Empty is allowed (defaults to "Champ")
        }
        if trimmed.count == 1 {
            return "Name seems a bit short"
        }
        if trimmed.count > Constants.Validation.nameMaxLength {
            return "Name is quite long (\(trimmed.count)/\(Constants.Validation.nameMaxLength))"
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 70))
                .foregroundStyle(LinearGradient.push)
                .padding(.bottom, 24)
            
            // Title
            Text("What should we call you?")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            Text("This helps us personalize your experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            
            // Name input with soft validation
            TextField("Your name", text: $name)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .focused($isNameFocused)
                .submitLabel(.continue)
                .onSubmit { onNext() }
                .padding(.horizontal, 32)
                .softValidation(nameWarning)
            
            Text("or swipe to continue as 'Champ'")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Spacer()
            Spacer()
            
            // Continue button
            OnboardingButton(title: "Continue", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .onAppear { isNameFocused = true }
    }
}

// MARK: - Step 2: Body Metrics

struct OnboardingStep2: View {
    @Binding var age: Int
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    let onNext: () -> Void
    
    // Computed height in feet and inches
    private var heightFeet: Int {
        Int(heightCm / 30.48)
    }
    
    private var heightInches: Int {
        Int((heightCm - Double(heightFeet) * 30.48) / 2.54)
    }
    
    private var heightDisplay: String {
        "\(heightFeet)' \(heightInches)\""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "figure.stand")
                .font(.system(size: 70))
                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.bottom, 24)
            
            // Title
            Text("Tell us about yourself")
                .font(.title.bold())
                .padding(.bottom, 8)
            
            Text("This helps us track your progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
            
            // Metrics
            VStack(spacing: 24) {
                // Age with slider
                MetricSlider(
                    title: "Age",
                    value: Binding(get: { Double(age) }, set: { age = Int($0) }),
                    range: 13...80,
                    step: 1,
                    unit: "years",
                    displayValue: "\(age)"
                )
                
                // Height in feet/inches
                HeightPicker(heightCm: $heightCm)
                
                // Weight with slider
                MetricSlider(
                    title: "Weight",
                    value: $weightKg,
                    range: 30...200,
                    step: 1,
                    unit: "kg",
                    displayValue: "\(Int(weightKg))"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
            
            // Continue button
            OnboardingButton(title: "Continue", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Metric Slider

struct MetricSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let displayValue: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Label row
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(displayValue) \(unit)")
                    .font(.title3.bold())
                    .foregroundColor(.orange)
            }
            
            // Slider with +/- buttons
            HStack(spacing: 12) {
                // Minus button
                Button(action: {
                    if value > range.lowerBound {
                        value -= step
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
                
                // Slider
                Slider(value: $value, in: range, step: step)
                    .tint(.orange)
                
                // Plus button
                Button(action: {
                    if value < range.upperBound {
                        value += step
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Height Picker (Slider in inches, displayed as ft/in)

struct HeightPicker: View {
    @Binding var heightCm: Double
    
    // Total height in inches for the slider
    private var totalInches: Double {
        heightCm / 2.54
    }
    
    // Display as feet and inches
    private var feet: Int {
        Int(totalInches) / 12
    }
    
    private var inches: Int {
        Int(totalInches) % 12
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Label row
            HStack {
                Text("Height")
                    .font(.headline)
                Spacer()
                Text("\(feet)' \(inches)\"")
                    .font(.title3.bold())
                    .foregroundColor(.orange)
            }
            
            // Slider with +/- buttons (moves 1 inch at a time)
            HStack(spacing: 12) {
                // Minus button
                Button(action: {
                    if totalInches > 48 { // 4 feet minimum
                        heightCm -= 2.54 // 1 inch
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
                
                // Slider (range: 4'0" to 7'0" = 48 to 84 inches)
                Slider(
                    value: Binding(
                        get: { totalInches },
                        set: { heightCm = $0 * 2.54 }
                    ),
                    in: 48...84,
                    step: 1
                )
                .tint(.orange)
                
                // Plus button
                Button(action: {
                    if totalInches < 84 { // 7 feet maximum
                        heightCm += 2.54 // 1 inch
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Step 3: Frequency

struct OnboardingStep3: View {
    @Binding var daysPerWeek: Int
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "calendar")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .padding(.bottom, 24)
            
            // Title
            Text("How often do you work out?")
                .font(.title.bold())
                .padding(.bottom, 8)
            
            Text("We'll suggest a schedule based on this")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 40)
            
            // Big number
            Text("\(daysPerWeek)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            
            Text("days per week")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
            
            // Slider
            Slider(value: Binding(
                get: { Double(daysPerWeek) },
                set: { daysPerWeek = Int($0) }
            ), in: 1...7, step: 1)
            .tint(.orange)
            .padding(.horizontal, 48)
            
            Spacer()
            Spacer()
            
            // Continue button
            OnboardingButton(title: "Continue", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Step 4: Quick Setup

struct OnboardingStep4: View {
    let daysPerWeek: Int
    let onComplete: (Bool) -> Void
    
    var suggestions: [DaySuggestion] {
        WorkoutTemplates.suggestedSchedule(forDaysPerWeek: daysPerWeek)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 70))
                .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.bottom, 24)
            
            // Title
            Text("Here's your plan")
                .font(.title.bold())
                .padding(.bottom, 8)
            
            Text("Based on \(daysPerWeek) days per week")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
            
            // Schedule preview
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(suggestions, id: \.dayOfWeek) { suggestion in
                        ScheduleRow(suggestion: suggestion)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 280)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                OnboardingButton(title: "Use This Plan", action: { onComplete(true) })
                
                Button(action: { onComplete(false) }) {
                    Text("I'll set it up myself")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

struct ScheduleRow: View {
    let suggestion: DaySuggestion
    
    var body: some View {
        HStack(spacing: 12) {
            Text(suggestion.dayName)
                .font(.subheadline.bold())
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.template.name)
                    .font(.subheadline.bold())
                Text("\(suggestion.template.exercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Onboarding Button

struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
