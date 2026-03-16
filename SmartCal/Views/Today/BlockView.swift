import SwiftUI

struct BlockView: View {
    let block: ScheduleBlock
    let hourHeight: CGFloat

    private var height: CGFloat {
        CGFloat(block.durationMinutes) / 60.0 * hourHeight
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(block.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if block.durationMinutes >= 30 {
                    Text("\(block.startTime) – \(block.endTime)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Spacer(minLength: 0)
        }
        .frame(height: max(height, 20))
        .background(block.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(block.color.opacity(0.3), lineWidth: 1)
        )
    }
}
