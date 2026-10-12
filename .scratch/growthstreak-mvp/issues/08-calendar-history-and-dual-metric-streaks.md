# 08: Calendar Month History & Dual-Metric Streak Tracking

**What to build:** The monthly calendar view and the dual-metric streak evaluation engine. Renders an interactive calendar displaying color-coded daily completion rings (green >= 70%, amber partial, red missed, blue excused). Computes and displays the active student streak using the dual metric: daily weighted completion score >= 70% AND zero unresolved/unpaid penalties.

**Blocked by:** 03: Hardware Step Counter Sensor & Auto-Completion, 07: Penalty Dues Ledger & Direct UPI Intent Settlement

**Status:** ready-for-agent

- [ ] Calendar screen displays month grid with custom day markers reflecting daily completion rings:
  - Green ring: $\ge$ 70% weighted completion.
  - Amber ring: > 0% and < 70% completion.
  - Red ring: 0% completion or finalized missed penalty task.
  - Blue ring: All incomplete tasks excused.
- [ ] Tapping a calendar date shows a breakdown of that day's completed and missed tasks.
- [ ] Streak calculation engine strictly enforces dual-metric rules:
  - Day qualifies to extend streak only if weighted completion $\ge$ 70%.
  - Any owed or unconfirmed penalty freezes the streak until resolved.
- [ ] Best streak and current streak are updated in the user profile and displayed prominently on Home and Profile screens.
