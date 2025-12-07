import Foundation

/// Motivational quote model
struct Quote: Identifiable {
    let id = UUID()
    let text: String
    let author: String
}

/// Service for daily motivational quotes
struct QuoteService {
    static let quotes: [Quote] = [
        Quote(text: "The only bad workout is the one that didn't happen.", author: "Unknown"),
        Quote(text: "Your body can stand almost anything. It's your mind you have to convince.", author: "Unknown"),
        Quote(text: "The pain you feel today will be the strength you feel tomorrow.", author: "Arnold Schwarzenegger"),
        Quote(text: "Don't count the days, make the days count.", author: "Muhammad Ali"),
        Quote(text: "Success is usually the culmination of controlling failure.", author: "Sylvester Stallone"),
        Quote(text: "The only way to define your limits is by going beyond them.", author: "Arthur C. Clarke"),
        Quote(text: "Strength does not come from the body. It comes from the will.", author: "Unknown"),
        Quote(text: "The difference between try and triumph is a little umph.", author: "Marvin Phillips"),
        Quote(text: "Push harder than yesterday if you want a different tomorrow.", author: "Unknown"),
        Quote(text: "Wake up with determination. Go to bed with satisfaction.", author: "Unknown"),
        Quote(text: "It never gets easier, you just get stronger.", author: "Unknown"),
        Quote(text: "Sweat is just fat crying.", author: "Unknown"),
        Quote(text: "The gym is my therapy.", author: "Unknown"),
        Quote(text: "Champions train, losers complain.", author: "Unknown"),
        Quote(text: "Your only limit is you.", author: "Unknown"),
        Quote(text: "The body achieves what the mind believes.", author: "Napoleon Hill"),
        Quote(text: "Train insane or remain the same.", author: "Unknown"),
        Quote(text: "No pain, no gain. Shut up and train.", author: "Unknown"),
        Quote(text: "Excuses don't burn calories.", author: "Unknown"),
        Quote(text: "Today's pain is tomorrow's power.", author: "Unknown")
    ]
    
    /// Get the quote of the day (rotates daily)
    static func getDailyQuote() -> Quote {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }
    
    /// Get a random quote
    static func getRandomQuote() -> Quote {
        quotes.randomElement() ?? quotes[0]
    }
}
