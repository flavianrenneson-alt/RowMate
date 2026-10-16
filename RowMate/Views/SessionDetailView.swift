import SwiftUI

struct SessionDetailView: View {
    let session: SessionData

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard
                metricsGrid
                if !session.splits.isEmpty { splitsSection }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(Formatters.dateShort(session.date)).font(.headline)
            HStack(spacing: 24) {
                VStack {
                    Text(Formatters.time(session.duration)).font(.system(.title2, design: .rounded).bold())
                    Text("Duree").font(.caption).foregroundColor(.secondary)
                }
                VStack {
                    Text(Formatters.distance(session.distance)).font(.system(.title2, design: .rounded).bold())
                    Text("Distance").font(.caption).foregroundColor(.secondary)
                }
                VStack {
                    Text(Formatters.split(session.avgSplit500m)).font(.system(.title2, design: .rounded).bold())
                    Text("/500m").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color(.secondarySystemGroupedBackground)).cornerRadius(16)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DetailMetric(title: "Cadence moy.", value: String(format: "%.0f", session.avgStrokeRate), unit: "c/min", color: .orange)
            DetailMetric(title: "Cadence max.", value: String(format: "%.0f", session.maxStrokeRate), unit: "c/min", color: .orange)
            DetailMetric(title: "Vitesse moy.", value: Formatters.speed(session.avgSpeed), unit: "km/h", color: .cyan)
            DetailMetric(title: "Vitesse max.", value: Formatters.speed(session.maxSpeed), unit: "km/h", color: .cyan)
            DetailMetric(title: "FC moy.", value: String(format: "%.0f", session.avgHeartRate), unit: "bpm", color: .red)
            DetailMetric(title: "FC max.", value: String(format: "%.0f", session.maxHeartRate), unit: "bpm", color: .red)
            DetailMetric(title: "Coups", value: "\(session.strokeCount)", unit: "", color: .green)
            DetailMetric(title: "Calories", value: String(format: "%.0f", session.calories), unit: "kcal", color: .pink)
        }
    }

    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Splits 500m").font(.headline).padding(.horizontal, 4)
            SplitChart(splits: session.splits)
                .frame(height: 120).padding()
                .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
            VStack(spacing: 0) {
                HStack {
                    Text("#").frame(width: 30, alignment: .leading)
                    Text("Temps").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Cadence").frame(maxWidth: .infinity, alignment: .trailing)
                    Text("FC").frame(width: 50, alignment: .trailing)
                }
                .font(.caption.weight(.semibold)).foregroundColor(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 8)
                ForEach(session.splits) { split in
                    HStack {
                        Text("\(split.index)").frame(width: 30, alignment: .leading).fontWeight(.medium)
                        Text(Formatters.split(split.time)).frame(maxWidth: .infinity, alignment: .leading).font(.system(.body, design: .monospaced))
                        Text(String(format: "%.0f c/m", split.strokeRate)).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(String(format: "%.0f", split.heartRate)).frame(width: 50, alignment: .trailing)
                    }
                    .font(.subheadline).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(split.index % 2 == 0 ? Color(.tertiarySystemGroupedBackground) : Color.clear)
                }
            }
            .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
        }
    }
}

struct DetailMetric: View {
    let title: String; let value: String; let unit: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(unit).font(.system(size: 11)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
}
