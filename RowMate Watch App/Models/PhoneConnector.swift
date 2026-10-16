import Foundation
import WatchConnectivity

class PhoneConnector: NSObject, WCSessionDelegate {
    static let shared = PhoneConnector()
    private var session: WCSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendMetrics(_ metrics: LiveMetrics) {
        guard let s = session, s.isReachable, let data = try? JSONEncoder().encode(metrics) else { return }
        s.sendMessage(["type": WatchMessage.metricsUpdate.rawValue, "data": data], replyHandler: nil)
    }

    func sendSessionComplete(_ sessionData: SessionData) {
        guard let s = session, let data = try? JSONEncoder().encode(sessionData) else { return }
        s.transferUserInfo(["type": WatchMessage.sessionComplete.rawValue, "data": data])
    }

    func session(_ s: WCSession, activationDidCompleteWith: WCSessionActivationState, error: Error?) {}
}
