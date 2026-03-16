import Foundation
import UserNotifications

actor NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleNotifications(for blocks: [ScheduleBlock], on date: Date) async {
        _ = await requestAuthorization()

        await cancelAllNotifications()

        let calendar = Calendar.current
        let taskBlocks = blocks.filter { $0.type == .task }

        for block in taskBlocks {
            let reminderMinute = block.startMinutes - 10
            guard reminderMinute >= 0 else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = reminderMinute / 60
            components.minute = reminderMinute % 60
            components.second = 0

            let content = UNMutableNotificationContent()
            content.title = "Starting soon"
            content.body = block.label
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "block-\(block.id)",
                content: content,
                trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(request)
        }

        // Morning briefing at wake time (first fixed block)
        if let wakeBlock = blocks.first(where: { $0.type == .fixed }) {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = wakeBlock.startMinutes / 60
            components.minute = wakeBlock.startMinutes % 60
            components.second = 0

            let content = UNMutableNotificationContent()
            content.title = "Your day is planned"
            content.body = "\(taskBlocks.count) task\(taskBlocks.count == 1 ? "" : "s") scheduled"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "morning-briefing",
                content: content,
                trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
