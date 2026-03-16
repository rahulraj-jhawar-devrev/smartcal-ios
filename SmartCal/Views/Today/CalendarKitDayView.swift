import SwiftUI
import CalendarKit

/// SwiftUI wrapper around CalendarKit's DayViewController.
/// Displays a single-day timeline with the given schedule blocks.
struct CalendarKitDayView: UIViewControllerRepresentable {
    let blocks: [ScheduleBlock]

    func makeUIViewController(context: Context) -> CalendarDayViewController {
        let vc = CalendarDayViewController()
        vc.blocks = blocks
        return vc
    }

    func updateUIViewController(_ vc: CalendarDayViewController, context: Context) {
        vc.blocks = blocks
    }
}
