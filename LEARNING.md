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

---

## Bug journal — mistakes made and fixed

### Bug 1: Swift 6 data race errors on ViewModels

**Symptom:** Compiler error on every `.task { await viewModel.load() }`:
```
error: sending 'self.viewModel' risks causing data races
```

**Why it happened:** Swift 6 introduced strict concurrency. SwiftUI views run on
`@MainActor`. The `@Observable` ViewModels had no actor annotation, so Swift
couldn't prove it was safe to call their `async` methods from the main actor.

**Fix:** Add `@MainActor` to every ViewModel class:
```swift
@MainActor
@Observable
class TaskViewModel { ... }
```

This pins the ViewModel to the main thread. No data race possible — everything
is on the same actor. The compiler is satisfied.

**Lesson:** In Swift 6, any class that's owned and mutated by a SwiftUI view
should be `@MainActor`. Make it the default for ViewModels.

---

### Bug 2: Dead properties in TimePickerRow

**Symptom:** `TimePickerRow` had two properties that were declared but never read:
```swift
@State private var date: Date = Date()   // never used
private var isInitialized = false         // never used
```

**Why it happened:** Early draft had the DatePicker bound to `@State var date`,
then it was refactored to use a computed `Binding` directly from the `time` string.
The old properties were left behind.

**Fix:** Delete both. The body already derived everything from `time` via `Binding`.

**Lesson:** Read your own structs top to bottom before shipping. Unused `@State`
properties still allocate storage and can cause confusing re-renders.

---

### Bug 3: DateFormatter allocated on every picker drag

**Symptom:** Inside `TimePickerRow.body`, a new `DateFormatter` was being
constructed inside the `Binding`'s setter — which fires continuously as the
user drags the time picker wheel.

```swift
// BAD — runs on every drag tick
set: { newDate in
    let formatter = DateFormatter()   // expensive allocation
    formatter.dateFormat = "HH:mm"
    time = formatter.string(from: newDate)
}
```

**Fix:** Cache as a `static let` on the struct — allocated once ever:
```swift
private static let displayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
}()
```

**Lesson:** `DateFormatter`, `NumberFormatter`, `JSONDecoder` etc. are expensive
to create. Always make them `static let` or store them as a property, never
allocate them inside a function/closure that runs frequently.

---

### Bug 4: Current time indicator frozen at launch time

**Symptom:** The red "current time" line on the timeline was computed once
when the view loaded and never updated. It showed the correct position at
open time, then stayed there even as minutes passed.

**Why it happened:** The `currentTimeIndicator` computed var read `Date()`
directly. SwiftUI only re-evaluates a computed var when state changes — with no
state tied to the clock, it never re-evaluated.

**Fix:** Add a `@State var now = Date()` and drive it with a `Timer`:
```swift
@State private var now = Date()
private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

// in body:
.onReceive(timer) { now = $0 }

// currentTimeIndicator reads `now` instead of Date()
```

Now SwiftUI sees `now` change every 60 seconds and re-renders the indicator.

**Lesson:** `Date()` in a SwiftUI computed property is evaluated once at render
time. If you want live-updating time, you need explicit state + a timer.

---

### Bug 5: Error banners couldn't be dismissed

**Symptom:** Once an error appeared (e.g. network failure), the red banner
stayed on screen forever with no way to dismiss it.

**Fix:** Added an optional `onDismiss` closure to the `errorBanner` modifier,
and an ✕ button in the banner that calls it. Call sites pass a closure that
sets `viewModel.errorMessage = nil`:

```swift
.errorBanner(message: viewModel.errorMessage) {
    viewModel.errorMessage = nil
}
```

**Lesson:** Any UI that surfaces an error needs a way to clear it. The pattern
here — error as `String?` in the ViewModel, nil to clear — works cleanly
because `@Observable` automatically re-renders the banner away when it becomes nil.

---

### Bug 6: `.animation(.spring, value: true)` does nothing

**Symptom:** The `SaveSuccessToast` had this:
```swift
.animation(.spring, value: true)
```

`true` is a constant — it never changes — so SwiftUI never sees a value change
and never triggers the animation. The toast appeared/disappeared with no transition.

**Fix:** Remove the modifier from the toast itself. The parent `overlay` drives
visibility via `viewModel.saveSuccess`, so the transition belongs on the
`if viewModel.saveSuccess { SaveSuccessToast() }` level, handled by the overlay.

**Lesson:** `.animation(_:value:)` only fires when `value` changes between renders.
Passing a constant literal like `true` or `42` is always a bug — it means
"never animate". Transitions on conditional views should be placed at the
branching point (the `if`), not deep inside the view being shown.

---

### Bug 7: iOS models didn't match the actual backend JSON (app was completely broken)

**Symptom:** Tasks showed 0 min duration. Schedule/timeline never rendered.
Settings crashed on load. Everything silently failed.

**Root cause:** The iOS models were written based on assumed field names, not
the actual running backend. There were 5 mismatches:

| Field | Backend sent | iOS expected | Effect |
|---|---|---|---|
| Task duration | `duration_mins` | `duration_minutes` | Always decoded as 0 |
| Schedule times | `start`, `end` | `start_time`, `end_time` | Timeline decoded nothing |
| Schedule block id | not sent | required `id: String` | Entire schedule decode failed |
| Constraint durations | `gym_duration_mins` | `gym_duration_minutes` | Always 0 |
| Constraint types | strings (`"true"`, `"60"`) | `Bool`, `Int` | Settings crashed |

**How to catch this earlier:** Before writing iOS models, read the actual API
response with `curl` and check every field name and type. Don't assume.

```bash
curl -s https://your-api/tasks | jq '.[0]'
curl -s https://your-api/constraints | jq '.'
curl -s https://your-api/plan/today -X POST | jq '.blocks[0]'
```

**The constraints problem was subtle:** The backend stores all constraints as
string key-value pairs in SQLite (because it's a generic key-value store).
So even `gym_enabled` comes back as the string `"false"`, and `gym_duration_mins`
comes back as `"60"`. Swift's default `Codable` can't coerce strings to `Bool`
or `Int` — it throws a type mismatch error.

**Fix:** Custom `init(from:)` and `encode(to:)` on `Constraints` that manually
convert between Swift types and their string representations:

```swift
// Decode: string → typed
let gymEnabledStr = try c.decode(String.self, forKey: .gymEnabled)
gymEnabled = gymEnabledStr == "true"

let gymDurStr = try c.decode(String.self, forKey: .gymDurationMins)
gymDurationMins = Int(gymDurStr) ?? 60

// Encode: typed → string (so backend stores them correctly)
try c.encode(gymEnabled ? "true" : "false", forKey: .gymEnabled)
try c.encode(String(gymDurationMins), forKey: .gymDurationMins)
```

**The `id` problem:** Swift's `Identifiable` protocol requires a stable `id`
on every element in a `ForEach`. The backend doesn't send an id on schedule
blocks. Fix: derive a synthetic id from the block's data:

```swift
var id: String { "\(start)-\(end)-\(label)" }
```

This is a computed property, not a stored one, so it doesn't need a CodingKey.

**Lesson:** Always verify your models against the real running API before
building any UI on top of them. A single field name mismatch will cause silent
decode failures — Swift won't crash, it'll just return nil or 0 and you'll
spend hours wondering why the UI is empty.
