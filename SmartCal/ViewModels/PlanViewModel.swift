import Foundation
import Observation

@Observable
class PlanViewModel {
    var schedule: DaySchedule?
    var isPlanning = false
    var isReplanning = false
    var errorMessage: String?

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func loadTodayPlan() async {
        errorMessage = nil
        do {
            schedule = try await APIClient.shared.getPlan(date: todayString)
        } catch {
            // No plan yet — that's fine, user will tap "Plan my day"
        }
    }

    func planToday() async {
        isPlanning = true
        errorMessage = nil
        do {
            schedule = try await APIClient.shared.planToday()
            if let s = schedule {
                await NotificationManager.shared.scheduleNotifications(for: s.blocks, on: Date())
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isPlanning = false
    }

    func replan() async {
        isReplanning = true
        errorMessage = nil
        do {
            schedule = try await APIClient.shared.replan(date: todayString)
            if let s = schedule {
                await NotificationManager.shared.scheduleNotifications(for: s.blocks, on: Date())
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isReplanning = false
    }
}
