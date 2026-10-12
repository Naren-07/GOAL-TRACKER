# GrowthStreak: Product Requirements Document and Implementation Plan

## Version 2.0 (Post-Grill Refinement)

---

# PART A. PRODUCT REQUIREMENTS DOCUMENT

## A1. Overview

**Problem.** Engineering and college students set ambitious daily goals but struggle with consistency due to a lack of visual progress records, accountability fatigue, and zero real stakes for skipping workouts.

**Solution.** A lightweight habit tracker combining weighted daily percentage progress, category growth metrics, automatic hardware pedometer tracking, and friend-verified gym check-ins. If a verified task is missed and an excuse is not accepted by the friend, a ₹10 penalty is paid directly to the friend via UPI intent deeplink (`upi://pay?pa=...`). The app never custodies user funds, eliminating regulatory liability while retaining real peer accountability.

**Target User.** Engineering and college students aged 17 to 25.

**Success Metrics.** 
- $\ge$ 70% daily task completion rate.
- $\ge$ 90% of friend photo proofs decided within 2 hours of submission.
- Zero payment gateway failures or custodial wallet licensing risks.
- 30-day user retention above 45%.

---

## A2. Categories

| Category | Examples | Default Weight |
| :--- | :--- | :--- |
| **Health** | Gym (photo proof), Steps (sensor), Sleep, Water | 2 |
| **Academics** | Study hours, Assignments, Exam prep, Lectures | 1 |
| **Technical Skills** | DSA practice, Flutter/Dev, Certifications | 1 |
| **Custom** | Reading, Journaling, Meditation | User-defined |

*(Note: Long-term Project Portfolios with monthly updates are planned for Phase 2).*

---

## A3. Feature Scope (MVP vs. Phase 2)

| # | Feature | Verification Mechanism | Penalty Rule | Phase |
| :- | :--- | :--- | :--- | :- |
| 1 | **Daily Weighted Tasks** | Self-marked checkbox | Optional | **MVP** |
| 2 | **Standard & Custom Categories** | Self-marked checkbox | Optional | **MVP** |
| 3 | **Gym Check-in (Live Photo)** | Friend reviews via signed Web Link sent via WhatsApp | ₹10 default | **MVP** |
| 4 | **Missed-Day Excuse Flow** | Friend accepts/declines via Web Link | Cancelled if accepted; ₹10 if declined or silent | **MVP** |
| 5 | **Hardware Step Counter** | Device hardware sensor (`ACTIVITY_RECOGNITION`) on-resume | Optional | **MVP** |
| 6 | **Penalty Ledger & Direct UPI** | Direct UPI deeplink (`upi://pay?pa=...`) + Friend confirmation | ₹10 per missed verified task | **MVP** |
| 7 | **Streak & Day Rings** | Dual Metric ($\ge$ 70% completion & zero unpaid penalties) | N/A | **MVP** |
| 8 | **Projects with Monthly Updates** | Self-written milestone logs + image attachments | None | **Phase 2** |
| 9 | **Deep Multi-Year Analytics** | Aggregated week/month/year category trends | None | **Phase 2** |

---

## A4. Accountability Friend Architecture

Each student pairs with exactly one accountability friend.
- **Zero-Friction Inline Linking:** The user enters their friend's Name, WhatsApp Number (E.164), and UPI VPA (`friend@bank`) during profile setup.
- **No Upfront App Install or Opt-In Barrier:** The friend does not need to download the app or register in advance. When the student submits their first gym proof, the app creates a secure signed link (`https://growthstreak.app/verify/{proofId}?token=...`) and launches WhatsApp with a prefilled message. The web page introduces the friend to GrowthStreak and presents the workout photo with one-tap **Approve** and **Reject** buttons.
- **Friend Switching:** The friend can be updated once every 30 days in the profile settings. Pending proofs remain tied to the original friend until resolved or expired.

---

## A5. Core User Flows

### Flow 1: Gym Photo Proof & Friend Web Review
1. **Capture:** Student opens the Gym task and captures a photo using the live in-app camera (gallery upload is disabled).
2. **Metadata & Anti-Cheat:** App embeds date/time watermark, computes a perceptual image hash (to prevent re-uploading identical images), and uploads the compressed photo (~300 KB) to Firebase Storage.
3. **Dispatch:** A new `proofs/{id}` record is created with a single-use token nonce. The app opens WhatsApp via deeplink (`https://wa.me/{friendPhone}?text=...`) containing the verification link.
4. **Review:** The friend taps the link in WhatsApp, viewing the photo, capture timestamp, and student streak on a lightweight, mobile-optimized web page (<500ms load time).
5. **Decision:** Friend taps **Approve** or **Reject**:
   - **Approve:** Token is invalidated; Firestore marks the proof approved and completes the Gym task. The student's app updates in real-time.
   - **Reject:** Friend selects an optional reason (*"Not at gym"*, *"Old photo"*, *"Blurry"*). Student can retake up to 3 times per day.

