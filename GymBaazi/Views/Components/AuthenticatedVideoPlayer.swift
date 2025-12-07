import SwiftUI
import AVKit

/// Custom video player that can stream from MuscleWiki API with authentication
struct AuthenticatedVideoPlayer: View {
    let videoURL: URL
    @StateObject private var viewModel = AuthenticatedVideoViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ZStack {
                    Color.black
                    ProgressView()
                        .tint(.white)
                }
            } else if let player = viewModel.player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ZStack {
                    Color.black
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                        Text("Video unavailable")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .task {
            await viewModel.loadVideo(from: videoURL)
        }
    }
}

@MainActor
class AuthenticatedVideoViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadVideo(from url: URL) async {
        isLoading = true
        
        // Create URL with custom scheme for resource loader
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            isLoading = false
            return
        }
        
        // Keep the original URL for the request
        let originalURL = url
        
        // Change scheme to custom for resource loader interception
        components.scheme = "streaming"
        guard let streamingURL = components.url else {
            isLoading = false
            return
        }
        
        let asset = AVURLAsset(url: streamingURL)
        let resourceLoader = AuthenticatedResourceLoader(originalURL: originalURL)
        asset.resourceLoader.setDelegate(resourceLoader, queue: .main)
        
        // Store reference to prevent deallocation
        self.resourceLoaderReference = resourceLoader
        
        let playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
        
        isLoading = false
    }
    
    // Keep strong reference to prevent deallocation
    private var resourceLoaderReference: AuthenticatedResourceLoader?
}

// MARK: - Resource Loader with Authentication

class AuthenticatedResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    let originalURL: URL
    private var pendingRequests: [AVAssetResourceLoadingRequest] = []
    private var downloadTask: URLSessionDataTask?
    private var downloadedData = Data()
    private var response: URLResponse?
    
    init(originalURL: URL) {
        self.originalURL = originalURL
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        pendingRequests.append(loadingRequest)
        
        if downloadTask == nil {
            startDownload()
        } else {
            processPendingRequests()
        }
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        pendingRequests.removeAll { $0 === loadingRequest }
    }
    
    private func startDownload() {
        var request = URLRequest(url: originalURL)
        request.setValue(MuscleWikiService.shared.rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue(MuscleWikiService.shared.rapidAPIHost, forHTTPHeaderField: "X-RapidAPI-Host")
        
        let session = URLSession.shared
        downloadTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let data = data {
                    self.downloadedData.append(data)
                }
                self.response = response
                self.processPendingRequests()
                
                if error != nil || data != nil {
                    self.downloadTask = nil
                }
            }
        }
        downloadTask?.resume()
    }
    
    private func processPendingRequests() {
        var completedRequests: [AVAssetResourceLoadingRequest] = []
        
        for request in pendingRequests {
            if fillInContentInformation(request: request) {
                if let dataRequest = request.dataRequest,
                   respondWithData(for: dataRequest) {
                    completedRequests.append(request)
                    request.finishLoading()
                }
            }
        }
        
        pendingRequests.removeAll { completedRequests.contains($0) }
    }
    
    private func fillInContentInformation(request: AVAssetResourceLoadingRequest) -> Bool {
        guard let response = response as? HTTPURLResponse,
              let contentInfo = request.contentInformationRequest else {
            return true
        }
        
        contentInfo.isByteRangeAccessSupported = true
        contentInfo.contentType = response.mimeType
        
        if let contentLength = response.value(forHTTPHeaderField: "Content-Length"),
           let length = Int64(contentLength) {
            contentInfo.contentLength = length
        }
        
        return true
    }
    
    private func respondWithData(for dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let requestedOffset = Int(dataRequest.requestedOffset)
        let requestedLength = dataRequest.requestedLength
        
        if requestedOffset >= downloadedData.count {
            return false
        }
        
        let availableLength = min(requestedLength, downloadedData.count - requestedOffset)
        let range = requestedOffset..<(requestedOffset + availableLength)
        let data = downloadedData.subdata(in: range)
        
        dataRequest.respond(with: data)
        
        let endOffset = requestedOffset + requestedLength
        return downloadedData.count >= endOffset
    }
}
