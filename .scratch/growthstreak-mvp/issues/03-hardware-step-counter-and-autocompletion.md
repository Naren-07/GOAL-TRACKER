# 03: Hardware Step Counter Sensor & Auto-Completion

**What to build:** Real-time hardware pedometer tracking using Android's physical step counter sensor. The app listens for step counts, tracks daily step deltas upon app resume against the user's daily goal, and automatically marks the "Daily Steps" task complete once the goal is reached.

**Blocked by:** 02: Daily Weighted Tasks & Completion Hero Ring

**Status:** completed

- [x] Android `ACTIVITY_RECOGNITION` permission requested with a clear explanatory dialog.
- [x] Hardware step counter stream listens for step updates via the device sensor.
- [x] Step deltas reset at midnight; daily total is preserved and displayed on the Home screen step widget.
- [x] When the daily step count reaches or exceeds the target goal (e.g. 8,000 steps), the "Daily Steps" task automatically toggles to completed.
- [x] Auto-completing the steps task immediately updates today's completion percentage ring on the Home screen.
