import SwiftUI

// MARK: - Design Constants
private enum DesignConstants {
    static let innerRadius: CGFloat = 8
    static let cardPadding: CGFloat = 12
    static let outerRadius: CGFloat = innerRadius + cardPadding
}

/// History view with monthly calendar and workout logs
struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showMonthPicker = false
    @State private var showYearPicker = false
    @State private var showDeleteConfirmation = false
    @State private var logToDelete: WorkoutLog?
    
    private let calendar = Calendar.current
    
    var logsForSelectedDate: [WorkoutLog] {
        appState.workoutLogs.filter { log in
            calendar.isDate(log.date, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Month calendar
                    calendarSection
                    
                    // Selected date header
                    selectedDateHeader
                    
                    // Workout logs for selected date
                    if logsForSelectedDate.isEmpty {
                        emptyDayCard
                    } else {
                        ForEach(logsForSelectedDate) { log in
                            WorkoutLogCard(log: log) {
                                logToDelete = log
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .confirmationDialog("Delete Workout?", isPresented: $showDeleteConfirmation, presenting: logToDelete) { log in
                Button("Delete", role: .destructive) {
                    appState.deleteWorkoutLog(id: log.id)
                    HapticService.shared.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: { log in
                Text("Delete this workout from \(log.date.formatted(date: .abbreviated, time: .omitted))?")
            }
            .sheet(isPresented: $showMonthPicker) {
                MonthPickerSheet(currentMonth: $currentMonth)
            }
            .sheet(isPresented: $showYearPicker) {
                YearPickerSheet(currentMonth: $currentMonth)
            }
        }
    }
    
    // MARK: - Calendar Section
    
    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Month/Year navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Clickable month
                Button(action: { showMonthPicker = true }) {
                    Text(currentMonth.formatted(.dateTime.month(.wide)))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                // Clickable year
                Button(action: { showYearPicker = true }) {
                    Text(currentMonth.formatted(.dateTime.year()))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.body.bold())
                        .foregroundColor(.orange)
                        .frame(width: 36, height: 36)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Day headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .frame(height: 24)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasWorkout: hasWorkout(on: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                            HapticService.shared.light()
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(DesignConstants.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.outerRadius))
    }
    
    // MARK: - Selected Date Header
    
    private var selectedDateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(selectedDate.formatted(.dateTime.day().month(.wide)))
                    .font(.headline)
            }
            
            Spacer()
            
            if calendar.isDateInToday(selectedDate) {
                Text("Today")
                    .font(.caption.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var emptyDayCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            
            Text("No workout logged")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Rest day or no activity recorded")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.outerRadius))
    }
    
    // MARK: - Calendar Helpers
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentMonth = newMonth
            }
            HapticService.shared.light()
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func hasWorkout(on date: Date) -> Bool {
        appState.workoutLogs.contains { log in
            calendar.isDate(log.date, inSameDayAs: date) && log.completed
        }
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasWorkout: Bool
    
    var body: some View {
        Text("\(Calendar.current.component(.day, from: date))")
            .font(.subheadline)
            .fontWeight(isToday || isSelected ? .bold : .regular)
            .foregroundColor(foregroundColor)
            .frame(width: 40, height: 40)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .orange
        } else if hasWorkout {
            return .green.opacity(0.15)
        } else if isToday {
            return .orange.opacity(0.1)
        }
        return .clear
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if hasWorkout {
            return .green
        } else if isToday {
            return .orange
        }
        return .primary
    }
}

// MARK: - Workout Log Card

struct WorkoutLogCard: View {
    let log: WorkoutLog
    let onDelete: () -> Void
    @State private var isExpanded = false
    
    private var dayInitials: String {
        String((log.dayName ?? log.type.displayName).prefix(2)).uppercased()
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: log.date)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: log.date)
    }
    
    private var completionPercentage: Int {
        guard !log.sets.isEmpty else { return 0 }
        let completed = log.sets.filter { $0.completed }.count
        return Int((Double(completed) / Double(log.sets.count)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
                HapticService.shared.light()
            }) {
                HStack(spacing: 12) {
                    // Day badge
                    Text(dayInitials)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.orange)
                        .clipShape(Circle())
                    
                    // Day name and date
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayName)
                            .font(.headline)
                        Text(dateString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quick actions
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(DesignConstants.cardPadding)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(spacing: 16) {
                    // Stats row
                    HStack(spacing: 0) {
                        StatBox(value: "\(log.completedSetsCount)/\(log.sets.count)", label: "SETS DONE")
                        StatBox(value: "\(Int(log.totalVolume))", label: "TOTAL KG")
                        StatBox(value: "\(completionPercentage)%", label: "COMPLETE")
                    }
                    
                    // Exercises section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EXERCISES")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        let groupedSets = Dictionary(grouping: log.sets) { $0.exerciseName }
                        
                        ForEach(Array(groupedSets.keys.sorted()), id: \.self) { exerciseName in
                            if let sets = groupedSets[exerciseName] {
                                ExerciseLogRow(exerciseName: exerciseName, sets: sets)
                            }
                        }
                    }
                }
                .padding(DesignConstants.cardPadding)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.outerRadius))
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
    }
}

