import Foundation
import CoreLocation
import HealthKit
import WatchKit

class RowingSession: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var strokeRate: Double = 0
    @Published var speed: Double = 0
    @Published var splitTime: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var heartRate: Double = 0
    @Published var calories: Double = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var strokeCount: Int = 0
    @Published var isActive = false
    @Published var isPaused = false
    @Published var currentSplitIndex: Int = 0

    private let strokeDetector = StrokeDetector()
    private let haptic = HapticManager()
    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()

    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var startTime: Date?
    private var pauseAccum: TimeInterval = 0
    private var pauseStart: Date?
    private var lastLocation: CLLocation?
    private var speedSamples: [Double] = []
    private var totalDist: Double = 0

    private var srSamples: [Double] = []
    private var hrSamples: [Double] = []
    private var spdHistory: [Double] = []
    private var maxSR: Double = 0
    private var maxSpd: Double = 0
    private var maxHR: Double = 0

    private var splits: [SplitData] = []
    private var lastSplitDist: Double = 0
    private var lastSplitTime: Date?
    private var splitSR: [Double] = []
    private var splitHR: [Double] = []

    var phoneConnector: PhoneConnector?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .otherNavigation

        strokeDetector.onStroke = { [weak self] rate in
            guard let self = self else { return }
            self.strokeRate = rate
            self.strokeCount = self.strokeDetector.strokeCount
            self.srSamples.append(rate)
            self.splitSR.append(rate)
            if rate > self.maxSR { self.maxSR = rate }
            self.haptic.checkZoneChange(strokeRate: rate)
        }
    }

    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
        let read: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let write: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        healthStore.requestAuthorization(toShare: write, read: read) { _, _ in }
    }

    func start() {
        isActive = true; isPaused = false
        startTime = Date(); pauseAccum = 0; totalDist = 0
        lastLocation = nil; speedSamples.removeAll()
        srSamples.removeAll(); hrSamples.removeAll(); spdHistory.removeAll()
        splits.removeAll(); lastSplitDist = 0; lastSplitTime = Date()
        splitSR.removeAll(); splitHR.removeAll()
        maxSR = 0; maxSpd = 0; maxHR = 0
        strokeRate = 0; speed = 0; splitTime = 0; distance = 0
        heartRate = 0; calories = 0; elapsedTime = 0; strokeCount = 0
        currentSplitIndex = 0

        strokeDetector.start()
        locationManager.startUpdatingLocation()
        startWorkout()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let s = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(s) - self.pauseAccum
        }
        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        isPaused = true; pauseStart = Date()
        strokeDetector.stop(); locationManager.stopUpdatingLocation()
        timer?.invalidate(); workoutSession?.pause()
        WKInterfaceDevice.current().play(.stop)
    }

    func resume() {
        isPaused = false
        if let ps = pauseStart { pauseAccum += Date().timeIntervalSince(ps) }
        pauseStart = nil
        strokeDetector.start(); locationManager.startUpdatingLocation()
        workoutSession?.resume()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let s = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(s) - self.pauseAccum
        }
        WKInterfaceDevice.current().play(.start)
    }

    func stop() -> SessionData {
        isActive = false; isPaused = false
        strokeDetector.stop(); locationManager.stopUpdatingLocation(); timer?.invalidate()
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { _, _ in
            self.workoutBuilder?.finishWorkout { _, _ in }
        }
        haptic.sessionEnd()
        let data = buildSessionData()
        phoneConnector?.sendSessionComplete(data)
        return data
    }

    func locationManager(_ mgr: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last, loc.horizontalAccuracy > 0, loc.horizontalAccuracy < 25 else { return }
        if let last = lastLocation {
            let d = loc.distance(from: last)
            if d > 0.3 && d < 50 {
                totalDist += d; distance = totalDist; checkSplit()
            }
        }
        if loc.speed >= 0 {
            speedSamples.append(loc.speed)
            if speedSamples.count > 5 { speedSamples.removeFirst() }
            let avg = speedSamples.reduce(0, +) / Double(speedSamples.count)
            speed = avg; spdHistory.append(avg)
            if avg > maxSpd { maxSpd = avg }
            if avg > 0.1 { splitTime = 500.0 / avg }
        }
        lastLocation = loc
    }

    private func checkSplit() {
        while totalDist - lastSplitDist >= 500 {
            let now = Date()
            let t = lastSplitTime.map { now.timeIntervalSince($0) } ?? 0
            let avgSR = splitSR.isEmpty ? 0 : splitSR.reduce(0, +) / Double(splitSR.count)
            let avgHR = splitHR.isEmpty ? 0 : splitHR.reduce(0, +) / Double(splitHR.count)
            splits.append(SplitData(index: splits.count + 1, time: t, strokeRate: avgSR, heartRate: avgHR, speed: t > 0 ? 500 / t : 0))
            currentSplitIndex = splits.count
            lastSplitDist += 500; lastSplitTime = now
            splitSR.removeAll(); splitHR.removeAll()
            WKInterfaceDevice.current().play(.notification)
        }
    }

    private func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .rowing; config.locationType = .outdoor
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            workoutBuilder?.delegate = self; workoutSession?.delegate = self
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
        } catch {}
    }

    private func buildSessionData() -> SessionData {
        SessionData(
            id: UUID(), date: startTime ?? Date(), duration: elapsedTime, distance: totalDist,
            avgStrokeRate: srSamples.isEmpty ? 0 : srSamples.reduce(0, +) / Double(srSamples.count),
            maxStrokeRate: maxSR,
            avgSpeed: spdHistory.isEmpty ? 0 : spdHistory.reduce(0, +) / Double(spdHistory.count),
            maxSpeed: maxSpd,
            avgHeartRate: hrSamples.isEmpty ? 0 : hrSamples.reduce(0, +) / Double(hrSamples.count),
            maxHeartRate: maxHR, calories: calories,
            strokeCount: strokeDetector.strokeCount, splits: splits
        )
    }
}

extension RowingSession: HKWorkoutSessionDelegate {
    func workoutSession(_ s: HKWorkoutSession, didChangeTo: HKWorkoutSessionState, from: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ s: HKWorkoutSession, didFailWithError: Error) {}
}

extension RowingSession: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ b: HKLiveWorkoutBuilder) {}
    func workoutBuilder(_ b: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        for type in types {
            guard let qt = type as? HKQuantityType, let stats = b.statistics(for: qt) else { continue }
            DispatchQueue.main.async {
                switch qt {
                case HKQuantityType.quantityType(forIdentifier: .heartRate):
                    let bpm = stats.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
                    self.heartRate = bpm; self.hrSamples.append(bpm); self.splitHR.append(bpm)
                    if bpm > self.maxHR { self.maxHR = bpm }
                case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                    self.calories = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                default: break
                }
            }
        }
    }
}
