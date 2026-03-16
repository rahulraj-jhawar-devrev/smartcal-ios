import Foundation

// The backend stores all constraints as string key-value pairs in SQLite.
// GET /constraints returns a flat dict like:
//   { "wake_time": "07:00", "gym_enabled": "false", "gym_duration_mins": "60", ... }
// We need custom Codable to coerce strings → Bool/Int on decode,
// and Bool/Int → strings on encode so the API accepts them back.

struct Constraints: Codable {
    var wakeTime: String
    var sleepTime: String
    var gymEnabled: Bool
    var gymTime: String
    var gymDurationMins: Int
    var lunchTime: String
    var lunchDurationMins: Int
    var deepWorkStart: String
    var deepWorkEnd: String

    enum CodingKeys: String, CodingKey {
        case wakeTime        = "wake_time"
        case sleepTime       = "sleep_time"
        case gymEnabled      = "gym_enabled"
        case gymTime         = "gym_time"
        case gymDurationMins = "gym_duration_mins"
        case lunchTime       = "lunch_time"
        case lunchDurationMins = "lunch_duration_mins"
        case deepWorkStart   = "deep_work_start"
        case deepWorkEnd     = "deep_work_end"
    }

    // Decode — all values arrive as strings from the backend
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wakeTime      = try c.decode(String.self, forKey: .wakeTime)
        sleepTime     = try c.decode(String.self, forKey: .sleepTime)
        gymTime       = try c.decode(String.self, forKey: .gymTime)
        deepWorkStart = try c.decode(String.self, forKey: .deepWorkStart)
        deepWorkEnd   = try c.decode(String.self, forKey: .deepWorkEnd)
        lunchTime     = try c.decode(String.self, forKey: .lunchTime)

        let gymEnabledStr    = try c.decode(String.self, forKey: .gymEnabled)
        let gymDurStr        = try c.decode(String.self, forKey: .gymDurationMins)
        let lunchDurStr      = try c.decode(String.self, forKey: .lunchDurationMins)

        gymEnabled       = gymEnabledStr == "true"
        gymDurationMins  = Int(gymDurStr)   ?? 60
        lunchDurationMins = Int(lunchDurStr) ?? 45
    }

    // Encode — send everything back as strings so the backend stores them correctly
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(wakeTime,                    forKey: .wakeTime)
        try c.encode(sleepTime,                   forKey: .sleepTime)
        try c.encode(gymEnabled ? "true" : "false", forKey: .gymEnabled)
        try c.encode(gymTime,                     forKey: .gymTime)
        try c.encode(String(gymDurationMins),     forKey: .gymDurationMins)
        try c.encode(lunchTime,                   forKey: .lunchTime)
        try c.encode(String(lunchDurationMins),   forKey: .lunchDurationMins)
        try c.encode(deepWorkStart,               forKey: .deepWorkStart)
        try c.encode(deepWorkEnd,                 forKey: .deepWorkEnd)
    }

    init(wakeTime: String, sleepTime: String, gymEnabled: Bool, gymTime: String,
         gymDurationMins: Int, lunchTime: String, lunchDurationMins: Int,
         deepWorkStart: String, deepWorkEnd: String) {
        self.wakeTime = wakeTime
        self.sleepTime = sleepTime
        self.gymEnabled = gymEnabled
        self.gymTime = gymTime
        self.gymDurationMins = gymDurationMins
        self.lunchTime = lunchTime
        self.lunchDurationMins = lunchDurationMins
        self.deepWorkStart = deepWorkStart
        self.deepWorkEnd = deepWorkEnd
    }

    static let `default` = Constraints(
        wakeTime: "07:00", sleepTime: "23:00",
        gymEnabled: false, gymTime: "07:00", gymDurationMins: 60,
        lunchTime: "13:00", lunchDurationMins: 45,
        deepWorkStart: "09:00", deepWorkEnd: "12:00"
    )
}
