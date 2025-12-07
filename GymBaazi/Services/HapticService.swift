import UIKit

/// Haptic feedback service for tactile feedback on all interactions
class HapticService {
    static let shared = HapticService()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators for lower latency
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    /// Light impact - for subtle interactions
    func light() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        lightGenerator.impactOccurred()
    }
    
    /// Medium impact - for button taps
    func medium() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        mediumGenerator.impactOccurred()
    }
    
    /// Heavy impact - for significant actions
    func heavy() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        heavyGenerator.impactOccurred()
    }
    
    /// Selection feedback - for picker changes
    func selection() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Success notification - for completed actions
    func success() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Warning notification - for important alerts
    func warning() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// Error notification - for failures
    func error() {
        guard StorageService.shared.userSettings.hapticFeedback else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Prepare all generators - call before rapid interactions
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
