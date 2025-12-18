import SwiftUI

/// Animated launch screen with logo and gradient background
struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var showTagline = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.pushStart, Color.pushEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo icon
                Image("SplashLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(isAnimating ? 0 : -15))
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0)
                
                // App name
                Text("Gym-Baazi")
                    .font(.outfit(42, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0)
                
                // Tagline
                Text("Your No Fuss Gym Buddy")
                    .font(.outfit(22, weight: .semiBold))
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(showTagline ? 1.0 : 0)
                    .offset(y: showTagline ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showTagline = true
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
