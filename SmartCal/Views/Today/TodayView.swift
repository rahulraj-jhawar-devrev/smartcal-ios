import SwiftUI

struct TodayView: View {
    @State private var planVM = PlanViewModel()
    @State private var taskVM = TaskViewModel()

    private var todayTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                actionBar

                Divider()

                if let schedule = planVM.schedule {
                    ChecklistView(
                        schedule: schedule,
                        tasks: taskVM.tasks,
                        onCompleteTask: { id in await taskVM.completeTask(id: id) }
                    )
                } else if planVM.isPlanning {
                    planningState
                } else {
                    emptyState
                }
            }
            .navigationTitle("Today · \(todayTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                async let plan: () = planVM.loadTodayPlan()
                async let tasks: () = taskVM.load()
                await plan; await tasks
            }
            .errorBanner(message: planVM.errorMessage) {
                planVM.errorMessage = nil
            }
        }
    }

    // MARK: - Sub-views

    private var actionBar: some View {
        HStack {
            Button {
                Task { await planVM.planToday() }
            } label: {
                Label("Plan my day", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(planVM.isPlanning || planVM.isReplanning)

            if planVM.schedule != nil {
                Button {
                    Task { await planVM.replan() }
                } label: {
                    Label("Replan", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
                .disabled(planVM.isPlanning || planVM.isReplanning)
            }

            Spacer()

            if planVM.isPlanning || planVM.isReplanning {
                ProgressView()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No plan yet",
            systemImage: "checklist",
            description: Text("Tap 'Plan my day' to generate your schedule")
        )
    }

    private var planningState: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("Planning your day...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}
