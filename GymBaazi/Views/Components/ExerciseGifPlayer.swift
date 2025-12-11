import SwiftUI
import ImageIO

/// Efficient animated GIF player using native iOS image decoding
/// Much lighter than WKWebView approach - no WebKit process spawning
struct ExerciseGifPlayer: View {
    let gifUrl: String
    var height: CGFloat = 180
    
    var body: some View {
        GifImage(url: gifUrl)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(Color(.systemGray6))
    }
}

/// Native GIF image view using CGImageSource for frame extraction
struct GifImage: View {
    let url: String
    
    @State private var frames: [UIImage] = []
    @State private var currentFrame: Int = 0
    @State private var isLoading = true
    @State private var loadError = false
    
    // Animation timer
    @State private var timer: Timer?
    private let frameDuration: TimeInterval = 0.1 // ~10fps
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if loadError || frames.isEmpty {
                ZStack {
                    Color(.systemGray6)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(uiImage: frames[currentFrame])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .task {
            await loadGif()
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    // MARK: - GIF Loading
    
    private func loadGif() async {
        guard let url = URL(string: url) else {
            loadError = true
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let extractedFrames = extractFrames(from: data)
            
            await MainActor.run {
                if extractedFrames.isEmpty {
                    loadError = true
                } else {
                    frames = extractedFrames
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = true
                isLoading = false
            }
        }
    }
    
    /// Extracts all frames from GIF data using ImageIO
    private func extractFrames(from data: Data) -> [UIImage] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return []
        }
        
        let frameCount = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        
        return images
    }
    
    // MARK: - Animation Control
    
    private func startAnimation() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: frameDuration, repeats: true) { _ in
            guard !frames.isEmpty else { return }
            currentFrame = (currentFrame + 1) % frames.count
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Compact Thumbnail (static, for lists)

struct ExerciseGifThumbnail: View {
    let gifUrl: String
    var size: CGFloat = 50
    
    var body: some View {
        AsyncImage(url: URL(string: gifUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .failure, .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: size, height: size)
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.orange)
                }
            @unknown default:
                EmptyView()
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExerciseGifPlayer(gifUrl: "https://static.exercisedb.dev/media/Y4QlY8z.gif")
        
        ExerciseGifThumbnail(gifUrl: "https://static.exercisedb.dev/media/Y4QlY8z.gif")
    }
    .padding()
}
