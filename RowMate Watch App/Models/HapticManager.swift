import WatchKit

class HapticManager {
    private var lastZone: Int = -1

    func checkZoneChange(strokeRate: Double) {
        let zone: Int
        if strokeRate < 1 { zone = 0 }
        else if strokeRate < 18 { zone = 1 }
        else if strokeRate < 24 { zone = 2 }
        else if strokeRate < 30 { zone = 3 }
        else { zone = 4 }

        if zone != lastZone && lastZone > 0 && zone > 0 {
            if zone > lastZone {
                WKInterfaceDevice.current().play(.directionUp)
            } else {
                WKInterfaceDevice.current().play(.directionDown)
            }
        }
        lastZone = zone
    }

    func sessionEnd() {
        WKInterfaceDevice.current().play(.success)
    }
}
