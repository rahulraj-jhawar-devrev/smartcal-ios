import Foundation

// Priority scale: p0 (critical) → p1 (high) → p2 (medium) → p3 (low)

struct SCTask: Codable, Identifiable {
    let id: Int
    var title: String
    var notes: String?
    var deadline: String?
    var durationMins: Int
    var priority: String    // "p0" | "p1" | "p2" | "p3"
    var status: String
    var repeatDays: Int     // 0 = one-time; N = schedule daily for N more days
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, notes, deadline, priority, status
        case durationMins = "duration_mins"
        case repeatDays   = "repeat_days"
        case createdAt    = "created_at"
    }

    // repeat_days may not exist in older DB rows — default to 0
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(Int.self,    forKey: .id)
        title        = try c.decode(String.self, forKey: .title)
        notes        = try? c.decode(String.self, forKey: .notes)
        deadline     = try? c.decode(String.self, forKey: .deadline)
        durationMins = try c.decode(Int.self,    forKey: .durationMins)
        priority     = try c.decode(String.self, forKey: .priority)
        status       = try c.decode(String.self, forKey: .status)
        createdAt    = try c.decode(String.self, forKey: .createdAt)
        repeatDays   = (try? c.decode(Int.self,  forKey: .repeatDays)) ?? 0
    }
}

struct NewTask: Codable {
    let title: String
    let notes: String?
    let deadline: String?
    let durationMins: Int
    let priority: String
    let repeatDays: Int

    enum CodingKeys: String, CodingKey {
        case title, notes, deadline, priority
        case durationMins = "duration_mins"
        case repeatDays   = "repeat_days"
    }
}

struct TaskPatch: Codable {
    let status: String?
    let title: String?
    let notes: String?
    let deadline: String?
    let durationMins: Int?
    let priority: String?

    enum CodingKeys: String, CodingKey {
        case status, title, notes, deadline, priority
        case durationMins = "duration_mins"
    }
}
