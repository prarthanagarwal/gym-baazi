import SwiftUI

/// Glassmorphism card container with blur background
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
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
