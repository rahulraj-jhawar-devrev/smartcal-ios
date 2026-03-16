import SwiftUI

struct AddTaskView: View {
    let onAdd: (NewTask) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var durationMins = 30
    @State private var priority = "medium"

    private let priorities = ["low", "medium", "high"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                }

                Section("Schedule") {
                    Toggle("Has deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }

                    Stepper("Duration: \(durationMins) min", value: $durationMins, in: 15...480, step: 15)

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
                    Button("Add") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let iso = ISO8601DateFormatter()
                        iso.formatOptions = [.withFullDate]
                        let deadlineString = hasDeadline ? iso.string(from: deadline) : nil
                        onAdd(NewTask(
                            title: title,
                            deadline: deadlineString,
                            durationMins: durationMins,
                            priority: priority
                        ))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
