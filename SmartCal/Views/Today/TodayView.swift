import SwiftUI

struct TodayView: View {
    @State private var viewModel = PlanViewModel()

    private var todayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Action bar
                HStack {
                    Button {
                        Task { await viewModel.planToday() }
                    } label: {
                        Label("Plan my day", systemImage: "sparkles")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .disabled(viewModel.isPlanning || viewModel.isReplanning)

                    if viewModel.schedule != nil {
                        Button {
                            Task { await viewModel.replan() }
                        } label: {
                            Label("Replan", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                        .disabled(viewModel.isPlanning || viewModel.isReplanning)
                    }

                    Spacer()

                    if viewModel.isPlanning || viewModel.isReplanning {
                        ProgressView()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider()

                // Timeline or empty state
                if let schedule = viewModel.schedule {
                    TimelineView(schedule: schedule)
                } else if !viewModel.isPlanning {
                    emptyState
                } else {
                    planningState
                }
            }
            .navigationTitle("Today · \(todayTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadTodayPlan() }
            .errorBanner(message: viewModel.errorMessage)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No plan yet",
            systemImage: "calendar.badge.plus",
            description: Text("Tap 'Plan my day' to generate your schedule")
        )
    }

    private var planningState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Planning your day...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}
