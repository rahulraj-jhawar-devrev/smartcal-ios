import SwiftUI

struct TodayView: View {
    @State private var vm = TodayViewModel()

    private var todayTitle: String {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.tasks.isEmpty {
                    loadingSkeleton
                } else {
                    mainList
                }
            }
            .navigationTitle("Today · \(todayTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .task { await vm.load() }
            .errorBanner(message: vm.errorMessage) {
                vm.errorMessage = nil
            }
        }
    }

    // MARK: - Main list

    private var mainList: some View {
        List {
            if !vm.dailyAnchors.isEmpty {
                anchorsSection
            }
            todayTasksSection
            if !vm.taskPile.isEmpty {
                taskPileSection
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Anchors section (fixed schedule from Settings)

    private var anchorsSection: some View {
        Section {
            ForEach(vm.dailyAnchors) { anchor in
                HStack(spacing: 12) {
                    anchorIcon(for: anchor.routineType)
                        .frame(width: 22)
                    Text(anchor.time)
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.tertiary)
                    Text(anchor.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(anchor.durationMins) min")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
                .padding(.vertical, 1)
            }
        } header: {
            Label("Fixed schedule", systemImage: "clock")
                .font(.footnote).fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func anchorIcon(for type: String) -> some View {
        switch type {
        case "meal":  Image(systemName: "fork.knife").foregroundStyle(.orange).font(.caption)
        case "fixed": Image(systemName: "figure.run").foregroundStyle(.blue).font(.caption)
        default:      Image(systemName: "brain.head.profile").foregroundStyle(.purple).font(.caption)
        }
    }

    // MARK: - Today's tasks section

    private var todayTasksSection: some View {
        Section {
            if vm.todayTasks.isEmpty {
                Label("Tap tasks below to add to your day", systemImage: "hand.tap")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(vm.todayTasks) { task in
                    TodayTaskRow(task: task) {
                        Task { await vm.completeTask(id: task.id) }
                    } onUncomplete: {
                        Task { await vm.uncompleteTask(id: task.id) }
                    } onRemove: {
                        vm.toggleSelection(task.id)
                    }
                }
            }
        } header: {
            HStack {
                Label("Today's tasks", systemImage: "checkmark.circle")
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(.purple)
                Spacer()
                if !vm.todayTasks.isEmpty {
                    Text("\(vm.doneCount)/\(vm.todayTasks.count) done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Task pile section

    private var taskPileSection: some View {
        Section {
            ForEach(vm.taskPile) { task in
                TaskPileRow(task: task) {
                    vm.toggleSelection(task.id)
                }
            }
        } header: {
            HStack {
                Label("Task pile", systemImage: "tray.full")
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(vm.taskPile.count) pending")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Loading skeleton

    private var loadingSkeleton: some View {
        List {
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle().frame(width: 22, height: 22)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).frame(height: 14)
                        RoundedRectangle(cornerRadius: 4).frame(width: 100, height: 11)
                    }
                    Spacer()
                }
                .foregroundStyle(.quaternary)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
        .redacted(reason: .placeholder)
    }
}

// MARK: - TodayTaskRow

struct TodayTaskRow: View {
    let task: SCTask
    let onComplete: () -> Void
    let onUncomplete: () -> Void
    let onRemove: () -> Void

    private var isDone: Bool { task.status == "done" }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: isDone ? onUncomplete : onComplete) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(isDone)
                    .foregroundStyle(isDone ? .secondary : .primary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .strikethrough(isDone)
                }
                HStack(spacing: 8) {
                    Text(formattedDuration(task.durationMins))
                        .font(.caption).foregroundStyle(.tertiary)
                    if let deadline = task.deadline {
                        Label(formatDeadline(deadline), systemImage: "calendar")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                    if task.repeatDays > 0 {
                        Label("\(task.repeatDays)d", systemImage: "arrow.clockwise")
                            .font(.caption).foregroundStyle(.purple)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                priorityBadge(task.priority)
                if !isDone {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - TaskPileRow

struct TaskPileRow: View {
    let task: SCTask
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        Text(formattedDuration(task.durationMins))
                            .font(.caption).foregroundStyle(.tertiary)
                        if let deadline = task.deadline {
                            Label(formatDeadline(deadline), systemImage: "calendar")
                                .font(.caption).foregroundStyle(.tertiary)
                        }
                        if task.repeatDays > 0 {
                            Label("\(task.repeatDays)d", systemImage: "arrow.clockwise")
                                .font(.caption).foregroundStyle(.purple)
                        }
                    }
                }

                Spacer()
                priorityBadge(task.priority)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared helpers (file-local)

private func priorityBadge(_ priority: String) -> some View {
    let color: Color = switch priority {
    case "p0": .red
    case "p1": .orange
    case "p2": .blue
    default:   .secondary
    }
    return Text(priority.uppercased())
        .font(.caption2).fontWeight(.semibold)
        .padding(.horizontal, 6).padding(.vertical, 2)
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

private func formatDeadline(_ s: String) -> String {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withFullDate]
    guard let d = iso.date(from: s) else { return s }
    let f = DateFormatter(); f.dateStyle = .short
    return f.string(from: d)
}
