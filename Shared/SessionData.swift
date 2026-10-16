import Foundation

struct SessionData: Codable, Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let distance: Double
    let avgStrokeRate: Double
    let maxStrokeRate: Double
    let avgSpeed: Double
    let maxSpeed: Double
    let avgHeartRate: Double
    let maxHeartRate: Double
    let calories: Double
    let strokeCount: Int
    let splits: [SplitData]

    var avgSplit500m: TimeInterval {
        guard avgSpeed > 0.1 else { return 0 }
        return 500.0 / avgSpeed
    }
}

struct SplitData: Codable, Identifiable {
    let id: UUID
    let index: Int
    let time: TimeInterval
    let strokeRate: Double
    let heartRate: Double
    let speed: Double

    init(index: Int, time: TimeInterval, strokeRate: Double, heartRate: Double, speed: Double) {
        self.id = UUID()
        self.index = index
        self.time = time
        self.strokeRate = strokeRate
        self.heartRate = heartRate
        self.speed = speed
    }
}

struct LiveMetrics: Codable {
    var strokeRate: Double = 0
    var speed: Double = 0
    var distance: Double = 0
    var heartRate: Double = 0
    var elapsedTime: TimeInterval = 0
    var calories: Double = 0
    var splitTime: TimeInterval = 0
    var strokeCount: Int = 0
    var isActive: Bool = false
}

enum WatchMessage: String {
    case startSession = "start"
    case pauseSession = "pause"
    case resumeSession = "resume"
    case stopSession = "stop"
    case metricsUpdate = "metrics"
    case sessionComplete = "complete"
}
