import SwiftUI

/// Quote card for displaying motivational quotes
struct QuoteCard: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(.orange)
                    .font(.title2)
                Spacer()
            }
            
            Text(quote.text)
                .font(.body)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
            
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    QuoteCard(quote: QuoteService.getDailyQuote())
        .padding()
        .background(Color(.systemGroupedBackground))
}
