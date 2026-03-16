import SwiftUI

struct AddTaskView: View {
    let onAdd: (NewTask) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var hasDeadline = false
    @State private var durationMins = 30
    @State private var priority = "medium"

    private let priorities = ["low", "medium", "high"]

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
                        DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }

                    Stepper(
                        "Estimated time: \(formattedDuration)",
                        value: $durationMins,
                        in: 15...480,
                        step: 15
                    )

                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { p in
                            Text(p.capitalized).tag(p)
                        }
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

    // e.g. "30 min", "1 hr", "1 hr 30 min"
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
        let notesString = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)

        onAdd(NewTask(
            title: trimmedTitle,
            notes: notesString,
            deadline: deadlineString,
            durationMins: durationMins,
            priority: priority
        ))
        dismiss()
    }
}
