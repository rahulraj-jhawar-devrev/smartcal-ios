# SmartCal

An AI-powered daily planner. Add tasks, set your schedule constraints, and let Claude generate a time-blocked calendar for your day.

---

## Architecture

```mermaid
graph TB
    subgraph iOS["iOS App (SwiftUI)"]
        direction TB
        TV[TodayView<br/>Timeline + Plan/Replan]
        TKV[TasksView<br/>List + Add + Complete]
        SV[SettingsView<br/>Constraints form]

        TV --> PVM[PlanViewModel]
        TKV --> TKVM[TaskViewModel]
        SV --> CVM[ConstraintViewModel]

        PVM --> AC[APIClient<br/>actor]
        TKVM --> AC
        CVM --> AC

        PVM --> NM[NotificationManager<br/>actor]
    end

    subgraph Backend["Backend (EC2 · ap-south-1)"]
        direction TB
        EX[Express API<br/>TypeScript · port 3001]
        DB[(SQLite)]
        CL[Claude API<br/>structured JSON output]

        EX --> DB
        EX --> CL
    end

    AC -->|HTTPS| EX

    subgraph Endpoints["API endpoints"]
        direction LR
        E1["GET /tasks"]
        E2["POST /tasks"]
        E3["PATCH /tasks/:id"]
        E4["DELETE /tasks/:id"]
        E5["GET /constraints"]
        E6["PUT /constraints"]
        E7["POST /plan/today"]
        E8["GET /plan/:date"]
        E9["POST /plan/:date/replan"]
    end

    EX --- Endpoints
```

### Data flow — "Plan my day"

```mermaid
sequenceDiagram
    actor User
    participant App as iOS App
    participant API as Express API
    participant LLM as Claude API
    participant DB as SQLite

    User->>App: Tap "Plan my day"
    App->>API: POST /plan/today
    API->>DB: SELECT pending tasks
    API->>DB: SELECT constraints
    API->>LLM: tasks + constraints → structured JSON
    LLM-->>API: [{ label, start_time, end_time, type }]
    API->>DB: INSERT schedule
    API-->>App: DaySchedule JSON
    App->>App: Render TimelineView
    App->>App: Schedule local notifications
    App-->>User: Time-blocked calendar + alerts
```

---

## Project structure

```
SmartCal/
├── App/
│   └── SmartCalApp.swift        @main entry + TabView
├── Networking/
│   ├── APIClient.swift          Swift actor, one method per endpoint
│   └── Endpoints.swift          URL builders, HTTPMethod enum, APIError
├── Models/
│   ├── Task.swift               SCTask · NewTask · TaskPatch
│   ├── Constraint.swift         Constraints (wake/sleep/gym/lunch/deepwork)
│   └── Schedule.swift           ScheduleBlock · DaySchedule · BlockType
├── ViewModels/
│   ├── TaskViewModel.swift      @Observable — task CRUD
│   ├── ConstraintViewModel.swift @Observable — load + save constraints
│   └── PlanViewModel.swift      @Observable — plan/replan + notify
├── Views/
│   ├── Today/
│   │   ├── TodayView.swift      Action bar + empty/planning states
│   │   ├── TimelineView.swift   Vertical scroll, hour grid, time indicator
│   │   └── BlockView.swift      Single colored block
│   ├── Tasks/
│   │   ├── TasksView.swift      List, swipe-delete, skeleton loader
│   │   └── AddTaskView.swift    Sheet form (title/deadline/duration/priority)
│   ├── Settings/
│   │   └── SettingsView.swift   Time pickers, toggles, save toast
│   └── Shared/
│       └── ErrorBanner.swift    .errorBanner(message:) view modifier
└── Notifications/
    └── NotificationManager.swift Swift actor — local notif scheduling
```

---

## Running locally

1. Requires Xcode 16+ (iOS 17 deployment target)
2. Open `SmartCal.xcodeproj`
3. Select your team in **Signing & Capabilities**
4. Choose **iPhone 16 Simulator** → `Cmd+R`

The backend is live at `https://43.205.131.137.nip.io` — no local setup needed.

---

## Stack

| Layer | Technology |
|---|---|
| iOS app | SwiftUI · MVVM · async/await · URLSession |
| Notifications | UserNotifications (local, no server) |
| Backend | Node.js · TypeScript · Express · SQLite |
| AI scheduling | Claude API (structured JSON output) |
| Hosting | AWS EC2 t3.small · ap-south-1 |
| TLS | nip.io wildcard + Let's Encrypt |
