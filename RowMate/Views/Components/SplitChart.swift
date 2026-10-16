import SwiftUI

struct SplitChart: View {
    let splits: [SplitData]
    private var maxTime: TimeInterval { splits.map(\.time).max() ?? 1 }
    private var minTime: TimeInterval { splits.map(\.time).min() ?? 0 }

    var body: some View {
        GeometryReader { geo in
            let barW = max(20, (geo.size.width - CGFloat(splits.count - 1) * 4) / CGFloat(splits.count))
            let range = max(maxTime - minTime, 1)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(splits) { s in
                    VStack(spacing: 4) {
                        Text(Formatters.split(s.time))
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(s.time))
                            .frame(width: barW, height: max(10, geo.size.height * 0.7 * barH(s.time, range: range)))
                        Text("\(s.index)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    private func barH(_ t: TimeInterval, range: TimeInterval) -> CGFloat {
        CGFloat(max(0.15, min(1.0, (1.0 - (t - minTime) / range) * 0.85 + 0.15)))
    }

    private func barColor(_ t: TimeInterval) -> Color {
        guard splits.count >= 2 else { return .cyan }
        let med = splits.map(\.time).sorted()[splits.count / 2]
        if t < med * 0.98 { return .green }
        if t > med * 1.02 { return .orange }
        return .cyan
    }
}
