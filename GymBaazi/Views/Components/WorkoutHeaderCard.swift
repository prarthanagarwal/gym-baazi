import SwiftUI

/// Compact header card for workout session showing title, timer, and progress
struct WorkoutHeaderCard: View {
    let title: String
    let elapsedTime: String
    let progress: Double
    
    var body: some View {
        HStack {
            // Workout info
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(elapsedTime)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            
            Spacer()
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
            }
            .frame(width: 60, height: 60)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        WorkoutHeaderCard(title: "Push Day", elapsedTime: "12:34", progress: 0.65)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
