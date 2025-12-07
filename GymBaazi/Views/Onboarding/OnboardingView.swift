import SwiftUI

/// Multi-step onboarding flow container (4 screens)
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
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(current: currentStep, total: totalSteps)
                    .padding(.top, 20)
                    .padding(.horizontal, 40)
                
                // Content
                TabView(selection: $currentStep) {
                    NameInputView(name: $name, onNext: nextStep)
                        .tag(0)
                    
                    BodyMetricsView(
                        age: $age,
                        heightCm: $heightCm,
                        weightKg: $weightKg,
                        onNext: nextStep,
                        onBack: previousStep
                    )
                    .tag(1)
                    
                    FrequencyView(
                        daysPerWeek: $workoutDaysPerWeek,
                        onNext: nextStep,
                        onBack: previousStep
                    )
                    .tag(2)
                    
                    QuickSetupView(
                        daysPerWeek: workoutDaysPerWeek,
                        onComplete: { applySchedule in
                            appliedSchedule = applySchedule
                            completeOnboarding()
                        },
                        onBack: previousStep
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
    }
    
    private func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        HapticService.shared.light()
        withAnimation {
            currentStep += 1
        }
    }
    
    private func previousStep() {
        guard currentStep > 0 else { return }
        HapticService.shared.light()
        withAnimation {
            currentStep -= 1
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

// MARK: - Frequency View

struct FrequencyView: View {
    @Binding var daysPerWeek: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // Title
            VStack(spacing: 8) {
                Text("How often do you work out?")
                    .font(.title2.bold())
                
                Text("We'll suggest a schedule based on this")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Slider
            VStack(spacing: 16) {
                Text("\(daysPerWeek)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text("days per week")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { Double(daysPerWeek) },
                    set: { daysPerWeek = Int($0) }
                ), in: 1...7, step: 1)
                .tint(.orange)
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 32)
            
            Spacer()
            
            // Navigation
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onNext) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Quick Setup View

struct QuickSetupView: View {
    let daysPerWeek: Int
    let onComplete: (Bool) -> Void
    let onBack: () -> Void
    
    var suggestions: [DaySuggestion] {
        WorkoutTemplates.suggestedSchedule(forDaysPerWeek: daysPerWeek)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Title
            VStack(spacing: 8) {
                Text("Here's your suggested plan")
                    .font(.title2.bold())
                
                Text("Based on \(daysPerWeek) days per week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Schedule preview
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(suggestions, id: \.dayOfWeek) { suggestion in
                        SchedulePreviewRow(suggestion: suggestion)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: { onComplete(true) }) {
                    Text("Use This Plan")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: { onComplete(false) }) {
                    Text("I'll set it up myself")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            
            // Back button
            Button(action: onBack) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
        }
    }
}

struct SchedulePreviewRow: View {
    let suggestion: DaySuggestion
    
    var body: some View {
        HStack(spacing: 16) {
            // Day
            Text(suggestion.dayName)
                .font(.headline)
                .frame(width: 44)
            
            // Template info
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.template.name)
                    .font(.subheadline.bold())
                
                Text(suggestion.template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Exercise count
            Text("\(suggestion.template.exercises.count)")
                .font(.caption.bold())
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.orange : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
