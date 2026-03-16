# Learning Notes — SmartCal iOS

Personal notes on iOS/SwiftUI patterns used in this project.

---

## MVVM in SwiftUI (iOS 17+)

The classic iOS architecture pattern adapted for SwiftUI:

```
View  ──reads──▶  ViewModel  ──calls──▶  Model / API
  ▲                   │
  └──── re-renders ───┘  (automatic, via @Observable)
```

- **Model** — plain Swift structs. Just data. No logic, no state.
- **ViewModel** — `@Observable` class. Owns the state, calls the API, transforms data for the view.
- **View** — SwiftUI struct. Reads from the ViewModel, calls methods on it. Zero business logic.

**Why `@Observable` instead of `ObservableObject`?**
`@Observable` (iOS 17+) only re-renders views that actually read a changed property.
`ObservableObject` + `@Published` re-renders everything in the view whenever *any* published property changes.

```swift
// Old way (iOS 16 and earlier)
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
}
// View needed: @StateObject var vm = TaskViewModel()

// New way (iOS 17+)
@Observable
class TaskViewModel {
    var tasks: [Task] = []  // no @Published needed
}
// View uses: @State var vm = TaskViewModel()
```

---

## Swift Actors for shared mutable state

`actor` is a concurrency primitive that serialises access to its state — like a mutex, but built into the type system.

```swift
actor APIClient {
    static let shared = APIClient()  // singleton, safe to call from anywhere
    private init() {}

    func getTasks() async throws -> [Task] { ... }
}
```

Why use an `actor` for `APIClient`?
- Multiple views might call it simultaneously (task list loads while settings saves)
- The actor ensures those calls don't corrupt shared state
- Compiler enforces `await` at every call site, making concurrency explicit

Same pattern for `NotificationManager` — scheduling notifications from multiple places is safe.

---

## async/await + Task { }

SwiftUI views are synchronous. To call async code from a button or `.task`:

```swift
// From a view modifier (preferred — auto-cancelled when view disappears)
.task { await viewModel.load() }

// From a button (fire-and-forget)
Button("Plan") {
    Task { await viewModel.planToday() }
}
```

**Error handling pattern used here:**
ViewModels catch errors internally and expose `errorMessage: String?`.
Views show it via `.errorBanner(message: vm.errorMessage)`.
This keeps views free of `do/catch` blocks.

```swift
func load() async {
    isLoading = true
    do {
        tasks = try await APIClient.shared.getTasks()
    } catch {
        errorMessage = error.localizedDescription  // view reacts automatically
    }
    isLoading = false
}
```

---

## Codable + CodingKeys for snake_case APIs

Swift uses camelCase. Most JSON APIs (including this one) use snake_case.
Map them with `CodingKeys`:

```swift
struct SCTask: Codable {
    let durationMinutes: Int

    enum CodingKeys: String, CodingKey {
        case durationMinutes = "duration_minutes"  // JSON key ↔ Swift property
    }
}
```

Note: The type is named `SCTask` (not `Task`) to avoid colliding with Swift's built-in `Task` concurrency type.

---

## Custom TimelineView (no third-party libraries)

The calendar view is a `ScrollView` + `ZStack` with manual pixel math:

```
totalHeight = totalHours × hourHeight   (e.g. 18h × 80pt = 1440pt)
blockY      = (startMinutes - offsetMinutes) / 60 × hourHeight
blockHeight = durationMinutes / 60 × hourHeight
```

```swift
ScrollView {
    ZStack(alignment: .topLeading) {
        hourGrid        // VStack of labeled rows, fixed spacing
        blocksLayer     // ForEach of BlockViews with .offset(y:)
        currentTimeLine // red line at today's minute offset
    }
    .frame(height: CGFloat(totalHours) * hourHeight)
}
```

Key insight: **everything is an offset from the top**, not relative to each other.
This is why ZStack works — all blocks share the same coordinate space.

---

## Local Notifications (UserNotifications)

No server involvement. Everything fires from the device.

```swift
// Request permission (shows the system dialog once)
try await UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .sound, .badge])

// Schedule a notification
let content = UNMutableNotificationContent()
content.title = "Starting soon"
content.body = "Write report"

var components = Calendar.current.dateComponents([.year,.month,.day], from: Date())
components.hour = 8
components.minute = 50  // 10 min before 9:00 block

let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
let request = UNNotificationRequest(identifier: "block-123", content: content, trigger: trigger)
try await UNUserNotificationCenter.current().add(request)
```

Cancel all before rescheduling (avoids duplicates on replan):
```swift
UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
```

---

## View Modifiers for reusable UI

Instead of copy-pasting an error banner into every view, one modifier covers all:

```swift
extension View {
    func errorBanner(message: String?) -> some View {
        self.overlay(alignment: .top) {
            if let message { ErrorBannerView(message: message) }
        }
    }
}

// Usage in any view:
.errorBanner(message: viewModel.errorMessage)
```

---

## DatePicker ↔ String binding

The API sends times as `"HH:mm"` strings. `DatePicker` needs `Date`.
Bridge them with a computed `Binding`:

```swift
DatePicker(
    "Wake time",
    selection: Binding(
        get: { dateFromString(constraints.wakeTime) },
        set: { constraints.wakeTime = stringFromDate($0) }
    ),
    displayedComponents: .hourAndMinute
)
```

---

## xcodegen

Instead of committing the enormous Xcode `.pbxproj` (which causes merge conflicts),
define the project in a clean `project.yml` and generate:

```bash
xcodegen generate   # creates SmartCal.xcodeproj from project.yml
```

Add `.xcodeproj` to `.gitignore` if working in a team (each dev generates locally).
For a solo project, committing it is fine.