### Flow 2: Missed-Day Reason (Excuse)
1. If the student cannot attend the gym, they tap **"Submit Reason"** (10 to 300 characters, optional category: illness, travel, exams).
2. The app generates an excuse review link sent to the friend via WhatsApp.
3. **Friend Decision:**
   - **Accept:** Penalty waived, task marked **Excused** (removed from daily weight calculation; streak preserved).
   - **Decline:** Task marked **Missed**, ₹10 penalty recorded in the student's dues ledger.
4. **Limits:** Maximum 3 accepted excuses per calendar month.

### Flow 3: Asymmetric Deadline Resolution Table
- **Daily Cutoff:** 11:59 PM local time.
- **Grace Deadline:** 10:00 AM the following morning.
- A Cloud Scheduler cron (`finalizeDay`) evaluates all pending tasks at 10:00 AM:

| Situation at 10:00 AM Grace Deadline | Penalty Incurred | Task Outcome | Streak Impact |
| :--- | :--- | :--- | :--- |
| **Gym photo approved by friend** | None | `completed` | Streak continues |
| **Gym photo submitted, friend never responded** | None *(Benefit of doubt)* | `auto_approved` | Streak continues |
| **Reason accepted by friend** | None | `excused` | Streak preserved |
| **Reason sent, friend never responded** | ₹10 owed | `missed` | Streak freezes until paid |
| **Reason declined by friend** | ₹10 owed | `missed` | Streak freezes until paid |
| **No photo and no reason submitted** | ₹10 owed | `missed` | Streak freezes until paid |
| **Steps goal reached** | None | `completed` | Streak continues |
| **Steps goal missed (with penalty enabled)** | ₹10 owed | `missed` | Streak freezes until paid |

### Flow 4: Penalty Settlement & Debt Clearance
1. When a task is finalized as `missed`, a `penalties/{id}` entry is created with status `owed`.
2. The student's streak freezes, and a banner appears: *"₹10 Penalty Due to [Friend Name]"*.
3. Tapping **"Pay Penalty"** launches the native UPI intent (`upi://pay?pa=friend_vpa&pn=FriendName&am=10&tn=GrowthStreak_Missed_Gym`).
4. Student completes payment in GPay / PhonePe / Paytm and returns to the app, tapping **"Marked Paid"**.
5. The friend receives a prompt on the web review page: *"Did [Name] pay you ₹10 via UPI? [Yes] [No]"*.
6. Once the friend confirms receipt, the penalty status updates to `confirmed`, and the student's streak unfreezes.

### Flow 5: Hardware Step Counter
- Uses the device's built-in step counter sensor via the `pedometer` package with `ACTIVITY_RECOGNITION`.
- Records step deltas when the app is opened or resumed.
- Step goals range from 1,000 to 50,000 (default 8,000). The step task automatically marks complete when the target is reached.
- Eliminates Google Play Health Connect policy declarations and battery-saver worker termination issues.

---

## A6. Screen Architecture

Bottom Navigation: **Home**, **Calendar**, **Tasks**, **Penalties (Dues)**, **Profile**.

1. **Home Screen:** Greeting, Circular Today's Completion Hero Card (% completed, current streak, fire icon), Quick Actions, Category Progress Tiles, Today's Task List with live checkboxes and photo submission buttons.
2. **Calendar Screen:** Monthly calendar grid with color rings (Green: $\ge$70%, Amber: partial, Red: missed, Blue: excused) and monthly average score.
3. **Tasks Screen:** Category-filtered list of recurring and single tasks, Add/Edit Task modal (Title, Category, Weight, Penalty toggle, Reminder time).
4. **Gym Proof Camera Screen:** Custom in-app camera view, preview with date/time watermark overlay, "Send to Friend via WhatsApp" action.
5. **Penalties (Dues) Screen:** Active penalty alert card, "Pay via UPI" button, history of settled penalties, friend's verified UPI VPA.
6. **Profile Screen:** Discipline score, total streaks, accountability friend card (edit friend details), Google account info.

