import Foundation

/// Exercise definition with sets, reps, and rest time
struct Exercise: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var sets: Int
    var reps: String // e.g., "6-8", "8-10"
    var isCompound: Bool
    var restTime: String // e.g., "2-4 min"
    var restSeconds: Int
    var muscleWikiId: Int? // For API lookup
    
    init(id: String? = nil, name: String, sets: Int, reps: String, isCompound: Bool = false, restTime: String = "90 sec", restSeconds: Int = 90, muscleWikiId: Int? = nil) {
        self.id = id ?? "ex_\(UUID().uuidString.prefix(8))"
        self.name = name
        self.sets = sets
        self.reps = reps
        self.isCompound = isCompound
        self.restTime = restTime
        self.restSeconds = restSeconds
        self.muscleWikiId = muscleWikiId
    }
    
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}
