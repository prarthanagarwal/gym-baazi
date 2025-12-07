import SwiftUI

/// Second step of onboarding - collect body metrics
struct BodyMetricsView: View {
    @Binding var age: Int
    @Binding var heightCm: Double
    @Binding var weightKg: Double
    var onNext: () -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.pull)
                
                Text("Tell us about yourself")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                Text("This helps us track your progress better")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Metrics inputs
            VStack(spacing: 20) {
                // Age
                MetricCard(title: "Age", value: "\(age) years") {
                    Stepper("", value: $age, in: 13...100)
                        .labelsHidden()
                        .onChange(of: age) { _, _ in
                            HapticService.shared.light()
                        }
                }
                
                // Height
                MetricCard(title: "Height", value: "\(Int(heightCm)) cm") {
                    Slider(value: $heightCm, in: 100...250, step: 1)
                        .tint(.cyan)
                        .onChange(of: heightCm) { _, _ in
                            HapticService.shared.selection()
                        }
                }
                
                // Weight
                MetricCard(title: "Weight", value: String(format: "%.1f kg", weightKg)) {
                    Slider(value: $weightKg, in: 30...200, step: 0.5)
                        .tint(.purple)
                        .onChange(of: weightKg) { _, _ in
                            HapticService.shared.selection()
                        }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                }
                
                Button(action: onNext) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.push)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Metric Card Component

struct MetricCard<Control: View>: View {
    let title: String
    let value: String
    @ViewBuilder let control: () -> Control
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.title3.bold())
            }
            
            control()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    BodyMetricsView(
        age: .constant(25),
        heightCm: .constant(170),
        weightKg: .constant(70),
        onNext: {},
        onBack: {}
    )
}
