import Foundation

struct Constraints: Codable {
    var wakeTime: String
    var sleepTime: String
    var gymEnabled: Bool
    var gymTime: String
    var gymDurationMinutes: Int
    var lunchTime: String
    var lunchDurationMinutes: Int
    var deepWorkStart: String
    var deepWorkEnd: String

    enum CodingKeys: String, CodingKey {
        case wakeTime = "wake_time"
        case sleepTime = "sleep_time"
        case gymEnabled = "gym_enabled"
        case gymTime = "gym_time"
        case gymDurationMinutes = "gym_duration_minutes"
        case lunchTime = "lunch_time"
        case lunchDurationMinutes = "lunch_duration_minutes"
        case deepWorkStart = "deep_work_start"
        case deepWorkEnd = "deep_work_end"
    }

    static let `default` = Constraints(
        wakeTime: "07:00",
        sleepTime: "23:00",
        gymEnabled: false,
        gymTime: "07:00",
        gymDurationMinutes: 60,
        lunchTime: "13:00",
        lunchDurationMinutes: 45,
        deepWorkStart: "09:00",
        deepWorkEnd: "12:00"
    )
}
