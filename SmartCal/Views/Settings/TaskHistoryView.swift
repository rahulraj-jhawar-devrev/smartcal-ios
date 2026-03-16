import SwiftUI

struct TaskHistoryView: View {
    @State private var tasks: [SCTask] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && tasks.isEmpty {
                ProgressView().frame(maxHeight: .infinity)
            } else if tasks.isEmpty {
                ContentUnavailableView(
                    "No completed tasks",
                    systemImage: "checkmark.circle",
                    description: Text("Tasks you mark as done will appear here")
                )
            } else {
                List {
                    ForEach(groupedByDate, id: \.0) { dateLabel, group in
                        Section(dateLabel) {
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

    // Group by the calendar date of completedAt, newest first.
    // Tasks without a completedAt date go in an "Earlier" bucket.
    private var groupedByDate: [(String, [SCTask])] {
        var buckets: [(String, [SCTask])] = []
        var seen: [String: Int] = [:]  // dateLabel → index in buckets

        for task in tasks {
            let label = dateLabel(for: task.completedAt)
            if let idx = seen[label] {
                buckets[idx].1.append(task)
            } else {
                seen[label] = buckets.count
                buckets.append((label, [task]))
            }
        }
        return buckets
    }

    private static let sqliteFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private func dateLabel(for completedAt: String?) -> String {
        guard let raw = completedAt,
              let date = Self.sqliteFormatter.date(from: raw) else { return "Earlier" }
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: date)
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
                HStack(spacing: 8) {
                    Text(formattedDuration(task.durationMins))
                        .font(.caption).foregroundStyle(.quaternary)
                    priorityBadge(task.priority)
                }
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
