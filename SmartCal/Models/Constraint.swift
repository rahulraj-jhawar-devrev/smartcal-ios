import Foundation

// MARK: - Sub-models

/// A single deep-work time window (e.g. 09:00–12:00).
/// id is a local UUID for SwiftUI — not encoded to the backend.
struct DeepWorkSession: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var start: String
    var end: String

    enum CodingKeys: String, CodingKey { case start, end }

    init(start: String, end: String) {
        self.start = start; self.end = end
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        start = try c.decode(String.self, forKey: .start)
        end   = try c.decode(String.self, forKey: .end)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(start, forKey: .start)
        try c.encode(end,   forKey: .end)
    }
}

/// A user-defined daily routine block (gym, lunch, dinner, meditation, etc.)
struct DailyRoutine: Codable, Identifiable, Equatable {
    var id: String            // stable — "gym", "lunch", or UUID string for custom
    var name: String
    var time: String          // HH:mm
    var durationMins: Int
    var enabled: Bool
    var routineType: String   // "fixed", "meal", "task"

    enum CodingKeys: String, CodingKey {
        case id, name, time, enabled
        case durationMins = "duration_mins"
        case routineType  = "type"
    }
}

// MARK: - Constraints

// The backend stores all constraints as string key-value pairs in SQLite.
// Arrays (deep work sessions, daily routines) are stored as JSON strings.
// Legacy keys (gym_*, lunch_*, deep_work_start/end) are decoded for backward compat
// but new saves always use the modular format.

struct Constraints: Codable {
    var wakeTime: String
    var sleepTime: String
    var deepWorkSessions: [DeepWorkSession]
    var dailyRoutines: [DailyRoutine]

    enum CodingKeys: String, CodingKey {
        case wakeTime           = "wake_time"
        case sleepTime          = "sleep_time"
        case deepWorkSessions   = "deep_work_sessions"
        case dailyRoutines      = "daily_routines"
        // Legacy keys — decode only
        case deepWorkStart      = "deep_work_start"
        case deepWorkEnd        = "deep_work_end"
        case gymEnabled         = "gym_enabled"
        case gymTime            = "gym_time"
        case gymDurationMins    = "gym_duration_mins"
        case lunchTime          = "lunch_time"
        case lunchDurationMins  = "lunch_duration_mins"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        wakeTime  = try c.decode(String.self, forKey: .wakeTime)
        sleepTime = try c.decode(String.self, forKey: .sleepTime)

        // Deep work sessions — new JSON-string format, fall back to legacy single window
        if let raw = try? c.decode(String.self, forKey: .deepWorkSessions),
           let data = raw.data(using: .utf8),
           let sessions = try? JSONDecoder().decode([DeepWorkSession].self, from: data),
           !sessions.isEmpty {
            deepWorkSessions = sessions
        } else {
            let start = (try? c.decode(String.self, forKey: .deepWorkStart)) ?? "09:00"
            let end   = (try? c.decode(String.self, forKey: .deepWorkEnd))   ?? "12:00"
            deepWorkSessions = [DeepWorkSession(start: start, end: end)]
        }

        // Daily routines — new JSON-string format, fall back to legacy gym + lunch keys
        if let raw = try? c.decode(String.self, forKey: .dailyRoutines),
           let data = raw.data(using: .utf8),
           let routines = try? JSONDecoder().decode([DailyRoutine].self, from: data),
           !routines.isEmpty {
            dailyRoutines = routines
        } else {
            let gymEnabled  = (try? c.decode(String.self, forKey: .gymEnabled)) ?? "false"
            let gymTime     = (try? c.decode(String.self, forKey: .gymTime))    ?? "07:00"
            let gymDurStr   = (try? c.decode(String.self, forKey: .gymDurationMins)) ?? "60"
            let lunchTime   = (try? c.decode(String.self, forKey: .lunchTime))  ?? "13:00"
            let lunchDurStr = (try? c.decode(String.self, forKey: .lunchDurationMins)) ?? "45"
            dailyRoutines = [
                DailyRoutine(id: "gym",    name: "Gym",    time: gymTime,
                             durationMins: Int(gymDurStr)   ?? 60,
                             enabled: gymEnabled == "true", routineType: "fixed"),
                DailyRoutine(id: "lunch",  name: "Lunch",  time: lunchTime,
                             durationMins: Int(lunchDurStr) ?? 45,
                             enabled: true, routineType: "meal"),
                DailyRoutine(id: "dinner", name: "Dinner", time: "20:00",
                             durationMins: 45, enabled: true, routineType: "meal"),
            ]
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(wakeTime,  forKey: .wakeTime)
        try c.encode(sleepTime, forKey: .sleepTime)

        let sessionsJSON = try JSONEncoder().encode(deepWorkSessions)
        try c.encode(String(data: sessionsJSON, encoding: .utf8)!, forKey: .deepWorkSessions)

        let routinesJSON = try JSONEncoder().encode(dailyRoutines)
        try c.encode(String(data: routinesJSON, encoding: .utf8)!, forKey: .dailyRoutines)
    }

    init(wakeTime: String, sleepTime: String,
         deepWorkSessions: [DeepWorkSession],
         dailyRoutines: [DailyRoutine]) {
        self.wakeTime          = wakeTime
        self.sleepTime         = sleepTime
        self.deepWorkSessions  = deepWorkSessions
        self.dailyRoutines     = dailyRoutines
    }

    static let `default` = Constraints(
        wakeTime:  "07:00",
        sleepTime: "23:00",
        deepWorkSessions: [DeepWorkSession(start: "09:00", end: "12:00")],
        dailyRoutines: [
            DailyRoutine(id: "gym",    name: "Gym",       time: "07:00",
                         durationMins: 60,  enabled: false, routineType: "fixed"),
            DailyRoutine(id: "lunch",  name: "Lunch",     time: "13:00",
                         durationMins: 45,  enabled: true,  routineType: "meal"),
            DailyRoutine(id: "dinner", name: "Dinner",    time: "20:00",
                         durationMins: 45,  enabled: true,  routineType: "meal"),
        ]
    )
}
