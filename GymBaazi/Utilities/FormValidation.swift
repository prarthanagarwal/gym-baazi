import Foundation

// MARK: - Validation Error Types

/// Validation errors with user-friendly messages
enum ValidationError: Error, Equatable {
    case empty(field: String)
    case tooShort(field: String, minimum: Int)
    case tooLong(field: String, maximum: Int)
    case outOfRange(field: String, message: String)
    case invalidFormat(field: String, expected: String)
    case custom(message: String)
    
    var message: String {
        switch self {
        case .empty(let field):
            return "\(field) cannot be empty"
        case .tooShort(let field, let min):
            return "\(field) must be at least \(min) characters"
        case .tooLong(let field, let max):
            return "\(field) cannot exceed \(max) characters"
        case .outOfRange(_, let message):
            return message
        case .invalidFormat(let field, let expected):
            return "\(field) must be \(expected)"
        case .custom(let message):
            return message
        }
    }
    
    static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
        lhs.message == rhs.message
    }
}

// MARK: - Form Validator

/// Centralized validation logic for all forms
struct FormValidator {
    
    // MARK: - Name Validation
    
    /// Validates a user's name
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateName(_ name: String) -> ValidationError? {
        let trimmed = name.trimmed
        
        if trimmed.isEmpty {
            return .empty(field: "Name")
        }
        if trimmed.count < Constants.Validation.nameMinLength {
            return .tooShort(field: "Name", minimum: Constants.Validation.nameMinLength)
        }
        if trimmed.count > Constants.Validation.nameMaxLength {
            return .tooLong(field: "Name", maximum: Constants.Validation.nameMaxLength)
        }
        return nil
    }
    
    // MARK: - Age Validation
    
    /// Validates age is within acceptable range
    static func validateAge(_ age: Int) -> ValidationError? {
        let min = Constants.Validation.ageMin
        let max = Constants.Validation.ageMax
        
        if age < min || age > max {
            return .outOfRange(
                field: "Age",
                message: "Age must be between \(min) and \(max) years"
            )
        }
        return nil
    }
    
    // MARK: - Height Validation
    
    /// Validates height in centimeters
    static func validateHeight(cm: Double) -> ValidationError? {
        let minCm = Double(Constants.Validation.heightMinInches) * 2.54 // ~122 cm
        let maxCm = Double(Constants.Validation.heightMaxInches) * 2.54 // ~213 cm
        
        if cm < minCm || cm > maxCm {
            return .outOfRange(
                field: "Height",
                message: "Height must be between 4'0\" and 7'0\""
            )
        }
        return nil
    }
    
    /// Validates height in inches
    static func validateHeight(inches: Double) -> ValidationError? {
        let min = Double(Constants.Validation.heightMinInches)
        let max = Double(Constants.Validation.heightMaxInches)
        
        if inches < min || inches > max {
            return .outOfRange(
                field: "Height",
                message: "Height must be between 4'0\" and 7'0\""
            )
        }
        return nil
    }
    
    // MARK: - Weight Validation
    
    /// Validates weight in kilograms
    static func validateWeight(_ weight: Double) -> ValidationError? {
        let min = Constants.Validation.weightMinKg
        let max = Constants.Validation.weightMaxKg
        
        if weight < min || weight > max {
            return .outOfRange(
                field: "Weight",
                message: "Weight must be between \(Int(min)) and \(Int(max)) kg"
            )
        }
        return nil
    }
    
    // MARK: - Workout Day Name Validation
    
    /// Validates workout day name
    static func validateWorkoutDayName(_ name: String) -> ValidationError? {
        let trimmed = name.trimmed
        
        if trimmed.isEmpty {
            return .empty(field: "Workout name")
        }
        if trimmed.count < Constants.Validation.workoutNameMinLength {
            return .tooShort(field: "Workout name", minimum: Constants.Validation.workoutNameMinLength)
        }
        if trimmed.count > Constants.Validation.workoutNameMaxLength {
            return .tooLong(field: "Workout name", maximum: Constants.Validation.workoutNameMaxLength)
        }
        return nil
    }
    
    // MARK: - Exercise Configuration Validation
    
    /// Validates exercise sets count
    static func validateSets(_ sets: Int) -> ValidationError? {
        if sets < 1 || sets > 10 {
            return .outOfRange(field: "Sets", message: "Sets must be between 1 and 10")
        }
        return nil
    }
    
    /// Validates exercise reps count
    static func validateReps(_ reps: Int) -> ValidationError? {
        if reps < 1 || reps > 100 {
            return .outOfRange(field: "Reps", message: "Reps must be between 1 and 100")
        }
        return nil
    }
    
    /// Validates weight input
    static func validateExerciseWeight(_ weight: Double) -> ValidationError? {
        if weight < 0 || weight > 1000 {
            return .outOfRange(field: "Weight", message: "Weight must be between 0 and 1000 kg")
        }
        return nil
    }
}

// MARK: - Validation Result Helper

/// Aggregates multiple validation results
struct ValidationResult {
    private(set) var errors: [String: ValidationError] = [:]
    
    var isValid: Bool {
        errors.isEmpty
    }
    
    var firstError: ValidationError? {
        errors.values.first
    }
    
    mutating func add(_ error: ValidationError?, forField field: String) {
        if let error = error {
            errors[field] = error
        } else {
            errors.removeValue(forKey: field)
        }
    }
    
    func error(for field: String) -> ValidationError? {
        errors[field]
    }
}
