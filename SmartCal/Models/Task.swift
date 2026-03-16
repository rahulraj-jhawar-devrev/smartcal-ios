import Foundation

struct SCTask: Codable, Identifiable {
    let id: Int
    var title: String
    var deadline: String?
    var durationMinutes: Int
    var priority: String
    var status: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, deadline, priority, status
        case durationMinutes = "duration_minutes"
        case createdAt = "created_at"
    }
}

struct NewTask: Codable {
    let title: String
    let deadline: String?
    let durationMinutes: Int
    let priority: String

    enum CodingKeys: String, CodingKey {
        case title, deadline, priority
        case durationMinutes = "duration_minutes"
    }
}

struct TaskPatch: Codable {
    let status: String?
    let title: String?
    let deadline: String?
    let durationMinutes: Int?
    let priority: String?

    enum CodingKeys: String, CodingKey {
        case status, title, deadline, priority
        case durationMinutes = "duration_minutes"
    }
}
