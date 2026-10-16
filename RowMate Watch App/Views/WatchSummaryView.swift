import SwiftUI

struct WatchSummaryView: View {
    let data: SessionData?
    @Binding var isPresented: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 28)).foregroundColor(.green)
                Text("Seance terminee").font(.system(.headline, design: .rounded)).padding(.bottom, 4)

                if let d = data {
                    SRow(icon: "timer", label: "Duree", value: Formatters.time(d.duration))
                    SRow(icon: "location.fill", label: "Distance", value: Formatters.distance(d.distance))
                    SRow(icon: "speedometer", label: "Split moy.", value: Formatters.split(d.avgSplit500m) + " /500m")
                    SRow(icon: "drop.circle.fill", label: "Cadence moy.", value: String(format: "%.0f c/min", d.avgStrokeRate))
                    SRow(icon: "drop.circle.fill", label: "Cadence max.", value: String(format: "%.0f c/min", d.maxStrokeRate))
                    SRow(icon: "heart.fill", label: "FC moy.", value: String(format: "%.0f bpm", d.avgHeartRate))
                    SRow(icon: "heart.fill", label: "FC max.", value: String(format: "%.0f bpm", d.maxHeartRate))
                    SRow(icon: "flame.fill", label: "Calories", value: String(format: "%.0f kcal", d.calories))
                    SRow(icon: "number.circle", label: "Coups", value: "\(d.strokeCount)")

                    if !d.splits.isEmpty {
                        Divider().padding(.vertical, 4)
                        Text("Splits 500m").font(.system(size: 11, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(d.splits) { s in
                            HStack {
                                Text("#\(s.index)").font(.system(size: 11, weight: .bold)).foregroundColor(.cyan).frame(width: 24, alignment: .leading)
                                Text(Formatters.split(s.time)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                                Spacer()
                                Text(String(format: "%.0f c/m", s.strokeRate)).font(.system(size: 10)).foregroundColor(.orange)
                            }
                        }
                    }
                }

                Button(action: { isPresented = false }) {
                    Text("OK")
                        .font(.system(.body, weight: .semibold))
                        .foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding(.vertical, 8).background(Color.blue).cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 8)
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct SRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.cyan).frame(width: 16).font(.system(size: 10))
            Text(label).font(.system(size: 11)).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold, design: .rounded))
        }
    }
}
