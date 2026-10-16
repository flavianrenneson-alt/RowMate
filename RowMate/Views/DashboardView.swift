import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var connector: WatchConnector
    private var m: LiveMetrics { connector.liveMetrics }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    connectionStatus
                    if m.isActive { liveContent } else { idleContent }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("RowMate")
        }
    }

    private var connectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connector.isWatchReachable ? (m.isActive ? Color.green : .orange) : .red)
                .frame(width: 10, height: 10)
            Text(connector.isWatchReachable
                 ? (m.isActive ? "Seance en cours" : "Watch connectee")
                 : "Watch non connectee")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            Spacer()
            if m.isActive {
                Text(Formatters.time(m.elapsedTime))
                    .font(.system(.subheadline, design: .monospaced).bold())
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var liveContent: some View {
        VStack(spacing: 16) {
            StrokeRateGauge(rate: m.strokeRate)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(title: "VITESSE", value: String(format: "%.1f", m.speed * 3.6), unit: "km/h", icon: "speedometer", color: .cyan)
                MetricCard(title: "SPLIT 500m", value: Formatters.split(m.splitTime), unit: "/500m", icon: "timer", color: .purple)
                MetricCard(title: "DISTANCE", value: m.distance >= 1000 ? String(format: "%.2f", m.distance / 1000) : String(format: "%.0f", m.distance), unit: m.distance >= 1000 ? "km" : "m", icon: "location.fill", color: .green)
                MetricCard(title: "FC", value: String(format: "%.0f", m.heartRate), unit: "bpm", icon: "heart.fill", color: .red)
                MetricCard(title: "COUPS", value: "\(m.strokeCount)", unit: "total", icon: "number.circle", color: .orange)
                MetricCard(title: "CALORIES", value: String(format: "%.0f", m.calories), unit: "kcal", icon: "flame.fill", color: .pink)
            }
        }
    }

    private var idleContent: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "drop.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.cyan.opacity(0.4))
            VStack(spacing: 8) {
                Text("Pret pour l'eau")
                    .font(.title2.bold())
                Text("Demarre une seance depuis ta Watch\npour voir les metriques en direct ici.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.vertical, 40)
    }
}
