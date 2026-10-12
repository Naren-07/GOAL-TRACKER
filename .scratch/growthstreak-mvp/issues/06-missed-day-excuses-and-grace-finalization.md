# 06: Missed-Day Excuse Flow & Morning Grace Auto-Finalize

**What to build:** The excuse submission workflow and backend asymmetric resolution cron. If a student cannot attend the gym, they can submit an excuse note (capped at 3 per calendar month) before midnight, generating a web review link for the friend. A Cloud Scheduler cron (`finalizeDay`) triggers at the 10:00 AM grace cutoff to apply asymmetric resolution: unreviewed photo proofs auto-approve, while unreviewed or declined excuses finalize as `missed` and log an owed ₹10 penalty.

**Blocked by:** 05: WhatsApp Deeplink & Friend Web Review Page

**Status:** ready-for-agent

- [ ] Student can tap "Submit Reason" on the Gym task before 11:59 PM to enter an excuse note (10 to 300 characters, optional category: illness, travel, exams).
- [ ] Enforces a hard monthly cap of maximum 3 accepted excuses per user per calendar month.
- [ ] Friend review web page supports reviewing excuses with one-tap "Accept" and "Decline" buttons.
- [ ] Accepted excuse marks task outcome `excused`, removes it from the daily weight calculation, and preserves the streak.
- [ ] Backend Cloud Function `finalizeDay` (triggered by Cloud Scheduler every 15 minutes) processes day logs past 10:00 AM grace cutoff.
- [ ] Implements asymmetric resolution:
  - If a photo proof is still pending at 10:00 AM, it is marked `auto_approved` and the task is completed without penalty.
  - If an excuse is still pending at 10:00 AM, it is marked `missed` and an owed ₹10 penalty is recorded.
  - If neither photo nor excuse was submitted, the task is marked `missed` with ₹10 penalty owed.
