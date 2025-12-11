import Foundation

// MARK: - Duration Formatting

extension Int {
    /// Formats seconds as HH:MM:SS or MM:SS
    /// - Example: 3661 → "1:01:01", 125 → "02:05"
    var formattedDuration: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        let seconds = self % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formats seconds as human-readable duration
    /// - Example: 3661 → "1h 1m", 125 → "2 minutes"
    var formattedDurationHumanReadable: String {
        let hours = self / 3600
        let minutes = (self % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) minutes"
    }
}

// MARK: - Height Formatting

extension Double {
    /// Converts centimeters to feet and inches string
    /// - Example: 175.26 → "5' 9\""
    var cmToFeetInches: String {
        let totalInches = self / 2.54
        let feet = Int(totalInches) / 12
        let inches = Int(totalInches) % 12
        return "\(feet)' \(inches)\""
    }
    
    /// Converts centimeters to total inches
    var cmToInches: Double {
        self / 2.54
    }
}

extension Int {
    /// Converts total inches to centimeters
    var inchesToCm: Double {
        Double(self) * 2.54
    }
}

// MARK: - Weight Formatting

extension Double {
    /// Formats weight with appropriate precision
    /// - Example: 70.0 → "70", 70.5 → "70.5"
    var formattedWeight: String {
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        }
        return String(format: "%.1f", self)
    }
}

// MARK: - String Formatting

extension String {
    /// Returns the string trimmed of whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns first letter uppercased, suitable for avatar initials
    var initial: String {
        prefix(1).uppercased()
    }
}
