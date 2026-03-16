import Foundation
import Observation

@MainActor
@Observable
class TodayViewModel {
    var tasks: [SCTask] = []
    var constraints: Constraints = .default
    var isLoading = false
    var errorMessage: String?

    // Task IDs selected for today — persisted by date in UserDefaults
    var selectedTaskIds: Set<Int> = []

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private var todayKey: String {
        "today_\(Self.dayFormatter.string(from: Date()))"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        // Restore today's selection from UserDefaults
        let saved = UserDefaults.standard.array(forKey: todayKey) as? [Int] ?? []
        selectedTaskIds = Set(saved)
        do {
            async let fetchedTasks = APIClient.shared.getTasks()
            async let fetchedConstraints = APIClient.shared.getConstraints()
            tasks = try await fetchedTasks
            constraints = try await fetchedConstraints
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleSelection(_ taskId: Int) {
        if selectedTaskIds.contains(taskId) {
            selectedTaskIds.remove(taskId)
        } else {
            selectedTaskIds.insert(taskId)
        }
        UserDefaults.standard.set(Array(selectedTaskIds), forKey: todayKey)
    }

    func uncompleteTask(id: Int) async {
        do {
            let updated = try await APIClient.shared.updateTask(
                id: id,
                patch: TaskPatch(status: "pending", title: nil, notes: nil,
                                 deadline: nil, durationMins: nil, priority: nil)
            )
            if let i = tasks.firstIndex(where: { $0.id == id }) {
                tasks[i] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeTask(id: Int) async {
        do {
            let updated = try await APIClient.shared.updateTask(
                id: id,
                patch: TaskPatch(status: "done", title: nil, notes: nil,
                                 deadline: nil, durationMins: nil, priority: nil)
            )
            if let i = tasks.firstIndex(where: { $0.id == id }) {
                tasks[i] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Derived lists

    /// Enabled daily routines sorted by time — shown as reference anchors
    var dailyAnchors: [DailyRoutine] {
        constraints.dailyRoutines
            .filter { $0.enabled }
            .sorted { $0.time < $1.time }
    }

    /// Tasks selected for today (done ones stay visible with strikethrough)
    var todayTasks: [SCTask] {
        tasks
            .filter { selectedTaskIds.contains($0.id) }
            .sorted { priorityRank($0.priority) < priorityRank($1.priority) }
    }

    /// Pending tasks not yet selected for today
    var taskPile: [SCTask] {
        tasks.filter { !selectedTaskIds.contains($0.id) && $0.status != "done" }
    }

    var doneCount: Int { todayTasks.filter { $0.status == "done" }.count }

    private func priorityRank(_ p: String) -> Int {
        ["p0": 0, "p1": 1, "p2": 2, "p3": 3][p] ?? 4
    }
}
