import Foundation
import CoreMotion

class StrokeDetector {
    var onStroke: ((Double) -> Void)?

    private let motionManager = CMMotionManager()
    private let sampleRate: Double = 50.0

    private var filteredX: Double = 0
    private var filteredY: Double = 0
    private var filteredZ: Double = 0
    private let alpha: Double = 0.15

    private enum Phase { case idle, drive, recovery }
    private var phase: Phase = .idle

    private var signalBuffer: [Double] = []
    private let bufferSize = 25

    private var recentPeaks: [Double] = []
    private var thresholdHigh: Double = 1.5
    private var thresholdLow: Double = 0.7

    private var strokeTimestamps: [TimeInterval] = []
    private var lastStrokeTime: TimeInterval = 0
    private let minInterval: TimeInterval = 0.8
    private let maxInterval: TimeInterval = 5.0
    private var startTime: TimeInterval = 0

    private(set) var strokeCount: Int = 0
    private(set) var currentRate: Double = 0

    func start() {
        reset()
        guard motionManager.isDeviceMotionAvailable else {
            startFallback()
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleRate
        motionManager.startDeviceMotionUpdates(to: OperationQueue()) { [weak self] motion, _ in
            guard let self = self, let m = motion else { return }
            let ua = m.userAcceleration
            self.filteredX = self.alpha * ua.x + (1 - self.alpha) * self.filteredX
            self.filteredY = self.alpha * ua.y + (1 - self.alpha) * self.filteredY
            self.filteredZ = self.alpha * ua.z + (1 - self.alpha) * self.filteredZ
            let mag = sqrt(self.filteredX * self.filteredX + self.filteredY * self.filteredY + self.filteredZ * self.filteredZ)
            let rot = m.rotationRate
            let rotMag = sqrt(rot.x * rot.x + rot.y * rot.y + rot.z * rot.z)
            self.process(mag + 0.3 * rotMag, at: ProcessInfo.processInfo.systemUptime - self.startTime)
        }
    }

    private func startFallback() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / sampleRate
        motionManager.startAccelerometerUpdates(to: OperationQueue()) { [weak self] data, _ in
            guard let self = self, let d = data else { return }
            self.filteredX = self.alpha * d.acceleration.x + (1 - self.alpha) * self.filteredX
            self.filteredY = self.alpha * d.acceleration.y + (1 - self.alpha) * self.filteredY
            self.filteredZ = self.alpha * d.acceleration.z + (1 - self.alpha) * self.filteredZ
            let mag = sqrt(self.filteredX * self.filteredX + self.filteredY * self.filteredY + self.filteredZ * self.filteredZ)
            self.process(abs(mag - 1.0), at: ProcessInfo.processInfo.systemUptime - self.startTime)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    func reset() {
        phase = .idle
        signalBuffer.removeAll()
        strokeTimestamps.removeAll()
        recentPeaks.removeAll()
        strokeCount = 0
        currentRate = 0
        lastStrokeTime = 0
        thresholdHigh = 1.5
        thresholdLow = 0.7
        filteredX = 0; filteredY = 0; filteredZ = 0
        startTime = ProcessInfo.processInfo.systemUptime
    }

    private func process(_ value: Double, at t: TimeInterval) {
        signalBuffer.append(value)
        if signalBuffer.count > bufferSize { signalBuffer.removeFirst() }
        guard signalBuffer.count >= 5 else { return }

        let smoothed = signalBuffer.suffix(5).reduce(0, +) / 5.0

        switch phase {
        case .idle:
            if smoothed > thresholdHigh { phase = .drive }
        case .drive:
            if smoothed < thresholdLow {
                phase = .recovery
                registerStroke(at: t, peak: signalBuffer.max() ?? smoothed)
            }
        case .recovery:
            if smoothed > thresholdHigh && (t - lastStrokeTime) >= minInterval {
                phase = .drive
            }
        }
    }

    private func registerStroke(at t: TimeInterval, peak: Double) {
        let interval = t - lastStrokeTime
        guard lastStrokeTime > 0, interval >= minInterval, interval <= maxInterval else {
            lastStrokeTime = t
            if strokeCount == 0 { strokeCount = 1 }
            return
        }
        lastStrokeTime = t
        strokeCount += 1
        strokeTimestamps.append(t)
        if strokeTimestamps.count > 20 { strokeTimestamps.removeFirst() }

        recentPeaks.append(peak)
        if recentPeaks.count > 10 { recentPeaks.removeFirst() }
        let avg = recentPeaks.reduce(0, +) / Double(recentPeaks.count)
        thresholdHigh = max(0.5, avg * 0.55)
        thresholdLow = max(0.2, avg * 0.25)

        guard strokeTimestamps.count >= 3 else { return }
        let w = min(strokeTimestamps.count, 8)
        let recent = Array(strokeTimestamps.suffix(w))
        let total = recent.last! - recent.first!
        guard total > 0 else { return }
        currentRate = min(max(Double(w - 1) / total * 60.0, 0), 50)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onStroke?(self.currentRate)
        }
    }
}
