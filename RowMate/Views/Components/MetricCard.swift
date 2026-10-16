import SwiftUI

struct MetricCard: View {
    let title: String; let value: String; let unit: String; let icon: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
                Text(unit).font(.system(size: 12)).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
}
