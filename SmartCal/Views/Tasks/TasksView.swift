import SwiftUI

struct TasksView: View {
    @State private var viewModel = TaskViewModel()
    @State private var showAddTask = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    loadingSkeleton
                } else if viewModel.tasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView { newTask in
                    Task { await viewModel.addTask(newTask) }
                }
            }
            .task { await viewModel.load() }
            .errorBanner(message: viewModel.errorMessage) {
                viewModel.errorMessage = nil
            }
        }
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.tasks.filter { $0.status != "done" }) { task in
                TaskRowView(task: task) {
                    Task { await viewModel.completeTask(id: task.id) }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteTask(id: task.id) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No tasks",
            systemImage: "checklist",
            description: Text("Tap + to add your first task")
        )
    }

    private var loadingSkeleton: some View {
        List {
            ForEach(0..<4, id: \.self) { _ in
                HStack {
                    Circle()
                        .frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 120, height: 11)
                    }
                    Spacer()
                }
                .foregroundStyle(.quaternary)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .redacted(reason: .placeholder)
    }
}

struct TaskRowView: View {
    let task: SCTask
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: task.status == "done" ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.status == "done" ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.status == "done")
                    .foregroundStyle(task.status == "done" ? .secondary : .primary)

                HStack(spacing: 8) {
                    if let deadline = task.deadline {
                        Label(formatDeadline(deadline), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Label("\(task.durationMins) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    priorityBadge
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityBadge: some View {
        let color: Color = switch task.priority {
        case "high": .red
        case "medium": .orange
        default: .blue
        }
        return Text(task.priority)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func formatDeadline(_ deadline: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        guard let date = iso.date(from: deadline) else { return deadline }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
