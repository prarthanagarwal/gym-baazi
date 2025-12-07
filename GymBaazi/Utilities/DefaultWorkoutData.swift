import Foundation

/// Default workout routines for Push/Pull/Legs
struct DefaultWorkoutData {
    
    static let routines: [WorkoutType: WorkoutRoutine] = [
        .push: pushRoutine,
        .pull: pullRoutine,
        .legs: legsRoutine,
        .rest: restRoutine
    ]
    
    // MARK: - Push Day
    
    static let pushRoutine = WorkoutRoutine(
        type: .push,
        title: "Push Day",
        subtitle: "Chest, Shoulders & Triceps",
        exercises: [
            Exercise(id: "push_1", name: "Bench Press", sets: 4, reps: "6-8", isCompound: true, restTime: "3 min", restSeconds: 180),
            Exercise(id: "push_2", name: "Overhead Press", sets: 4, reps: "6-8", isCompound: true, restTime: "3 min", restSeconds: 180),
            Exercise(id: "push_3", name: "Incline Dumbbell Press", sets: 3, reps: "8-10", isCompound: true, restTime: "2 min", restSeconds: 120),
            Exercise(id: "push_4", name: "Lateral Raises", sets: 3, reps: "12-15", isCompound: false, restTime: "90 sec", restSeconds: 90),
            Exercise(id: "push_5", name: "Tricep Pushdown", sets: 3, reps: "10-12", isCompound: false, restTime: "90 sec", restSeconds: 90),
            Exercise(id: "push_6", name: "Overhead Tricep Extension", sets: 3, reps: "10-12", isCompound: false, restTime: "90 sec", restSeconds: 90)
        ],
        warmup: ["5 min cardio", "Arm circles", "Light shoulder rotations"],
        cooldown: ["Chest stretch", "Tricep stretch", "Shoulder stretch"]
    )
    
    // MARK: - Pull Day
    
    static let pullRoutine = WorkoutRoutine(
        type: .pull,
        title: "Pull Day",
        subtitle: "Back & Biceps",
        exercises: [
            Exercise(id: "pull_1", name: "Deadlift", sets: 4, reps: "5-6", isCompound: true, restTime: "4 min", restSeconds: 240),
            Exercise(id: "pull_2", name: "Barbell Row", sets: 4, reps: "6-8", isCompound: true, restTime: "3 min", restSeconds: 180),
            Exercise(id: "pull_3", name: "Lat Pulldown", sets: 3, reps: "8-10", isCompound: true, restTime: "2 min", restSeconds: 120),
            Exercise(id: "pull_4", name: "Seated Cable Row", sets: 3, reps: "10-12", isCompound: true, restTime: "2 min", restSeconds: 120),
            Exercise(id: "pull_5", name: "Face Pulls", sets: 3, reps: "15-20", isCompound: false, restTime: "90 sec", restSeconds: 90),
            Exercise(id: "pull_6", name: "Barbell Curl", sets: 3, reps: "10-12", isCompound: false, restTime: "90 sec", restSeconds: 90),
            Exercise(id: "pull_7", name: "Hammer Curls", sets: 3, reps: "10-12", isCompound: false, restTime: "90 sec", restSeconds: 90)
        ],
        warmup: ["5 min cardio", "Cat-cow stretches", "Arm swings"],
        cooldown: ["Lat stretch", "Back stretch", "Bicep stretch"]
    )
    
    // MARK: - Legs Day
    
    static let legsRoutine = WorkoutRoutine(
        type: .legs,
        title: "Leg Day",
        subtitle: "Quads, Hamstrings & Glutes",
        exercises: [
            Exercise(id: "legs_1", name: "Squat", sets: 4, reps: "6-8", isCompound: true, restTime: "4 min", restSeconds: 240),
            Exercise(id: "legs_2", name: "Romanian Deadlift", sets: 4, reps: "8-10", isCompound: true, restTime: "3 min", restSeconds: 180),
            Exercise(id: "legs_3", name: "Leg Press", sets: 3, reps: "10-12", isCompound: true, restTime: "2 min", restSeconds: 120),
            Exercise(id: "legs_4", name: "Walking Lunges", sets: 3, reps: "12 each", isCompound: true, restTime: "2 min", restSeconds: 120),
            Exercise(id: "legs_5", name: "Leg Curl", sets: 3, reps: "10-12", isCompound: false, restTime: "90 sec", restSeconds: 90),
            Exercise(id: "legs_6", name: "Leg Extension", sets: 3, reps: "12-15", isCompound: false, restTime: "90 sec", restSeconds: 90),
            Exercise(id: "legs_7", name: "Standing Calf Raises", sets: 4, reps: "15-20", isCompound: false, restTime: "60 sec", restSeconds: 60)
        ],
        warmup: ["5 min cardio", "Bodyweight squats", "Leg swings"],
        cooldown: ["Quad stretch", "Hamstring stretch", "Calf stretch"]
    )
    
    // MARK: - Rest Day
    
    static let restRoutine = WorkoutRoutine(
        type: .rest,
        title: "Rest Day",
        subtitle: "Recovery & Stretching",
        exercises: [],
        warmup: [],
        cooldown: ["Light stretching", "Foam rolling", "Meditation"]
    )
}
