# 01: Project Foundation, Emerald Theme & Google Auth Spike

**What to build:** A runnable Flutter mobile application configured with the Emerald design system color palette and typography, integrated Firebase Auth via Google Sign-In, and an initial onboarding step where a student signs in, confirms their profile name and daily step goal, and persists their user profile to Firestore.

**Blocked by:** None (can start immediately)

**Status:** completed

- [x] Flutter Android app runs clean with Flutter 3.x and Material 3 design tokens (#0B5D45 deep emerald brand color, #F5F9F7 background, Inter/Poppins font).
- [x] Google Sign-In authenticates via Firebase Auth on Android with seamless session persistence.
- [x] First-time sign-in presents a simple profile onboarding screen asking for the student's name and step goal (default 8,000).
- [x] Profile document successfully writes to `users/{uid}` in Cloud Firestore.
- [x] User remains signed in across app cold restarts.
