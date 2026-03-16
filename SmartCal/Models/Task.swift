import Foundation

struct SCTask: Codable, Identifiable {
    let id: Int
    var title: String
    var notes: String?
    var deadline: String?
    var durationMins: Int
    var priority: String
    var status: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, notes, deadline, priority, status
        case durationMins = "duration_mins"
        case createdAt = "created_at"
    }
}

struct NewTask: Codable {
    let title: String
    let notes: String?
    let deadline: String?
    let durationMins: Int
    let priority: String

    enum CodingKeys: String, CodingKey {
        case title, notes, deadline, priority
        case durationMins = "duration_mins"
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
