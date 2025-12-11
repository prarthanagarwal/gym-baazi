import SwiftUI

// MARK: - Validation Feedback Modifier

/// View modifier that shows validation error feedback below the field
struct ValidationFeedbackModifier: ViewModifier {
    let error: ValidationError?
    let showBorder: Bool
    
    init(error: ValidationError?, showBorder: Bool = true) {
        self.error = error
        self.showBorder = showBorder
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .overlay(
                    Group {
                        if showBorder, error != nil {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                        }
                    }
                )
            
            if let error = error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                    Text(error.message)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: error != nil)
    }
}

// MARK: - Soft Validation Modifier (Warning Style)

/// View modifier that shows soft validation warning (orange, non-blocking)
struct SoftValidationModifier: ViewModifier {
    let warning: String?
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
            
            if let warning = warning {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                    Text(warning)
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: warning != nil)
    }
}

// MARK: - View Extensions

extension View {
    /// Adds validation error feedback below the view
    /// - Parameters:
    ///   - error: The ValidationError to display, or nil if valid
    ///   - showBorder: Whether to show a red border on invalid fields
    func validationFeedback(_ error: ValidationError?, showBorder: Bool = true) -> some View {
        modifier(ValidationFeedbackModifier(error: error, showBorder: showBorder))
    }
    
    /// Adds soft validation warning below the view (non-blocking, orange)
    func softValidation(_ warning: String?) -> some View {
        modifier(SoftValidationModifier(warning: warning))
    }
    
    /// Adds validation error from ValidationResult for a specific field
    func validationFeedback(from result: ValidationResult, field: String, showBorder: Bool = true) -> some View {
        modifier(ValidationFeedbackModifier(error: result.error(for: field), showBorder: showBorder))
    }
}

// MARK: - Validated Text Field

/// A text field with built-in validation feedback
struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    let validate: (String) -> ValidationError?
    let onValidationChange: ((Bool) -> Void)?
    
    @State private var error: ValidationError?
    @State private var hasBeenEdited = false
    @FocusState private var isFocused: Bool
    
    init(
        _ title: String,
        text: Binding<String>,
        validate: @escaping (String) -> ValidationError?,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.title = title
        self._text = text
        self.validate = validate
        self.onValidationChange = onValidationChange
    }
    
    var body: some View {
        TextField(title, text: $text)
            .focused($isFocused)
            .onChange(of: text) { _, newValue in
                hasBeenEdited = true
                validateField(newValue)
            }
            .onChange(of: isFocused) { _, focused in
                if !focused && hasBeenEdited {
                    validateField(text)
                }
            }
            .validationFeedback(hasBeenEdited ? error : nil)
    }
    
    private func validateField(_ value: String) {
        error = validate(value)
        onValidationChange?(error == nil)
    }
}

// MARK: - Inline Error View

/// Displays a validation error inline
struct InlineValidationError: View {
    let error: ValidationError?
    
    var body: some View {
        if let error = error {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                Text(error.message)
                    .font(.caption)
            }
            .foregroundColor(.red)
            .padding(.horizontal, 4)
        }
    }
}
