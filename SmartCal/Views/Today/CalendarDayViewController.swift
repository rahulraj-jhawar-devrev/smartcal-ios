import UIKit
import CalendarKit

/// CalendarKit DayViewController subclass that renders ScheduleBlocks.
final class CalendarDayViewController: DayViewController {

    var blocks: [ScheduleBlock] = [] {
        didSet { reloadData() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var style = CalendarStyle()
        style.timeline.verticalDiff = 60.0        // 60pt per hour — matches Apple Calendar density
        style.timeline.separatorColor = UIColor.separator
        style.timeline.backgroundColor = UIColor.systemBackground
        style.timeline.timeColor = UIColor.secondaryLabel
        updateStyle(style)

        // Move timeline to today
        move(to: Date())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Scroll to 1 hour before current time (min 7am so we don't start at midnight)
        let hour = max(Calendar.current.component(.hour, from: Date()) - 1, 7)
        dayView.scrollTo(hour24: Float(hour), animated: false)
    }

    // MARK: - EventDataSource

    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        blocks.compactMap { block -> Event? in
            guard let start = timeDate(block.start, on: date),
                  let end   = timeDate(block.end,   on: date),
                  end > start else { return nil }

            let event = Event()
            event.dateInterval = DateInterval(start: start, end: end)
            event.text         = block.label
            event.color        = uiColor(for: block.type)
            return event
        }
    }

    // MARK: - Helpers

    private func timeDate(_ hhmm: String, on date: Date) -> Date? {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return Calendar.current.date(
            bySettingHour: parts[0], minute: parts[1], second: 0, of: date
        )
    }

    private func uiColor(for type: ScheduleBlock.BlockType) -> UIColor {
        switch type {
        case .fixed:  return .systemBlue
        case .task:   return .systemPurple
        case .meal:   return .systemOrange
        case .buffer: return .systemGray3
        }
    }
}
