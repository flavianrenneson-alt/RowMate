import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var store: WatchSessionStore
    @StateObject private var session = RowingSession()
    @State private var showWorkout = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "drop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)
                Text("RowMate")
                    .font(.system(.headline, design: .rounded))

                Button(action: {
                    session.phoneConnector = PhoneConnector.shared
                    session.requestPermissions()
                    session.start()
                    showWorkout = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Nouvelle seance")
                    }
                    .font(.system(.body, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())

                if store.sessions.count > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Seances").font(.system(size: 11)).foregroundColor(.secondary)
                            Spacer()
                            Text("\(store.sessions.count)").font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        HStack {
                            Text("Distance").font(.system(size: 11)).foregroundColor(.secondary)
                            Spacer()
                            Text(Formatters.distance(store.totalDistance)).font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        if let best = store.bestSplit500m {
                            HStack {
                                Image(systemName: "trophy.fill").font(.system(size: 9)).foregroundColor(.yellow)
                                Text("Meilleur split").font(.system(size: 11)).foregroundColor(.secondary)
                                Spacer()
                                Text(Formatters.split(best)).font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }

                if !store.sessions.isEmpty {
                    NavigationLink(destination: WatchHistoryView()) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Historique")
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 10))
                        }
                        .font(.system(size: 13))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .fullScreenCover(isPresented: $showWorkout) {
            WatchWorkoutView(session: session, isPresented: $showWorkout)
                .environmentObject(store)
        }
        .onAppear { session.requestPermissions() }
    }
}
