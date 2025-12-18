import SwiftUI

/// Muscle group badge component
struct MuscleBadge: View {
    let muscle: String
    let isPrimary: Bool
    
    var body: some View {
        Text(muscle)
            .font(.outfit(11, weight: .semiBold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPrimary ? Color.orange.opacity(0.15) : Color.gray.opacity(0.15))
            .foregroundColor(isPrimary ? .orange : .gray)
            .clipShape(Capsule())
    }
}

#Preview {
    HStack {
        MuscleBadge(muscle: "Chest", isPrimary: true)
        MuscleBadge(muscle: "Triceps", isPrimary: false)
    }
}
