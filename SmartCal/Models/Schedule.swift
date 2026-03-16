import Foundation
import SwiftUI

struct ScheduleBlock: Codable, Identifiable {
    let label: String
    let start: String
    let end: String
    let type: BlockType
    let taskId: Int?

    // Backend doesn't send an id — derive a stable one from position in schedule
    var id: String { "\(start)-\(end)-\(label)" }

    enum CodingKeys: String, CodingKey {
        case label, start, end, type
        case taskId = "task_id"
    }

    enum BlockType: String, Codable {
        case fixed
        case task
        case buffer
        case meal
    }

    var startMinutes: Int { minutesFrom(start) }
    var endMinutes: Int   { minutesFrom(end) }
    var durationMinutes: Int { endMinutes - startMinutes }

    // Convenience aliases used by views
    var startTime: String { start }
    var endTime: String   { end }

    var color: Color {
        switch type {
        case .fixed:  return .blue
        case .buffer: return .gray.opacity(0.5)
        case .meal:   return .orange
        case .task:   return .purple
        }
    }

    private func minutesFrom(_ time: String) -> Int {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}

struct DaySchedule: Codable {
    let date: String
    let blocks: [ScheduleBlock]
    let reasoning: String?
}
