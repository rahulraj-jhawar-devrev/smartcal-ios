import SwiftUI

struct SettingsView: View {
    @State private var viewModel = ConstraintViewModel()
    @State private var showAddRoutine = false

    var body: some View {
        NavigationStack {
            Form {
                sleepSection
                dailyRoutinesSection
                saveSection
                historySection
            }
            .navigationTitle("Settings")
            .task { await viewModel.load() }
            .errorBanner(message: viewModel.errorMessage) {
                viewModel.errorMessage = nil
            }
            .overlay {
                if viewModel.saveSuccess {
                    SaveSuccessToast()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewModel.saveSuccess = false
                            }
                        }
                }
            }
            .sheet(isPresented: $showAddRoutine) {
                AddRoutineSheet { newRoutine in
                    viewModel.constraints.dailyRoutines.append(newRoutine)
                }
            }
        }
    }

    // MARK: - Sections

    private var sleepSection: some View {
        Section("Sleep schedule") {
            TimePickerRow(label: "Wake time",  time: $viewModel.constraints.wakeTime)
            TimePickerRow(label: "Sleep time", time: $viewModel.constraints.sleepTime)
        }
    }

    private var dailyRoutinesSection: some View {
        Section {
            ForEach($viewModel.constraints.dailyRoutines) { $routine in
                RoutineRow(routine: $routine)
            }
            .onDelete { viewModel.constraints.dailyRoutines.remove(atOffsets: $0) }
            Button {
                showAddRoutine = true
            } label: {
                Label("Add routine", systemImage: "plus")
                    .font(.subheadline)
            }
        } header: {
            Text("Daily routines")
        } footer: {
            Text("Fixed daily blocks (gym, meals, meditation, etc.). Swipe left to remove.")
                .font(.caption)
        }
    }

    private var historySection: some View {
        Section {
            NavigationLink(destination: TaskHistoryView()) {
                Label("Task history", systemImage: "checkmark.circle")
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task { await viewModel.save() }
            } label: {
                if viewModel.isSaving {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    Text("Save").frame(maxWidth: .infinity)
                }
            }
            .disabled(viewModel.isSaving)
        }
    }
}

// MARK: - RoutineRow

struct RoutineRow: View {
    @Binding var routine: DailyRoutine
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Toggle(routine.name, isOn: $routine.enabled)
                    .tint(.purple)
                Spacer()
                Text(routine.time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    withAnimation(.spring(duration: 0.2)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                }
            }

            if isExpanded {
                Divider().padding(.vertical, 6)
                TimePickerRow(label: "Time", time: $routine.time)
                Stepper(
                    "Duration: \(routine.durationMins) min",
                    value: $routine.durationMins,
                    in: 5...180,
                    step: 5
                )
            }
        }
        .padding(.vertical, 2)
        .animation(.spring(duration: 0.2), value: isExpanded)
    }
}

// MARK: - AddRoutineSheet

struct AddRoutineSheet: View {
    let onAdd: (DailyRoutine) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var time = "08:00"
    @State private var durationMins = 30

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name (e.g. Morning walk, Gym, Reading…)", text: $name)
                }
                Section {
                    TimePickerRow(label: "Time", time: $time)
                    Stepper("Duration: \(durationMins) min",
                            value: $durationMins, in: 5...180, step: 5)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(DailyRoutine(
                            id: UUID().uuidString,
                            name: name.trimmingCharacters(in: .whitespaces),
                            time: time,
                            durationMins: durationMins,
                            enabled: true,
                            routineType: "fixed"
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Shared helpers

struct TimePickerRow: View {
    let label: String
    @Binding var time: String

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    var body: some View {
        DatePicker(
            label,
            selection: Binding(
                get: { Self.fmt.date(from: time) ?? Date() },
                set: { time = Self.fmt.string(from: $0) }
            ),
            displayedComponents: .hourAndMinute
        )
    }
}

struct SaveSuccessToast: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("Settings saved").font(.subheadline).fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.bottom, 32)
        }
    }
}
