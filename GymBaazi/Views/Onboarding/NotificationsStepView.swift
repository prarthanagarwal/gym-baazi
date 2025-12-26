import SwiftUI
import UserNotifications

/// Step 5: Notifications permission screen
struct NotificationsStepView: View {
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @State private var hasAppeared = false
    @State private var showNotification1 = false
    @State private var showNotification2 = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon with pulse animation
            ZStack {
                // Pulse rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                        .frame(width: 100 + CGFloat(index * 30), height: 100 + CGFloat(index * 30))
                        .scaleEffect(hasAppeared ? 1.2 : 0.8)
                        .opacity(hasAppeared ? 0 : 0.5)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: hasAppeared
                        )
                }
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: hasAppeared)
            }
            .padding(.bottom, 24)
            
            // Title
            Text("Smart Reminders")
                .font(.outfit(34, weight: .bold))
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
                .padding(.bottom, 8)
            
            Text("Friendly nudges when you forget to track")
                .font(.outfit(14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // Sample notifications
            VStack(spacing: 12) {
                NotificationPreviewCard(
                    title: "GymBaazi",
                    message: "Time to hit the gym! 💪",
                    time: "2:30 PM"
                )
                .opacity(showNotification1 ? 1.0 : 0)
                .offset(x: showNotification1 ? 0 : 50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNotification1)
                
                NotificationPreviewCard(
                    title: "GymBaazi",
                    message: "Great workout today! 🔥",
                    time: "6:45 PM"
                )
                .opacity(showNotification2 ? 1.0 : 0)
                .offset(x: showNotification2 ? 0 : 50)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNotification2)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                OnboardingButton(title: "🔔  Enable Notifications", action: {
                    requestNotificationPermission()
                })
                .opacity(hasAppeared ? 1.0 : 0)
                .offset(y: hasAppeared ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: hasAppeared)
                
                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.outfit(16, weight: .semiBold))
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
            // Stagger notification appearances
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showNotification1 = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showNotification2 = true
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                HapticService.shared.success()
                onNext()
            }
        }
    }
}

// MARK: - Notification Preview Card

struct NotificationPreviewCard: View {
    let title: String
    let message: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay(
                    Text("🐻")
                        .font(.system(size: 20))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.outfit(14, weight: .bold))
                    Spacer()
                    Text(time)
                        .font(.outfit(12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Text(message)
                    .font(.outfit(14, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    NotificationsStepView(onNext: {}, onSkip: {})
}