// MARK: - Exercise Log Row

struct ExerciseLogRow: View {
    let exerciseName: String
    let sets: [ExerciseSet]
    
    var completedSets: [ExerciseSet] {
        sets.filter { $0.completed }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise header
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text(exerciseName)
                    .font(.subheadline.bold())
                
                Spacer()
                
                Text("\(completedSets.count)/\(sets.count) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Set pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sets, id: \.id) { set in
                        SetPill(set: set)
                    }
                }
            }
        }
        .padding(DesignConstants.cardPadding)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.innerRadius))
    }
}

// MARK: - Set Pill

struct SetPill: View {
    let set: ExerciseSet
    
    var body: some View {
        Text(pillText)
            .font(.caption)
            .foregroundColor(set.completed ? .primary : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(set.completed ? Color.orange.opacity(0.15) : Color(.systemGray5))
            .clipShape(Capsule())
    }
    
    private var pillText: String {
        if set.weight > 0 || set.reps > 0 {
            return "\(Int(set.weight))kg × \(set.reps)"
        }
        return "0kg × 0"
    }
}


// MARK: - Month Picker Sheet

struct MonthPickerSheet: View {
    @Binding var currentMonth: Date
    @Environment(\.dismiss) var dismiss
    
    let months = Calendar.current.monthSymbols
    
    var selectedMonthIndex: Int {
        Calendar.current.component(.month, from: currentMonth) - 1
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<12, id: \.self) { index in
                    Button(action: {
                        selectMonth(index)
                    }) {
                        HStack {
                            Text(months[index])
                                .foregroundColor(.primary)
                            Spacer()
                            if index == selectedMonthIndex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func selectMonth(_ index: Int) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentMonth)
        components.month = index + 1
        if let newDate = Calendar.current.date(from: components) {
            currentMonth = newDate
        }
        dismiss()
    }
}

// MARK: - Year Picker Sheet

struct YearPickerSheet: View {
    @Binding var currentMonth: Date
    @Environment(\.dismiss) var dismiss
    
    var currentYear: Int {
        Calendar.current.component(.year, from: currentMonth)
    }
    
    var years: [Int] {
        let thisYear = Calendar.current.component(.year, from: Date())
        return Array((thisYear - 10)...(thisYear + 1))
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(years.reversed(), id: \.self) { year in
                    Button(action: {
                        selectYear(year)
                    }) {
                        HStack {
                            Text(String(year))
                                .foregroundColor(.primary)
                            Spacer()
                            if year == currentYear {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Year")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func selectYear(_ year: Int) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: currentMonth)
        components.year = year
        if let newDate = Calendar.current.date(from: components) {
            currentMonth = newDate
        }
        dismiss()
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
