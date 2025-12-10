import SwiftUI
import AudioToolbox

/// Rest timer popup overlay shown after completing a set
struct RestTimerView: View {
    let duration: Int // in seconds
    let setNumber: Int
    let exerciseName: String
    let nextInfo: String // "Lat Pulldown" or "Set 2"
    @Binding var isPresented: Bool
    
    @State private var remainingTime: Int
    @State private var isPaused = false
    @State private var timer: Timer?
    
    @Environment(\.colorScheme) var colorScheme
    
    init(duration: Int, setNumber: Int = 1, exerciseName: String = "", nextInfo: String = "", isPresented: Binding<Bool>) {
        self.duration = duration
        self.setNumber = setNumber
        self.exerciseName = exerciseName
        self.nextInfo = nextInfo
        self._isPresented = isPresented
        self._remainingTime = State(initialValue: duration)
    }
    
    // Legacy init for backwards compatibility
    init(duration: Int, isPresented: Binding<Bool>) {
        self.duration = duration
        self.setNumber = 1
        self.exerciseName = ""
        self.nextInfo = ""
        self._isPresented = isPresented
        self._remainingTime = State(initialValue: duration)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(duration - remainingTime) / Double(duration)
    }
    
    var formattedTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REST TIMER")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Text("Set \(setNumber) Complete")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Close button
                Button(action: { dismissTimer() }) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
            
            // Circular Progress Timer
            ZStack {
                // Background circle
                Circle()
                    .stroke(
                        Color(.systemGray4),
                        lineWidth: 8
                    )
                    .frame(width: 180, height: 180)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // Time display
                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text("remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Next exercise/set info
            if !nextInfo.isEmpty {
                HStack(spacing: 4) {
                    Text("Next:")
                        .foregroundColor(.secondary)
                    Text(nextInfo)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            
            // Control buttons
            HStack(spacing: 24) {
                // Reset button
                Button(action: { resetTimer() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                        .frame(width: 56, height: 56)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                
                // Pause/Resume button
                Button(action: { togglePause() }) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(Color.orange)
                        .clipShape(Circle())
                }
                
                // Skip button
                Button(action: { dismissTimer() }) {
                    Image(systemName: "xmark")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                        .frame(width: 56, height: 56)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .padding(32)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Control
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !isPaused else { return }
            
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                // Timer complete - play sound and auto-dismiss
                playCompletionSound()
                HapticService.shared.success()
                dismissTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        remainingTime = duration
        isPaused = false
        HapticService.shared.light()
    }
    
    private func togglePause() {
        isPaused.toggle()
        HapticService.shared.light()
    }
    
    private func dismissTimer() {
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
        stopTimer()
    }
    
    private func playCompletionSound() {
        // Play system sound (tri-tone notification)
        AudioServicesPlaySystemSound(1007)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
        
        RestTimerView(
            duration: 90,
            setNumber: 1,
            exerciseName: "Bench Press",
            nextInfo: "Lat Pulldown",
            isPresented: .constant(true)
        )
    }
}
