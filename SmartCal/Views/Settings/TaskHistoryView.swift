import SwiftUI

struct TaskHistoryView: View {
    @State private var tasks: [SCTask] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && tasks.isEmpty {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if tasks.isEmpty {
                ContentUnavailableView(
                    "No completed tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Tasks you mark as done will appear here")
                )
            } else {
                List {
                    ForEach(groupedByPriority, id: \.0) { priority, group in
                        Section(header: priorityHeader(priority)) {
                            ForEach(group) { task in
                                HistoryRow(task: task)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Task History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .errorBanner(message: errorMessage) { errorMessage = nil }
    }

    private var groupedByPriority: [(String, [SCTask])] {
        let order = ["p0", "p1", "p2", "p3"]
        return order.compactMap { p in
            let group = tasks.filter { $0.priority == p }
            return group.isEmpty ? nil : (p, group)
        }
    }

    private func priorityHeader(_ priority: String) -> some View {
        let (label, color): (String, Color) = switch priority {
        case "p0": ("P0 — Critical", .red)
        case "p1": ("P1 — High", .orange)
        case "p2": ("P2 — Medium", .blue)
        default:   ("P3 — Low", .secondary)
        }
        return Text(label)
            .font(.footnote).fontWeight(.semibold)
            .foregroundStyle(color)
    }

    private func load() async {
        isLoading = true
        do {
            tasks = try await APIClient.shared.getCompletedTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct HistoryRow: View {
    let task: SCTask

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.body)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Text(formattedDuration(task.durationMins))
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formattedDuration(_ mins: Int) -> String {
        let h = mins / 60, m = mins % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hr" }
        return "\(h) hr \(m) min"
    }
}
