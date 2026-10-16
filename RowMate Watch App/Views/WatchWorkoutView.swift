import SwiftUI

struct WatchWorkoutView: View {
    @ObservedObject var session: RowingSession
    @Binding var isPresented: Bool
    @EnvironmentObject var store: WatchSessionStore
    @State private var showSummary = false
    @State private var sessionData: SessionData?

    var body: some View {
        TabView {
            page1Cadence
            page2Navigation
            page3Health
            page4Controls
        }
        .tabViewStyle(PageTabViewStyle())
        .sheet(isPresented: $showSummary) {
            WatchSummaryView(data: sessionData, isPresented: $isPresented)
        }
    }

    // PAGE 1 : Cadence + Split
    private var page1Cadence: some View {
        VStack(spacing: 2) {
            Text(zoneLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(zoneColor)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(zoneColor.opacity(0.2))
                .cornerRadius(4)

            Text(String(format: "%.0f", session.strokeRate))
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundColor(zoneColor)
                .minimumScaleFactor(0.6)

            Text("coups/min").font(.system(size: 11)).foregroundColor(.secondary)

            Divider().padding(.vertical, 2)

            HStack(spacing: 4) {
                Image(systemName: "timer").font(.system(size: 10)).foregroundColor(.purple)
                Text("SPLIT 500m").font(.system(size: 10, weight: .semibold)).foregroundColor(.purple)
            }
            Text(Formatters.split(session.splitTime))
                .font(.system(size: 26, weight: .bold, design: .rounded))
        }
    }

    // PAGE 2 : Vitesse + Distance + Temps
    private var page2Navigation: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "stopwatch").font(.system(size: 10)).foregroundColor(.yellow)
                Text(Formatters.time(session.elapsedTime))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            .padding(.vertical, 4).frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.1)).cornerRadius(8)

            Divider()
            WMetric(label: "VITESSE", value: String(format: "%.1f", session.speed * 3.6), unit: "km/h", color: .cyan)
            Divider()
            WMetric(label: "DISTANCE", value: fmtDist(session.distance), unit: session.distance >= 1000 ? "km" : "m", color: .green)
        }
        .padding(.horizontal, 2)
    }

    // PAGE 3 : FC + Coups + Calories
    private var page3Health: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").font(.system(size: 10)).foregroundColor(.red)
                Text("FC").font(.system(size: 9, weight: .semibold)).foregroundColor(.red)
            }
            Text(String(format: "%.0f", session.heartRate))
                .font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(.red)
            Text("bpm").font(.system(size: 10)).foregroundColor(.secondary)

            Divider()
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(session.strokeCount)").font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("coups").font(.system(size: 10)).foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text(String(format: "%.0f", session.calories)).font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("kcal").font(.system(size: 10)).foregroundColor(.secondary)
                }
            }
        }
    }

    // PAGE 4 : Controles
    private var page4Controls: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Formatters.time(session.elapsedTime)).font(.system(size: 14, weight: .bold, design: .monospaced))
                    Text(fmtDist(session.distance) + (session.distance >= 1000 ? " km" : " m")).font(.system(size: 12)).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f c/m", session.strokeRate)).font(.system(size: 14, weight: .bold)).foregroundColor(.orange)
                    Text(String(format: "%.0f bpm", session.heartRate)).font(.system(size: 12)).foregroundColor(.red)
                }
            }
            .padding(.horizontal, 4)

            if session.isPaused {
                Button(action: { session.resume() }) {
                    HStack { Image(systemName: "play.fill"); Text("Reprendre") }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding(.vertical, 8).background(Color.green).cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button(action: { session.pause() }) {
                    HStack { Image(systemName: "pause.fill"); Text("Pause") }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black).frame(maxWidth: .infinity)
                        .padding(.vertical, 8).background(Color.yellow).cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button(action: {
                sessionData = session.stop()
                if let d = sessionData { store.add(d) }
                showSummary = true
            }) {
                HStack { Image(systemName: "stop.fill"); Text("Terminer") }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white).frame(maxWidth: .infinity)
                    .padding(.vertical, 8).background(Color.red).cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 4)
    }

    private var zoneColor: Color {
        if session.strokeRate < 1 { return .gray }
        if session.strokeRate < 18 { return .blue }
        if session.strokeRate < 24 { return .green }
        if session.strokeRate < 30 { return .orange }
        return .red
    }

    private var zoneLabel: String {
        if session.strokeRate < 1 { return "EN ATTENTE" }
        if session.strokeRate < 18 { return "RECUP" }
        if session.strokeRate < 24 { return "ENDURANCE" }
        if session.strokeRate < 30 { return "HAUTE" }
        return "SPRINT"
    }

    private func fmtDist(_ m: Double) -> String {
        m >= 1000 ? String(format: "%.2f", m / 1000) : String(format: "%.0f", m)
    }
}

struct WMetric: View {
    let label: String; let value: String; let unit: String; let color: Color
    var body: some View {
        VStack(spacing: 0) {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(color)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).minimumScaleFactor(0.5)
                if !unit.isEmpty { Text(unit).font(.system(size: 10)).foregroundColor(.secondary) }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
