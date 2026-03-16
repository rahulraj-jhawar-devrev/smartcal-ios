import Foundation
import Observation

@MainActor
@Observable
class TaskViewModel {
    var tasks: [SCTask] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            tasks = try await APIClient.shared.getTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addTask(_ newTask: NewTask) async {
        do {
            let created = try await APIClient.shared.createTask(newTask)
            tasks.append(created)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeTask(id: Int) async {
        do {
            let updated = try await APIClient.shared.updateTask(id: id, patch: TaskPatch(status: "done", title: nil, notes: nil, deadline: nil, durationMins: nil, priority: nil))
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                tasks[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(id: Int) async {
        do {
            try await APIClient.shared.deleteTask(id: id)
            tasks.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
