# 05: WhatsApp Deeplink & Friend Web Review Page

**What to build:** The friend verification loop. After capturing a gym proof, the app presents a "Send to Friend" button that opens WhatsApp via deeplink (`https://wa.me/{friendPhone}?text=...`) containing a signed single-use verification URL (`https://growthstreak.app/verify/{proofId}?token=...`). The friend opens the link in their mobile browser (<500ms load time via Firebase Hosting & Cloud Functions), views the watermarked photo and student streak, and taps "Approve" or "Reject". Approving immediately updates the proof in Firestore and completes the Gym task in real-time in the student's app.

**Blocked by:** 04: Friend Profile Linking & In-App Camera Proof Capture

**Status:** ready-for-agent

- [ ] Tapping "Send Proof" launches WhatsApp with a prefilled message addressed to the friend containing the secure verification link.
- [ ] Friend review web page is served via Firebase Hosting with an ultra-lightweight mobile layout that loads in under 500ms.
- [ ] Opening the review page verifies the cryptographic token nonce; expired or previously decided tokens show a clean status card.
- [ ] Friend sees the student's name, current streak, capture timestamp, and the full-resolution compressed photo.
- [ ] Tapping "Approve" invalidates the token, transitions the proof to `approved` in Firestore, and shows a celebratory confirmation screen.
- [ ] Tapping "Reject" allows picking an optional reason (*"Not at gym"*, *"Old photo"*, *"Blurry"*) and marks the proof `rejected`.
- [ ] Approval immediately completes the Gym task in the student's app via real-time Firestore snapshot listeners without needing to refresh.
