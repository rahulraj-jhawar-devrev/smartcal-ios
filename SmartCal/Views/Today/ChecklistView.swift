import SwiftUI

/// The main Today tab content — replaces the calendar timeline.
/// Shows the day's plan as an ordered checklist:
///   1. Scheduled blocks (timed, from the LLM plan) — task blocks are checkable
///   2. Task pile — unscheduled tasks the user can pick off
struct ChecklistView: View {
    let schedule: DaySchedule
    let tasks: [SCTask]
    let onCompleteTask: (Int) async -> Void

    /// Local check state for non-task blocks (fixed/meal) — not persisted
    @State private var localChecked: Set<String> = []

    private var scheduledTaskIds: Set<Int> {
        Set(schedule.blocks.compactMap(\.taskId))
    }

    private var unscheduledTasks: [SCTask] {
        tasks.filter { !scheduledTaskIds.contains($0.id) && $0.status != "done" }
    }

    var body: some View {
        List {
            scheduledSection
            if !unscheduledTasks.isEmpty {
                taskPileSection
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Scheduled section

    private var scheduledSection: some View {
        Section {
            ForEach(schedule.blocks.filter { $0.type != .buffer }) { block in
                blockRow(block)
            }
        } header: {
            Label("Today's plan", systemImage: "sparkles")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.purple)
        }
    }

    // MARK: - Task pile section

    private var taskPileSection: some View {
        Section {
            ForEach(unscheduledTasks) { task in
                taskPileRow(task)
            }
        } header: {
            HStack {
                Label("Task pile", systemImage: "tray.full")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(unscheduledTasks.count) not scheduled")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Row builders

    @ViewBuilder
    private func blockRow(_ block: ScheduleBlock) -> some View {
        let isTask = block.type == .task
        let taskForBlock = block.taskId.flatMap { id in tasks.first { $0.id == id } }
        let isDone: Bool = {
            if let t = taskForBlock { return t.status == "done" }
            return localChecked.contains(block.id)
        }()

        HStack(alignment: .center, spacing: 12) {
            // Checkbox or dot
            if isTask {
                Button {
                    if let id = block.taskId {
                        Task { await onCompleteTask(id) }
                    } else {
                        toggleLocal(block.id)
                    }
                } label: {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isDone ? .green : .secondary)
                }
                .buttonStyle(.plain)
            } else {
                // Anchor dot (fixed/meal)
                Circle()
                    .fill(block.color)
                    .frame(width: 9, height: 9)
                    .padding(.leading, 3)
            }

            // Time + label
            VStack(alignment: .leading, spacing: 2) {
                Text(block.label)
                    .font(isTask ? .body : .subheadline)
                    .fontWeight(isTask ? .regular : .regular)
                    .foregroundStyle(isTask ? (isDone ? .secondary : .primary) : .secondary)
                    .strikethrough(isDone)

                HStack(spacing: 6) {
                    Text(block.start)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if isTask {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(formattedDuration(block.durationMinutes))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Priority badge for task blocks
            if let task = taskForBlock {
                priorityBadge(task.priority)
            }
        }
        .padding(.vertical, isTask ? 5 : 2)
        .opacity(isTask ? 1.0 : 0.55)
    }

    @ViewBuilder
    private func taskPileRow(_ task: SCTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                Task { await onCompleteTask(task.id) }
            } label: {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 8) {
                    if let deadline = task.deadline {
                        Label(formatDeadline(deadline), systemImage: "calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(formattedDuration(task.durationMins))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if task.repeatDays > 0 {
                        Label("\(task.repeatDays)d", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
            }

            Spacer()
            priorityBadge(task.priority)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func toggleLocal(_ id: String) {
        if localChecked.contains(id) {
            localChecked.remove(id)
        } else {
            localChecked.insert(id)
        }
    }

    @ViewBuilder
    private func priorityBadge(_ priority: String) -> some View {
        let color: Color = switch priority {
        case "p0": .red
        case "p1": .orange
        case "p2": .blue
        default:   .secondary
        }
        Text(priority.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func formattedDuration(_ mins: Int) -> String {
        let h = mins / 60, m = mins % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hr" }
        return "\(h) hr \(m) min"
    }

    private func formatDeadline(_ deadline: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        guard let date = iso.date(from: deadline) else { return deadline }
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
