import Foundation
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var liveMetrics = LiveMetrics()
    @Published var isWatchReachable = false
    var sessionStore: SessionStore?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.isWatchReachable = session.isReachable }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isWatchReachable = session.isReachable }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message["type"] as? String,
              type == WatchMessage.metricsUpdate.rawValue,
              let data = message["data"] as? Data,
              let metrics = try? JSONDecoder().decode(LiveMetrics.self, from: data)
        else { return }
        DispatchQueue.main.async { self.liveMetrics = metrics }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let type = userInfo["type"] as? String,
              type == WatchMessage.sessionComplete.rawValue,
              let data = userInfo["data"] as? Data,
              let sessionData = try? JSONDecoder().decode(SessionData.self, from: data)
        else { return }
        DispatchQueue.main.async {
            self.sessionStore?.add(sessionData)
            self.liveMetrics = LiveMetrics()
        }
    }
}
