import SwiftUI

struct TimelineView: View {
    let schedule: DaySchedule
    let hourHeight: CGFloat = 80

    private let startHour = 6
    private let endHour = 24
    private var totalHours: Int { endHour - startHour }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour grid lines + labels
                    hourGrid

                    // Schedule blocks (offset by left column)
                    blocksLayer
                        .padding(.leading, 44)

                    // Current time indicator
                    currentTimeIndicator
                        .padding(.leading, 44)
                }
                .frame(height: CGFloat(totalHours) * hourHeight)
                .padding(.bottom, 20)
            }
            .onAppear {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let scrollTarget = max(currentHour - startHour - 1, 0)
                withAnimation {
                    proxy.scrollTo("hour-\(scrollTarget + startHour)", anchor: .top)
                }
            }
        }
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(startHour..<endHour, id: \.self) { hour in
                HStack(spacing: 0) {
                    Text(String(format: "%02d", hour))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                        .padding(.trailing, 8)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                }
                .frame(height: hourHeight, alignment: .top)
                .id("hour-\(hour)")
            }
        }
    }

    private var blocksLayer: some View {
        ZStack(alignment: .topLeading) {
            ForEach(schedule.blocks) { block in
                let yOffset = CGFloat(block.startMinutes - startHour * 60) / 60.0 * hourHeight
                if block.startMinutes >= startHour * 60 {
                    BlockView(block: block, hourHeight: hourHeight)
                        .padding(.trailing, 8)
                        .offset(y: yOffset)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var currentTimeIndicator: some View {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        let yOffset = CGFloat(totalMinutes - startHour * 60) / 60.0 * hourHeight

        return Group {
            if totalMinutes >= startHour * 60 && totalMinutes < endHour * 60 {
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 1.5)
                }
                .offset(y: yOffset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
