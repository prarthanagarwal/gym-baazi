import Foundation

/// User profile data collected during onboarding
struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var preferredUnit: WeightUnit
    var createdAt: Date = Date()
    
    init(name: String, age: Int, heightCm: Double, weightKg: Double, preferredUnit: WeightUnit = .kg) {
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.preferredUnit = preferredUnit
    }
}
