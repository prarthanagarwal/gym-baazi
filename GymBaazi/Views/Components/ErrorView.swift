import SwiftUI

/// Reusable error view component with retry support
struct ErrorView: View {
    let error: NetworkError
    let onRetry: (() async -> Void)?
    
    @State private var isRetrying = false
    
    init(error: NetworkError, onRetry: (() async -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            Image(systemName: error.icon)
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.secondary, .secondary.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .symbolRenderingMode(.hierarchical)
            
            // Title & Message
            VStack(spacing: 8) {
                Text(error.title)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                
                Text(error.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Retry Button
            if error.isRetryable, let onRetry = onRetry {
                Button(action: {
                    performRetry(onRetry)
                }) {
                    HStack(spacing: 8) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRetrying ? "Retrying..." : "Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .disabled(isRetrying)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func performRetry(_ action: @escaping () async -> Void) {
        isRetrying = true
        HapticService.shared.light()
        
        Task {
            await action()
            await MainActor.run {
                isRetrying = false
            }
        }
    }
}

// MARK: - Compact Error View (for inline use)

/// Smaller error view for inline use in lists or cards
struct CompactErrorView: View {
    let message: String
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundColor(.orange)
            
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
                    .font(.footnote.bold())
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Error Banner (for overlay use)

/// Error banner for temporary error notifications
struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Full Error View") {
    ErrorView(error: .noInternet) {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

#Preview("Compact Error") {
    CompactErrorView(message: "Failed to load exercises", onRetry: {})
        .padding()
}
