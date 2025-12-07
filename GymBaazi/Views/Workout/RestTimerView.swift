import SwiftUI

/// Countdown rest timer modal with circular progress
struct RestTimerView: View {
    let duration: Int
    @Binding var isPresented: Bool
    @State private var remainingTime: Int
    @State private var timer: Timer?
    
    init(duration: Int, isPresented: Binding<Bool>) {
        self.duration = duration
        self._isPresented = isPresented
        self._remainingTime = State(initialValue: duration)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Rest Time")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(remainingTime) / CGFloat(duration))
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remainingTime)
                
                // Timer text
                Text(formatTime(remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: 200, height: 200)
            
            // Control buttons
            HStack(spacing: 16) {
                Button(action: {
                    stopTimer()
                    isPresented = false
                    HapticService.shared.light()
                }) {
                    Text("Skip")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Button(action: {
                    remainingTime += 30
                    HapticService.shared.light()
                }) {
                    Text("+30s")
                        .font(.headline)
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(radius: 20)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                HapticService.shared.heavy()
                stopTimer()
                isPresented = false
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        RestTimerView(duration: 90, isPresented: .constant(true))
    }
}
