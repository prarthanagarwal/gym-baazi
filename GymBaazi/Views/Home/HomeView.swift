import SwiftUI

/// Home view - Overview and motivation (not action-focused)
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting with streak
                    greetingSection
                    
                    // Today's workout preview with quote
                    todayPreviewCard
                    
                    // Weekly overview
                    weekOverviewCard
                    
                    // Personal Records
                    personalRecordsCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.outfit(28, weight: .semiBold))
                            .foregroundStyle(LinearGradient.push)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                NavigationStack {
                    ProfileView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Done") {
                                    showingProfile = false
                                }
                            }
                        }
                }
                .preferredColorScheme(appState.preferredColorScheme)
            }
        }
    }
    
    // MARK: - Greeting Section with Streak
    
    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.outfit(20, weight: .semiBold))
                    .foregroundColor(.primary)
                
                Text(appState.userProfile?.name ?? "Champ")
                    .font(.outfit(34, weight: .bold))
                    .foregroundStyle(LinearGradient.push)
            }
            
            Spacer()
            
            // Streak badge beside greeting
            if appState.currentStreak > 0 {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.outfit(22, weight: .regular))
                    Text("\(appState.currentStreak)")
                        .font(.outfit(18, weight: .bold))
                        .foregroundColor(.white)
                    Text("day streak")
                        .font(.outfit(14, weight: .semiBold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.red.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.orange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - Today Preview Card with Quote
    
    private var todayPreviewCard: some View {
        Group {
            if let todayWorkout = appState.workoutSchedule.todayWorkout {
                VStack(alignment: .leading, spacing: 16) {
                    // Today's workout header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TODAY (\(Date().formatted(.dateTime.month(.abbreviated).day())))")
                                .font(.outfit(12, weight: .semiBold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(todayWorkout.name)
                                .font(.outfit(22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.outfit(32, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("Go to Workout tab to start →")
                        .font(.outfit(12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Quote inside main card
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    quoteSection
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient.push)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                // Rest day or no workout scheduled
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.outfit(36, weight: .bold))
                            .foregroundColor(.purple)
                        
                        Text("Rest Day")
                            .font(.outfit(18, weight: .semiBold))
                        
                        Text("No workout scheduled for today")
                            .font(.outfit(12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    // Quote for rest day too
                    Divider()
                    
                    quoteSection
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }
    
    // Quote section (embedded in main card)
    private var quoteSection: some View {
        let quote = QuoteService.getRandomQuote()
        
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.outfit(12, weight: .regular))
                .foregroundColor(appState.workoutSchedule.todayWorkout != nil ? .white.opacity(0.6) : .orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(quote.text)
                    .font(.outfit(12, weight: .regular))
                    .foregroundColor(appState.workoutSchedule.todayWorkout != nil ? .white.opacity(0.9) : .primary)
                    .italic()
                
                Text("— \(quote.author)")
                    .font(.outfit(11, weight: .regular))
                    .foregroundColor(appState.workoutSchedule.todayWorkout != nil ? .white.opacity(0.6) : .secondary)
            }
        }
    }
    
    // MARK: - Week Overview Card
    
    private var weekOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.outfit(18, weight: .semiBold))
            
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { dayOfWeek in
                    let hasWorkout = appState.workoutSchedule.hasWorkout(on: dayOfWeek)
                    let isToday = Calendar.current.component(.weekday, from: Date()) == dayOfWeek
                    let isCompleted = hasCompletedWorkout(on: dayOfWeek)
                    
                    VStack(spacing: 4) {
                        Text(dayAbbrev(dayOfWeek))
                            .font(.outfit(11, weight: .semiBold))
                            .foregroundColor(isToday ? .orange : .secondary)
                        
                        ZStack {
                            Circle()
                                .fill(circleColor(isToday: isToday, hasWorkout: hasWorkout, completed: isCompleted))
                                .frame(width: 32, height: 32)
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.outfit(12, weight: .bold))
                                    .foregroundColor(.white)
                            } else if hasWorkout {
                                Image(systemName: "dumbbell.fill")
                                    .font(.outfit(11, weight: .regular))
                                    .foregroundColor(isToday ? .white : .orange)
                            } else {
                                Text("R")
                                    .font(.outfit(12, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Personal Records Card
    
    private var personalRecordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Personal Records")
                    .font(.outfit(18, weight: .semiBold))
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
            }
            
            if personalRecords.isEmpty {
                Text("Complete workouts to set records!")
                    .font(.outfit(12, weight: .regular))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(personalRecords.prefix(3), id: \.exercise) { record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.exercise)
                                    .font(.outfit(14, weight: .semiBold))
                                Text(record.date)
                                    .font(.outfit(11, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(record.value)
                                .font(.outfit(18, weight: .semiBold))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Personal Record Helper
    
    struct PersonalRecord {
        let exercise: String
        let value: String
        let date: String
    }
    
    private var personalRecords: [PersonalRecord] {
        // Group all sets by exercise name and find max weight
        var maxWeights: [String: (weight: Double, date: Date)] = [:]
        
        for log in appState.workoutLogs where log.completed {
            for set in log.sets {
                let current = maxWeights[set.exerciseName]
                if current == nil || set.weight > current!.weight {
                    maxWeights[set.exerciseName] = (set.weight, log.date)
                }
            }
        }
        
        // Convert to PersonalRecord and sort by weight
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return maxWeights.map { name, data in
            PersonalRecord(
                exercise: name,
                value: "\(Int(data.weight)) kg",
                date: dateFormatter.string(from: data.date)
            )
        }
        .sorted { $0.value > $1.value }
    }
    
    // MARK: - Helpers
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<21: return "Good evening,"
        default: return "Hey there,"
        }
    }
    
    private func dayAbbrev(_ day: Int) -> String {
        ["", "S", "M", "T", "W", "T", "F", "S"][day]
    }
    
    private func circleColor(isToday: Bool, hasWorkout: Bool, completed: Bool) -> Color {
        if completed { return .green }
        if isToday && hasWorkout { return .orange }
        if hasWorkout { return .orange.opacity(0.2) }
        return Color(.systemGray5)
    }
    
    private func hasCompletedWorkout(on dayOfWeek: Int) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Sunday)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return false
        }
        
        // Calculate target date for this weekday in current week
        // dayOfWeek: 1=Sunday, 2=Monday, etc.
        let daysFromSunday = dayOfWeek - 1
        guard let targetDate = calendar.date(byAdding: .day, value: daysFromSunday, to: startOfWeek) else {
            return false
        }
        
        return appState.workoutLogs.contains { log in
            calendar.isDate(log.date, inSameDayAs: targetDate) && log.completed
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
