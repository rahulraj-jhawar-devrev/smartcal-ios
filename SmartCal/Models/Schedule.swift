import Foundation
import SwiftUI

struct ScheduleBlock: Codable, Identifiable {
    let id: String
    let label: String
    let startTime: String
    let endTime: String
    let type: BlockType
    let taskId: Int?

    enum CodingKeys: String, CodingKey {
        case id, label, type
        case startTime = "start_time"
        case endTime = "end_time"
        case taskId = "task_id"
    }

    enum BlockType: String, Codable {
        case fixed
        case task
        case buffer
        case meal
    }

    var startMinutes: Int {
        minutesFromTimeString(startTime)
    }

    var endMinutes: Int {
        minutesFromTimeString(endTime)
    }

    var durationMinutes: Int {
        endMinutes - startMinutes
    }

    var color: Color {
        switch type {
        case .fixed: return .blue
        case .buffer: return .gray.opacity(0.5)
        case .meal: return .orange
        case .task: return .purple
        }
    }

    private func minutesFromTimeString(_ time: String) -> Int {
        let parts = time.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count >= 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }
}

struct DaySchedule: Codable {
    let date: String
    let blocks: [ScheduleBlock]
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case date, blocks
        case generatedAt = "generated_at"
    }
}
