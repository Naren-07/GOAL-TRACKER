# 04: Friend Profile Linking & In-App Camera Proof Capture

**What to build:** Profile configuration for linking an accountability friend and the live in-app camera proof capture pipeline. The user links their friend's Name, WhatsApp phone number, and UPI VPA. When the user taps their daily "Gym" task, it opens a live in-app camera (gallery upload strictly disabled), applies a date/time watermark, checks image perceptual hash, and uploads the photo to Firebase Storage with a pending proof document.

**Blocked by:** 02: Daily Weighted Tasks & Completion Hero Ring

**Status:** ready-for-agent

- [ ] Profile screen allows entering and editing Accountability Friend details (Name, WhatsApp number with country code, and UPI VPA).
- [ ] Tapping the Gym task opens a dedicated in-app camera viewfinder; picking from gallery or camera roll is disabled.
- [ ] Captured photo preview shows an embedded date/time stamp watermark overlay.
- [ ] Photo is compressed to under 350 KB and uploaded to Firebase Storage under `proofs/{uid}/{proofId}.jpg`.
- [ ] A new `proofs/{id}` record is created in Firestore with status `pending`, a single-use token nonce, and an expiration timestamp set to 10:00 AM the following morning.
- [ ] Perceptual hash check prevents submitting the exact same photo multiple times.
