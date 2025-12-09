import SwiftUI

/// Glassmorphism card container with blur background
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    /// Border color adapts to color scheme for better visibility
    private var borderColor: Color {
        colorScheme == .dark 
            ? Color.white.opacity(0.35) 
            : Color.black.opacity(0.1)
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(borderColor, lineWidth: colorScheme == .dark ? 1.5 : 1)
            )
    }
}

#Preview {
    ZStack {
        LinearGradient.push
            .ignoresSafeArea()
        
        GlassCard {
            VStack {
                Text("Glass Card")
                    .font(.headline)
                Text("With blur effect")
                    .font(.caption)
            }
            .padding(32)
        }
        .padding()
    }
}
