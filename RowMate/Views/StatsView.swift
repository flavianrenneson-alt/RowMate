import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: SessionStore

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if store.sessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("Pas encore de donnees")
                                .font(.headline)
                        }
                        .padding(.vertical, 60)
                    } else {
                        statsContent
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistiques")
        }
    }

    private var statsContent: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Seances", value: "\(store.sessions.count)", icon: "number", color: .blue)
                StatCard(title: "Distance", value: String(format: "%.1f km", store.totalDistance / 1000), icon: "location.fill", color: .green)
                StatCard(title: "Temps total", value: Formatters.time(store.totalDuration), icon: "timer", color: .orange)
                StatCard(title: "Coups total", value: "\(store.totalStrokes)", icon: "number.circle", color: .purple)
            }

            if let best = store.bestSplit500m {
                HStack {
                    Image(systemName: "trophy.fill").foregroundColor(.yellow).font(.title2)
                    VStack(alignment: .leading) {
                        Text("Meilleur split 500m").font(.subheadline).foregroundColor(.secondary)
                        Text(Formatters.split(best) + " /500m").font(.system(.title3, design: .rounded).bold())
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
            }

            if store.sessions.count >= 2 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Evolution cadence").font(.headline)
                    ProgressChart(
                        values: store.sessions.prefix(10).reversed().map(\.avgStrokeRate),
                        color: .orange
                    )
                    .frame(height: 140).padding()
                    .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(value).font(.system(.title3, design: .rounded).bold()).minimumScaleFactor(0.7).lineLimit(1)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
}

struct ProgressChart: View {
    let values: [Double]; let color: Color
    private var maxVal: Double { values.max() ?? 1 }
    private var minVal: Double { values.min() ?? 0 }

    var body: some View {
        GeometryReader { geo in
            let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    for (i, val) in values.enumerated() {
                        let pt = CGPoint(x: CGFloat(i) * stepX, y: geo.size.height - yPos(val, h: geo.size.height))
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                Path { path in
                    for (i, val) in values.enumerated() {
                        let pt = CGPoint(x: CGFloat(i) * stepX, y: geo.size.height - yPos(val, h: geo.size.height))
                        if i == 0 {
                            path.move(to: CGPoint(x: 0, y: geo.size.height))
                            path.addLine(to: pt)
                        } else { path.addLine(to: pt) }
                    }
                    path.addLine(to: CGPoint(x: CGFloat(values.count - 1) * stepX, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.05)], startPoint: .top, endPoint: .bottom))

                ForEach(0..<values.count, id: \.self) { i in
                    Circle().fill(color).frame(width: 6, height: 6)
                        .position(x: CGFloat(i) * stepX, y: geo.size.height - yPos(values[i], h: geo.size.height))
                }
            }
        }
    }

    private func yPos(_ val: Double, h: CGFloat) -> CGFloat {
        let range = max(maxVal - minVal, 1)
        return CGFloat((val - minVal) / range) * h * 0.8 + h * 0.1
    }
}
