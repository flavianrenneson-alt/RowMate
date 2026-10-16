import SwiftUI

struct WatchHistoryView: View {
    @EnvironmentObject var store: WatchSessionStore

    var body: some View {
        List {
            ForEach(store.sessions) { s in
                NavigationLink(destination: WatchDetailView(session: s)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Formatters.dateShort(s.date)).font(.system(size: 12, weight: .semibold))
                        HStack(spacing: 8) {
                            Text(Formatters.time(s.duration)).font(.system(size: 11, design: .monospaced)).foregroundColor(.yellow)
                            Text(Formatters.distance(s.distance)).font(.system(size: 11)).foregroundColor(.green)
                        }
                        HStack(spacing: 8) {
                            Text(String(format: "%.0f c/m", s.avgStrokeRate)).font(.system(size: 10)).foregroundColor(.orange)
                            Text(Formatters.split(s.avgSplit500m) + " /500m").font(.system(size: 10)).foregroundColor(.purple)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete { store.delete(at: $0) }
        }
        .navigationTitle("Historique")
    }
}

struct WatchDetailView: View {
    let session: SessionData
    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text(Formatters.dateShort(session.date)).font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
                Divider()
                DR(label: "Duree", value: Formatters.time(session.duration))
                DR(label: "Distance", value: Formatters.distance(session.distance))
                DR(label: "Split 500m", value: Formatters.split(session.avgSplit500m))
                DR(label: "Cadence moy.", value: String(format: "%.0f c/min", session.avgStrokeRate))
                DR(label: "Cadence max.", value: String(format: "%.0f c/min", session.maxStrokeRate))
                DR(label: "FC moy.", value: String(format: "%.0f bpm", session.avgHeartRate))
                DR(label: "FC max.", value: String(format: "%.0f bpm", session.maxHeartRate))
                DR(label: "Calories", value: String(format: "%.0f kcal", session.calories))
                DR(label: "Coups", value: "\(session.strokeCount)")

                if !session.splits.isEmpty {
                    Divider()
                    Text("Splits 500m").font(.system(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(session.splits) { s in
                        HStack {
                            Text("#\(s.index)").font(.system(size: 11, weight: .bold)).foregroundColor(.cyan).frame(width: 22, alignment: .leading)
                            Text(Formatters.split(s.time)).font(.system(size: 12, design: .monospaced))
                            Spacer()
                            Text(String(format: "%.0f c/m", s.strokeRate)).font(.system(size: 10)).foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
        .navigationTitle("Details")
    }
}

private struct DR: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .rounded))
        }
    }
}
