import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: SessionStore

    var body: some View {
        NavigationView {
            Group {
                if store.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("Aucune seance")
                            .font(.headline)
                        Text("Tes seances d'aviron apparaitront ici.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(store.sessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(Formatters.dateShort(session.date))
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(Formatters.time(session.duration))
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    HStack(spacing: 16) {
                                        Label(Formatters.distance(session.distance), systemImage: "location.fill")
                                        Label(String(format: "%.0f c/min", session.avgStrokeRate), systemImage: "drop.circle.fill")
                                        Label(Formatters.split(session.avgSplit500m) + " /500m", systemImage: "timer")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { store.delete(at: $0) }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Historique")
        }
    }
}
