import SwiftUI

struct AddTaskView: View {
    let onAdd: (NewTask) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var hasDeadline = false
    @State private var durationMins = 30
    @State private var priority = "p1"
    @State private var isRecurring = false
    @State private var repeatDays = 7

    private let priorities: [(id: String, label: String, description: String)] = [
        ("p0", "P0 — Critical",  "Drop everything, do this now"),
        ("p1", "P1 — High",      "Important, gets deep-work slot"),
        ("p2", "P2 — Medium",    "Do this week"),
        ("p3", "P3 — Low",       "Nice to have"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Schedule") {
                    Toggle("Has deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline,
                                   in: Date()..., displayedComponents: .date)
                    }

                    Stepper(
                        "Estimated time: \(formattedDuration)",
                        value: $durationMins,
                        in: 15...480,
                        step: 15
                    )
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.id) { p in
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.label)
                                Text(p.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(p.id)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Recurring") {
                    Toggle("Repeat daily", isOn: $isRecurring)
                    if isRecurring {
                        Stepper(
                            "For \(repeatDays) day\(repeatDays == 1 ? "" : "s")",
                            value: $repeatDays,
                            in: 1...90,
                            step: 1
                        )
                        Text("e.g. Read 30 pages every day for \(repeatDays) days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { submit() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var formattedDuration: String {
        let hours = durationMins / 60
        let mins  = durationMins % 60
        if hours == 0 { return "\(mins) min" }
        if mins  == 0 { return "\(hours) hr" }
        return "\(hours) hr \(mins) min"
    }

    private func submit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        let deadlineString = hasDeadline ? iso.string(from: deadline) : nil
        let notesString = notes.trimmingCharacters(in: .whitespaces).isEmpty
            ? nil : notes.trimmingCharacters(in: .whitespaces)

        onAdd(NewTask(
            title: trimmedTitle,
            notes: notesString,
            deadline: deadlineString,
            durationMins: durationMins,
            priority: priority,
            repeatDays: isRecurring ? repeatDays : 0
        ))
        dismiss()
    }
}
