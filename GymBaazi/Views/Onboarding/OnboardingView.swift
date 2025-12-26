import SwiftUI

/// Multi-step onboarding flow container (6 screens) with dot carousel
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age: Int? = nil
    @State private var heightCm: Double? = nil
    @State private var weightKg: Double? = nil
    @State private var workoutDaysPerWeek: Int? = nil
    @State private var selectedUnit: WeightUnit = .kg
    @State private var appliedSchedule = false
    @State private var hasSelectedUnit = false  // Track if user has selected a unit
    
    private let totalSteps = 6
    
    // Check if we can navigate forward from current step
    private var canSwipeForward: Bool {
        switch currentStep {
        case 0: return true  // Welcome -> Units is always allowed
        case 1: return hasSelectedUnit  // Units -> About You requires selection
        default: return true  // Other steps allow forward navigation
        }
    }
    
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
                // Content - conditionally disable swipe
                TabView(selection: Binding(
                    get: { currentStep },
                    set: { newValue in
                        // Allow going back always
                        if newValue < currentStep {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep = newValue
                            }
                        } else if canSwipeForward {
                            // Only allow forward if conditions are met
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentStep = newValue
                            }
                        }
                    }
                )) {
                    // Step 0: Welcome
                    WelcomeStepView(onNext: nextStep)
                        .tag(0)
                    
                    // Step 1: Units
                    UnitsStepView(
                        selectedUnit: $selectedUnit,
                        onNext: {
                            hasSelectedUnit = true
                            nextStep()
                        }
                    )
                    .tag(1)
                    
                    // Step 2: About You (Name + Age)
                    AboutYouStepView(name: $name, age: $age, onNext: nextStep)
                        .tag(2)
                    
                    // Step 3: Body & Training
                    BodyTrainingStepView(
                        heightCm: $heightCm,
                        weightKg: $weightKg,
                        daysPerWeek: $workoutDaysPerWeek,
                        selectedUnit: selectedUnit,
                        onNext: nextStep
                    )
                    .tag(3)
                    
                    // Step 4: Notifications
                    NotificationsStepView(onNext: nextStep, onSkip: nextStep)
                        .tag(4)
                    
                    // Step 5: Plan Ready
                    PlanReadyStepView(
                        daysPerWeek: workoutDaysPerWeek ?? 3,
                        onComplete: { applySchedule in
                            appliedSchedule = applySchedule
                            completeOnboarding()
                        }
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                
                // Dot carousel
                DotIndicator(current: currentStep, total: totalSteps)
                    .padding(.bottom, 40)
            }
        }
    }
    
    private func nextStep() {
        guard currentStep < totalSteps - 1 else { return }
        HapticService.shared.light()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep += 1
        }
    }
    
    private func completeOnboarding() {
        let profile = UserProfile(
            name: name.isEmpty ? "Champ" : name,
            age: age ?? 25,
            heightCm: heightCm ?? 170,
            weightKg: weightKg ?? 70,
            preferredUnit: selectedUnit
        )
        
        // Apply suggested schedule if user chose to
        if appliedSchedule {
            let suggestions = WorkoutTemplates.suggestedSchedule(forDaysPerWeek: workoutDaysPerWeek ?? 3)
            for suggestion in suggestions {
                let day = suggestion.template.toCustomWorkoutDay(forDayOfWeek: suggestion.dayOfWeek)
                appState.addWorkoutDay(day)
            }
        }
        
        HapticService.shared.success()
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
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Step 0: Welcome

struct WelcomeStepView: View {
    let onNext: () -> Void
    
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo with bounce animation
            Image("SplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140, height: 140)
                .scaleEffect(hasAppeared ? 1.0 : 0.3)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.5), value: hasAppeared)
                .padding(.bottom, 32)
            
            // Title with staggered animation
            Text("Welcome to")
                .font(.outfit(24, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
            
            Text("GymBaazi")
                .font(.outfit(48, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: hasAppeared)
                .padding(.bottom, 16)
            
            Text("Track workouts. Build strength. Stay consistent.")
                .font(.outfit(16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: hasAppeared)
            
            Spacer()
            Spacer()
            
            // Get Started button
            OnboardingButton(title: "Get Started", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 40)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: hasAppeared)
        }
        .onAppear {
            hasAppeared = true
        }
    }
}

// MARK: - Step 2: About You (Name + Age) - Bottom Sheet Pattern

struct AboutYouStepView: View {
    @Binding var name: String
    @Binding var age: Int?
    let onNext: () -> Void
    
    @State private var hasAppeared = false
    @State private var showNameSheet = false
    @State private var showAgeSheet = false
    @State private var tempAge: Int = 25
    
    // MARK: - Validation
    
    private var isNameSet: Bool { !name.isEmpty }
    private var isAgeSet: Bool { age != nil }
    private var isFormComplete: Bool { isNameSet && isAgeSet }
    
    private var nameDisplay: String? { name.isEmpty ? nil : name }
    private var ageDisplay: String? { age.map { "\($0) years" } }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "person.fill")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(hasAppeared ? 1.0 : 0.5)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: hasAppeared)
                .padding(.bottom, 24)
            
            // Title
            Text("About you")
                .font(.outfit(34, weight: .bold))
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                .padding(.bottom, 8)
            
            Text("Tap each field to set your info")
                .font(.outfit(14, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                .padding(.bottom, 32)
            
            // Row cards
            VStack(spacing: 14) {
                OnboardingRowCard(
                    icon: "👤",
                    title: "Name",
                    value: nameDisplay,
                    isSet: isNameSet,
                    action: { showNameSheet = true }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(x: hasAppeared ? 0 : -50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
                
                OnboardingRowCard(
                    icon: "🎂",
                    title: "Age",
                    value: ageDisplay,
                    isSet: isAgeSet,
                    action: { 
                        tempAge = age ?? 25
                        showAgeSheet = true 
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(x: hasAppeared ? 0 : -50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
            
            // Continue button - only visible when form is complete
            if isFormComplete {
                OnboardingButton(title: "Continue", action: onNext)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFormComplete)
        .onAppear {
            hasAppeared = true
        }
        .sheet(isPresented: $showNameSheet) {
            NameInputSheet(name: $name)
        }
        .sheet(isPresented: $showAgeSheet) {
            AgePickerSheetOptional(age: $age, tempAge: $tempAge)
        }
    }
}

// MARK: - Step 3: Body & Training - Bottom Sheet Pattern

struct BodyTrainingStepView: View {
    @Binding var heightCm: Double?
    @Binding var weightKg: Double?
    @Binding var daysPerWeek: Int?
    let selectedUnit: WeightUnit
    let onNext: () -> Void
    
    @State private var hasAppeared = false
    @State private var showHeightSheet = false
    @State private var showWeightSheet = false
    @State private var showFrequencySheet = false
    
    // Temp values for sheets
    @State private var tempHeightCm: Double = 170
    @State private var tempWeightKg: Double = 70
    @State private var tempDays: Int = 3
    
    // MARK: - Validation
    
    private var isHeightSet: Bool { heightCm != nil }
    private var isWeightSet: Bool { weightKg != nil }
    private var isFrequencySet: Bool { daysPerWeek != nil }
    private var isFormComplete: Bool { isHeightSet && isWeightSet && isFrequencySet }
    
    // Height display
    private var heightDisplay: String? {
        guard let heightCm = heightCm else { return nil }
        let totalInches = heightCm / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches) % 12
        return "\(feet)' \(inches)\""
    }
    
    // Weight display based on unit preference
    private var weightDisplay: String? {
        guard let weightKg = weightKg else { return nil }
        if selectedUnit == .lbs {
            let lbs = weightKg * 2.20462
            return "\(Int(lbs)) lbs"
        }
        return "\(Int(weightKg)) kg"
    }
    
    // Training frequency display
    private var frequencyDisplay: String? {
        guard let days = daysPerWeek else { return nil }
        return "\(days) days/week"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "figure.stand")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(hasAppeared ? 1.0 : 0.5)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: hasAppeared)
                .padding(.bottom, 24)
            
            // Title
            Text("Your body & training")
                .font(.outfit(34, weight: .bold))
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                .padding(.bottom, 8)
            
            Text("Tap each field to set your info")
                .font(.outfit(14, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                .padding(.bottom, 32)
            
            // Row cards
            VStack(spacing: 14) {
                OnboardingRowCard(
                    icon: "📏",
                    title: "Height",
                    value: heightDisplay,
                    isSet: isHeightSet,
                    action: { 
                        tempHeightCm = heightCm ?? 170
                        showHeightSheet = true 
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(x: hasAppeared ? 0 : -50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: hasAppeared)
                
                OnboardingRowCard(
                    icon: "⚖️",
                    title: "Weight",
                    value: weightDisplay,
                    isSet: isWeightSet,
                    action: { 
                        tempWeightKg = weightKg ?? 70
                        showWeightSheet = true 
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(x: hasAppeared ? 0 : -50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: hasAppeared)
                
                OnboardingRowCard(
                    icon: "🏃",
                    title: "Training",
                    value: frequencyDisplay,
                    isSet: isFrequencySet,
                    action: { 
                        tempDays = daysPerWeek ?? 3
                        showFrequencySheet = true 
                    }
                )
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(x: hasAppeared ? 0 : -50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: hasAppeared)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
            
            // Continue button - only visible when form is complete
            if isFormComplete {
                OnboardingButton(title: "Continue", action: onNext)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFormComplete)
        .onAppear {
            hasAppeared = true
        }
        .sheet(isPresented: $showHeightSheet) {
            HeightPickerSheetOptional(heightCm: $heightCm, tempHeightCm: $tempHeightCm)
        }
        .sheet(isPresented: $showWeightSheet) {
            WeightPickerSheetOptional(weightKg: $weightKg, tempWeightKg: $tempWeightKg, unit: selectedUnit)
        }
        .sheet(isPresented: $showFrequencySheet) {
            FrequencyPickerSheetOptional(daysPerWeek: $daysPerWeek, tempDays: $tempDays)
        }
    }
}

// MARK: - Weight Slider (Unit-aware)

struct WeightSlider: View {
    @Binding var weightKg: Double
    let unit: WeightUnit
    
    private var displayValue: Double {
        unit == .lbs ? weightKg * 2.20462 : weightKg
    }
    
    private var range: ClosedRange<Double> {
        unit == .lbs ? 66...440 : 30...200
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Label row
            HStack {
                Text("Weight")
                    .font(.outfit(18, weight: .semiBold))
                Spacer()
                Text("\(Int(displayValue)) \(unit.symbol)")
                    .font(.outfit(22, weight: .bold))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: Int(displayValue))
            }
            
            // Slider with +/- buttons
            HStack(spacing: 12) {
                Button(action: {
                    if weightKg > 30 {
                        weightKg -= 1
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.orange)
                }
                
                Slider(
                    value: unit == .lbs ? 
                        Binding(
                            get: { weightKg * 2.20462 },
                            set: { weightKg = $0 / 2.20462 }
                        ) : $weightKg,
                    in: range,
                    step: 1
                )
                .tint(.orange)
                
                Button(action: {
                    if weightKg < 200 {
                        weightKg += 1
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Frequency Picker

struct FrequencyPicker: View {
    @Binding var daysPerWeek: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Label row
            HStack {
                Text("Training")
                    .font(.outfit(18, weight: .semiBold))
                Spacer()
                Text("\(daysPerWeek) days/week")
                    .font(.outfit(22, weight: .bold))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: daysPerWeek)
            }
            
            // Slider with +/- buttons
            HStack(spacing: 12) {
                Button(action: {
                    if daysPerWeek > 1 {
                        daysPerWeek -= 1
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.orange)
                }
                
                Slider(
                    value: Binding(
                        get: { Double(daysPerWeek) },
                        set: { daysPerWeek = Int($0) }
                    ),
                    in: 1...7,
                    step: 1
                )
                .tint(.orange)
                
                Button(action: {
                    if daysPerWeek < 7 {
                        daysPerWeek += 1
                        HapticService.shared.light()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Step 5: Plan Ready

struct PlanReadyStepView: View {
    let daysPerWeek: Int
    let onComplete: (Bool) -> Void
    
    @State private var hasAppeared = false
    @State private var showStars = false
    
    var suggestions: [DaySuggestion] {
        WorkoutTemplates.suggestedSchedule(forDaysPerWeek: daysPerWeek)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon with star burst animation
            ZStack {
                // Star particles
                ForEach(0..<8) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .offset(
                            x: showStars ? cos(Double(index) * .pi / 4) * 60 : 0,
                            y: showStars ? sin(Double(index) * .pi / 4) * 60 : 0
                        )
                        .opacity(showStars ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.0)
                            .delay(0.3 + Double(index) * 0.05),
                            value: showStars
                        )
                }
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(hasAppeared ? 1.0 : 0.3)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: hasAppeared)
            }
            .padding(.bottom, 24)
            
            // Title
            Text("You're all set! 🎉")
                .font(.outfit(34, weight: .bold))
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                .padding(.bottom, 8)
            
            Text("Here's your suggested plan")
                .font(.outfit(14, weight: .medium))
                .foregroundColor(.secondary)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                .padding(.bottom, 24)
            
            // Schedule preview with staggered animation
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.dayOfWeek) { index, suggestion in
                        ScheduleRow(suggestion: suggestion)
                            .opacity(hasAppeared ? 1.0 : 0)
                            .offset(x: hasAppeared ? 0 : 50)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.2 + Double(index) * 0.1),
                                value: hasAppeared
                            )
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 280)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                OnboardingButton(title: "Use This Plan", action: { onComplete(true) })
                    .opacity(hasAppeared ? 1.0 : 0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: hasAppeared)
                
                Button(action: { onComplete(false) }) {
                    Text("I'll set it up myself")
                        .font(.outfit(18, weight: .semiBold))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 12)
                }
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.6), value: hasAppeared)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            hasAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showStars = true
            }
        }
    }
}

struct ScheduleRow: View {
    let suggestion: DaySuggestion
    
    var body: some View {
        HStack(spacing: 12) {
            Text(suggestion.dayName)
                .font(.outfit(14, weight: .semiBold))
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.template.name)
                    .font(.outfit(14, weight: .semiBold))
                Text("\(suggestion.template.exercises.count) exercises")
                    .font(.outfit(12, weight: .regular))
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
                    .font(.outfit(18, weight: .semiBold))
                Spacer()
                Text("\(displayValue) \(unit)")
                    .font(.outfit(22, weight: .bold))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: displayValue)
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
                        .font(.system(size: 34))
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
                        .font(.system(size: 34))
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
                    .font(.outfit(18, weight: .semiBold))
                Spacer()
                Text("\(feet)' \(inches)\"")
                    .font(.outfit(22, weight: .bold))
                    .foregroundColor(.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: Int(totalInches))
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
                        .font(.system(size: 34))
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
                        .font(.system(size: 34))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Onboarding Button

struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.outfit(18, weight: .bold))
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
