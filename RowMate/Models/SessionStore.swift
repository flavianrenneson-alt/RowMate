import Foundation

class SessionStore: ObservableObject {
    @Published var sessions: [SessionData] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("rowmate_sessions.json")
    }()

    init() { load() }

    func add(_ session: SessionData) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SessionData].self, from: data)
        else { return }
        sessions = decoded
    }

    var totalDistance: Double { sessions.reduce(0) { $0 + $1.distance } }
    var totalDuration: TimeInterval { sessions.reduce(0) { $0 + $1.duration } }
    var totalStrokes: Int { sessions.reduce(0) { $0 + $1.strokeCount } }

    var bestSplit500m: TimeInterval? {
        sessions.compactMap { $0.avgSplit500m > 0 ? $0.avgSplit500m : nil }.min()
    }
}
