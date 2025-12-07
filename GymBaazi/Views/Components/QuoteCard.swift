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
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    QuoteCard(quote: QuoteService.getDailyQuote())
        .padding()
        .background(Color(.systemGroupedBackground))
}