---

# PART B. IMPLEMENTATION PLAN

## B1. System Architecture

```
Flutter Mobile App (Android)
       │
       ├── (Realtime sync & offline cache) ────────► Cloud Firestore
       ├── (Live photo upload) ────────────────────► Firebase Storage
       ├── (Launches WhatsApp deeplink) ───────────► WhatsApp Mobile Client
       └── (Direct UPI intent) ────────────────────► UPI Apps (GPay, PhonePe, Paytm)

Accountability Friend
       │
       └── (Taps link in WhatsApp) ────────────────► Firebase Hosting (HTML/JS Web App)
                                                            │
                                                            ▼
                                                    Cloud Functions (TypeScript)
                                                            │
                                                            ▼
                                                    Update Firestore Proofs/Penalties
```

---

## B2. Frontend Tech Stack (Flutter)

- **Architecture:** Feature-first structure (`lib/core`, `lib/features/{home, calendar, tasks, proofs, penalties, profile}`).
- **State Management:** Riverpod (`flutter_riverpod`).
- **Navigation:** `go_router`.
- **Firebase:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`.
- **Sensors & Hardware:** `camera`, `pedometer`, `permission_handler`.
- **UI & Charts:** `google_fonts` (Inter/Poppins), `flutter_animate`, `table_calendar`, `fl_chart`.
- **Payment & Linking:** `url_launcher` (for `upi://pay` intents and `wa.me` links).

---

## B3. Backend Services (Firebase)

| Service | Configuration | Purpose |
| :--- | :--- | :--- |
| **Firebase Auth** | Google Sign-In primary, Email fallback | Seamless student authentication with zero SMS costs |
| **Cloud Firestore** | Multi-region, offline cache enabled | Application state, tasks, day logs, proofs, penalties |
| **Firebase Storage** | Private bucket, image validation rules | Secure storage for gym proof photos |
| **Cloud Functions (2nd Gen)** | Node.js / TypeScript | Web verification endpoints, token validation, scheduling |
| **Cloud Scheduler** | Cron running every 15 minutes | `finalizeDay` evaluations at 10:00 AM grace cutoff |
| **Firebase Hosting** | Static HTML/CSS/JS + Cloud Function rewrites | Ultra-fast friend review web page (<500ms load time) |

### Cloud Functions Roster:
1. `getProofForReview` (HTTPS / Callable): Returns photo URL, student name, and timestamp if the single-use token is valid.
2. `submitProofDecision` (HTTPS): Idempotently records friend's Approve/Reject decision, invalidates token, and updates task outcome.
3. `submitExcuseDecision` (HTTPS): Records friend's Accept/Decline decision on an excuse.
4. `confirmPenaltyReceipt` (HTTPS): Records friend's Yes/No confirmation of UPI penalty receipt.
5. `finalizeDay` (Scheduler - every 15 mins): Applies asymmetric resolution to all day logs past 10:00 AM grace window.

---

## B4. Firestore Data Models

### `users/{uid}`
```typescript
{
  name: string,
  email: string,
  photoUrl?: string,
  whatsappPhone?: string,
  accountabilityFriend: {
    name: string,
    phoneE164: string,
    upiVpa: string, // e.g. naren@okhdfcbank
    firstProofViewed: boolean
  },
  stepGoal: number, // default 8000
  currentStreak: number,
  bestStreak: number,
  unresolvedPenaltiesCount: number,
  createdAt: Timestamp
}
```

### `users/{uid}/tasks/{taskId}`
```typescript
{
  id: string,
  title: string,
  category: "Health" | "Academics" | "Technical Skills" | "Custom",
  type: "standard" | "gym_photo" | "steps_auto",
  weight: number, // 1 to 10, default 1
  penaltyAmount: number, // default 10
  repeatDays: number[], // [1, 2, 3, 4, 5, 6, 7]
  reminderTime?: string, // "18:00"
  active: boolean,
  createdAt: Timestamp
}
```

### `users/{uid}/dayLogs/{yyyy-mm-dd}`
```typescript
{
  date: string,
  totalWeight: number,
  completedWeight: number,
  completionPercent: number,
  taskOutcomes: {
    [taskId: string]: {
      status: "pending" | "completed" | "excused" | "missed",
      proofId?: string,
      excuseId?: string,
      penaltyId?: string
    }
  },
  finalized: boolean,
  finalizedAt?: Timestamp
}
```

