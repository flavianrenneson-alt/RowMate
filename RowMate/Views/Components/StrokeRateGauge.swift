import SwiftUI

struct StrokeRateGauge: View {
    let rate: Double
    private var norm: Double { min(max(rate / 40.0, 0), 1.0) }

    private var color: Color {
        if rate < 18 { return .blue }
        if rate < 24 { return .green }
        if rate < 30 { return .orange }
        return .red
    }

    private var zone: String {
        if rate < 18 { return "Recuperation" }
        if rate < 24 { return "Endurance" }
        if rate < 30 { return "Cadence haute" }
        return "Sprint"
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(90))
                Circle()
                    .trim(from: 0.15, to: 0.15 + norm * 0.7)
                    .stroke(
                        AngularGradient(colors: [.blue, .green, .orange, .red], center: .center, startAngle: .degrees(144), endAngle: .degrees(396)),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .animation(.easeOut(duration: 0.5), value: rate)
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", rate))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    Text("coups/min").font(.caption).foregroundColor(.secondary)
                }
            }
            .frame(height: 180).padding(.horizontal, 20)

            Text(zone)
                .font(.caption.weight(.semibold)).foregroundColor(color)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(color.opacity(0.15)).cornerRadius(8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground)).cornerRadius(16)
    }
}
