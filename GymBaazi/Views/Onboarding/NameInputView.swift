import SwiftUI

/// First step of onboarding - collect user's name
struct NameInputView: View {
    @Binding var name: String
    var onNext: () -> Void
    
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.push)
                
                Text("What should we call you?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                
                Text("This helps us personalize your experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Name input
            VStack(spacing: 8) {
                TextField("Your name", text: $name)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .focused($isNameFocused)
                    .submitLabel(.continue)
                    .onSubmit {
                        if !name.isEmpty {
                            onNext()
                        }
                    }
                
                Text("or just tap Continue to use 'Champ'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Continue button
            Button(action: onNext) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.push)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

#Preview {
    NameInputView(name: .constant(""), onNext: {})
}
