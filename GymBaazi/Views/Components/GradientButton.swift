import SwiftUI

/// Gradient button with workout type styling
struct GradientButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    
    init(title: String, icon: String? = nil, gradient: LinearGradient = .push, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticService.shared.medium()
            action()
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(gradient)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

/// Outline button style
struct OutlineButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String? = nil, color: Color = .orange, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticService.shared.light()
            action()
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .stroke(color, lineWidth: 2)
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientButton(title: "Start Workout", icon: "play.fill") {}
        GradientButton(title: "Pull Day", gradient: .pull) {}
        OutlineButton(title: "Cancel", icon: "xmark") {}
    }
    .padding()
}
