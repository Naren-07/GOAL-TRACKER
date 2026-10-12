# 02: Daily Weighted Tasks & Completion Hero Ring

**What to build:** The core daily task engine. Students can create, edit, and toggle daily recurring tasks with custom categories (Health, Academics, Technical Skills, Custom) and weights (1 to 10). The home screen dynamically computes and renders today's percentage completion circle and persists daily task states with offline Firestore support.

**Blocked by:** 01: Project Foundation, Emerald Theme & Google Auth Spike

**Status:** completed

- [x] Students can create tasks with title, category, repeat schedule (daily/weekdays), and weight (1-10, default 1).
- [x] Today's task list renders on the Home screen with instant checkbox toggles.
- [x] Toggling a task updates today's completion percentage in real time: `completedWeight / totalWeight * 100`.
- [x] Hero Card on the Home screen animates the circular progress ring and displays the current percentage score.
- [x] Task outcomes persist to `users/{uid}/dayLogs/{date}` with Firestore offline persistence enabled (works when airplane mode is on and syncs when back online).
