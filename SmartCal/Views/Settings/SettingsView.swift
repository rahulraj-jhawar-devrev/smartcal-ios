import SwiftUI

struct SettingsView: View {
    @State private var viewModel = ConstraintViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep schedule") {
                    TimePickerRow(label: "Wake time", time: $viewModel.constraints.wakeTime)
                    TimePickerRow(label: "Sleep time", time: $viewModel.constraints.sleepTime)
                }

                Section("Gym") {
                    Toggle("Gym enabled", isOn: $viewModel.constraints.gymEnabled)
                    if viewModel.constraints.gymEnabled {
                        TimePickerRow(label: "Gym time", time: $viewModel.constraints.gymTime)
                        Stepper(
                            "Duration: \(viewModel.constraints.gymDurationMinutes) min",
                            value: $viewModel.constraints.gymDurationMinutes,
                            in: 15...180,
                            step: 15
                        )
                    }
                }

                Section("Meals") {
                    TimePickerRow(label: "Lunch time", time: $viewModel.constraints.lunchTime)
                    Stepper(
                        "Lunch duration: \(viewModel.constraints.lunchDurationMinutes) min",
                        value: $viewModel.constraints.lunchDurationMinutes,
                        in: 15...120,
                        step: 15
                    )
                }

                Section("Deep work") {
                    TimePickerRow(label: "Start", time: $viewModel.constraints.deepWorkStart)
                    TimePickerRow(label: "End", time: $viewModel.constraints.deepWorkEnd)
                }

                Section {
                    Button {
                        Task { await viewModel.save() }
                    } label: {
                        if viewModel.isSaving {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .navigationTitle("Settings")
            .task { await viewModel.load() }
            .errorBanner(message: viewModel.errorMessage)
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
        }
    }
}

struct TimePickerRow: View {
    let label: String
    @Binding var time: String

    @State private var date: Date = Date()
    private var isInitialized = false

    init(label: String, time: Binding<String>) {
        self.label = label
        self._time = time
        self._date = State(initialValue: Self.dateFromTimeString(time.wrappedValue))
    }

    var body: some View {
        DatePicker(
            label,
            selection: Binding(
                get: { Self.dateFromTimeString(time) },
                set: { newDate in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    time = formatter.string(from: newDate)
                }
            ),
            displayedComponents: .hourAndMinute
        )
    }

    static func dateFromTimeString(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }
}

struct SaveSuccessToast: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Settings saved")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.bottom, 32)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring, value: true)
    }
}