### `proofs/{proofId}`
```typescript
{
  id: string,
  uid: string,
  taskId: string,
  date: string,
  photoStoragePath: string,
  photoPerceptualHash: string,
  tokenNonce: string, // cryptographic single-use token
  status: "pending" | "approved" | "rejected" | "auto_approved" | "expired",
  rejectionReason?: string,
  submittedAt: Timestamp,
  decidedAt?: Timestamp,
  expiresAt: Timestamp // 10:00 AM next day
}
```

### `penalties/{penaltyId}`
```typescript
{
  id: string,
  uid: string,
  friendName: string,
  friendUpiVpa: string,
  taskId: string,
  date: string,
  amount: number, // default 10
  status: "owed" | "marked_paid" | "confirmed" | "disputed",
  upiIntentUrl: string,
  confirmationToken: string,
  incurredAt: Timestamp,
  markedPaidAt?: Timestamp,
  confirmedAt?: Timestamp
}
```

---

## B5. Security Rules

### Firestore Rules Summary
- Users can read and write only their own documents under `users/{uid}/**`.
- Clients can create proofs with status `pending`, but cannot update proof decisions or status directly (restricted to Cloud Functions).
- The `penalties/{penaltyId}` collection can only be written or transitioned to `confirmed` by Cloud Functions.
- Day logs are finalized exclusively by backend Cloud Functions.

### Storage Rules Summary
- Authenticated users can write only to `proofs/{uid}/{proofId}.jpg`.
- File size strictly limited to $\le 2$ MB. Content type restricted to `image/jpeg` or `image/png`.

---

## B6. Web Review Page Design (`/verify/{id}`)

The friend review page is delivered as a lightweight, responsive web card:
1. **Header:** GrowthStreak brand icon, student name (*"Naren's Workout Check-in"*), current streak badge.
2. **Media:** Full-width compressed photo with embedded timestamp watermark.
3. **Metadata Card:** Task title (*"Morning Chest & Triceps"*), capture time (*"Today, 7:15 AM"*), daily excuse counter.
4. **Primary Actions:**
   - Large Green Button: **"Approve Workout"** (marks task complete instantly).
   - Red Outline Button: **"Reject Photo"** (opens reason dropdown: *"Not at gym"*, *"Old photo"*, *"Blurry"*).
5. **Confirmation Feedback:** Instant celebration animation upon approval with a note: *"Thanks for keeping Naren accountable!"*.

---

## B7. Cost Breakdown (Near Zero Infrastructure)

| Service | Free Tier / Projected Cost |
| :--- | :--- |
| **Firebase Auth (Google)** | 100% Free (unlimited logins) |
| **Firestore & Storage** | Free within Firebase monthly quotas (~50k reads/day, 5 GB storage) |
| **Firebase Hosting** | Free (up to 10 GB/month) |
| **Cloud Functions & Scheduler** | Free tier on Blaze plan (2M invocations/month free) |
| **WhatsApp Delivery** | 100% Free (uses client-side `wa.me` deeplinks, zero Meta API charges) |
| **Payment Gateway** | 100% Free (direct UPI intent deeplinks incur zero gateway or payout fees) |
| **Total Monthly Cost at 500 Active Users** | **₹0 (Entirely within free tiers)** |

---

## B8. Delivery Roadmap (Streamlined 5-Week Plan)

- **Week 1: Foundations & Auth**
  - Flutter project setup, Emerald Design System theme tokens, Riverpod state container.
  - Firebase Auth with Google Sign-In.
  - Profile setup with friend details (Name, WhatsApp, UPI VPA).
- **Week 2: Daily Tasks & Step Counter**
  - Task CRUD with custom weights and categories.
  - Home screen Hero Card with dynamic daily completion circle.
  - Hardware pedometer integration (`pedometer` stream with on-resume delta sync).
- **Week 3: In-App Camera, Proofs & WhatsApp Deeplink**
  - Live in-app camera with date/time watermark and perceptual image hashing.
  - Firebase Storage upload and proof document creation.
  - WhatsApp deeplink generation with signed single-use verification URL.
- **Week 4: Web Review Page & Cloud Functions**
  - Static HTML/JS friend review page deployed to Firebase Hosting.
  - Cloud Functions for proof decision handling and token invalidation.
  - `finalizeDay` Cloud Scheduler cron implementing asymmetric resolution.
- **Week 5: Penalty Dues, UPI Intent & Polish**
  - Penalty dues screen with direct `upi://pay` deeplink.
  - Friend payment confirmation flow.
  - Streak freeze/unfreeze rules and end-to-end integration testing.
