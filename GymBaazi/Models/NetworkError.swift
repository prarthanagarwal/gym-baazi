import Foundation

/// Unified network error types with user-friendly messages
enum NetworkError: Error, Equatable {
    case noInternet
    case timeout
    case serverError(statusCode: Int)
    case decodingError
    case rateLimited
    case invalidURL
    case unknown(String)
    
    // MARK: - User-Facing Messages
    
    var title: String {
        switch self {
        case .noInternet:
            return "No Connection"
        case .timeout:
            return "Request Timed Out"
        case .serverError:
            return "Server Error"
        case .decodingError:
            return "Data Error"
        case .rateLimited:
            return "Too Many Requests"
        case .invalidURL:
            return "Invalid Request"
        case .unknown:
            return "Something Went Wrong"
        }
    }
    
    var message: String {
        switch self {
        case .noInternet:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .serverError(let code):
            return "The server returned an error (\(code)). Please try again later."
        case .decodingError:
            return "We couldn't process the data. Please try again."
        case .rateLimited:
            return "You've made too many requests. Please wait a moment."
        case .invalidURL:
            return "The request couldn't be completed."
        case .unknown(let msg):
            return msg.isEmpty ? "An unexpected error occurred." : msg
        }
    }
    
    var icon: String {
        switch self {
        case .noInternet:
            return "wifi.exclamationmark"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .serverError:
            return "exclamationmark.icloud"
        case .decodingError:
            return "doc.questionmark"
        case .rateLimited:
            return "hourglass"
        case .invalidURL:
            return "link.badge.plus"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
    
    /// Whether the error is likely transient and can be retried
    var isRetryable: Bool {
        switch self {
        case .noInternet, .timeout, .serverError, .rateLimited:
            return true
        case .decodingError, .invalidURL, .unknown:
            return false
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noInternet, .noInternet),
             (.timeout, .timeout),
             (.decodingError, .decodingError),
             (.rateLimited, .rateLimited),
             (.invalidURL, .invalidURL):
            return true
        case (.serverError(let a), .serverError(let b)):
            return a == b
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
    
    // MARK: - Factory Methods
    
    /// Creates a NetworkError from a URLError
    static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternet
        case .timedOut:
            return .timeout
        default:
            return .unknown(urlError.localizedDescription)
        }
    }
    
    /// Creates a NetworkError from any Error
    static func from(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            return from(urlError)
        }
        if error is DecodingError {
            return .decodingError
        }
        return .unknown(error.localizedDescription)
    }
}
