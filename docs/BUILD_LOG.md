# BUILD LOG

**Date:** 2026-06-30

---

## Focus Today
- [X] HealthKit / Health Connect sleep sync integration

---

## Milestones Completed (high-level only; keep section short and sweet)
- Core sleep logging: manual entry (duration, stages, times, quality, notes), derived sleep score, sleep efficiency (incl. sleep latency), time-to-fall-asleep
- Sleep dashboard: sleep score chart, sleep-stage bar chart, sleep consistency chart across 7d/4w/3m/1y windows with circular-mean bucket aggregation
- Dream journaling: multi-dream entry modal, genre tagging, sentiment analysis, recall rating
- Home screen: sleep summary card, recent dreams, daily "did you dream?" prompt, quote of the day, weekly stats
- Firebase Auth + Firestore backend; dark/light theme toggle; ChatSLEEPT screen
- HealthKit / Health Connect sleep import — Android Health Connect live end-to-end, iOS HealthKit config written pending Mac verification (2026-06-30)

---

## What We Accomplished Today
- Implemented HealthKit (iOS) + Health Connect (Android) sleep sync via the `health` package, built and verified end-to-end on Android:
  - Added `health: ^13.3.1`; bumped Android `minSdk` 23→26, `compileSdk` 35→36, `targetSdk` 33→34, AGP 8.7.0→8.9.1, Gradle 8.10.2→8.13 (all required by Health Connect's native dependency — found via real build failures, not guessed upfront)
  - `AndroidManifest.xml`: `READ_SLEEP` permission, Health Connect rationale activity-alias, `<queries>` entries; `MainActivity.kt` switched `FlutterActivity` → `FlutterFragmentActivity` (required for the Android 14+ permission flow)
  - New `lib/services/health_sync_service.dart`: authorization, fetch, gap-based nightly-session clustering, stage→duration/time-string conversion matching the existing manual-entry format exactly
  - `lib/firestore_service.dart`: refactored `saveSleepLogAuto` into a shared `_buildSleepLogData` helper; added `saveSleepLogFromHealth` with deterministic doc IDs (`uid_yyyyMMdd_health`) written via merge, so repeat syncs of the same night overwrite instead of duplicating; tagged all `sleep_logs` writes with `source: 'manual'|'health'`
  - `lib/screens/settings_screen.dart` + `lib/home_screen.dart`: "Sync with Health App" toggle, "Sync Now" button, silent once-daily auto-sync mirroring the existing daily-dream-prompt pattern
  - iOS: `Info.plist` usage descriptions, new `Runner.entitlements`, `CODE_SIGN_ENTITLEMENTS` wired into all 3 Runner build configs in `project.pbxproj` — **written but unverified, needs an actual Xcode/Mac pass** (no Mac available on this dev machine)
  - **Live-verified on an Android 16 emulator**: real login → Settings toggle → native Health Connect onboarding → permission grant (correctly scoped to Sleep only, confirming manifest scoping) → graceful "No new sleep data found." result, no crashes, clean logcat. "Sync Now" verified too.
- Replaced `PLANNER.md` with this `BUILD_LOG.md` / `BUILD_LOG_TEMPLATE.md` system, mirrored from Hedgecraft's setup.
- Where we left off: Android side works end-to-end but hasn't actually imported real data yet — the emulator has no seeded Health Connect sleep records, so only the empty-result path has been exercised. iOS side is config-only and unverified.

---

## Tomorrow
- [ ] Verify iOS HealthKit config on an actual Mac (Xcode build, on-device permission prompt, confirm a real import works)
- [ ] Seed real sleep data in Health Connect and confirm an end-to-end import produces a sane `sleep_logs` doc (not just the "no data found" path)
- [ ] Fix previous change percentage metric
- [ ] Add metrics beneath sleep stage chart
- [ ] Add metrics beneath sleep consistency chart
- [ ] Update Home, Me, and Dream windows with o4-mini-high
- [ ] Come up with clear Mission statement and Target Demographic
- [ ] Add recommendations on home screen
- [ ] Email app developers and ask quality questions
- [ ] Email dream doctors and ask them about their favorite sleep metrics, the best sleep data, and what they don't currently see in most sleep apps that would be valuable. Also ask how they would calculate sleep score.

---

## Backlog
- Shareable option to other social medias — ability to export post/log as a picture so the user can share on other social media platforms and increase REM exposure
- Update loading screen when launching app — instead of Flutter logo, have REM logo
- Make logo appear on loading screen instead of Flutter icon
- Update DREAM GENRES: take away normal, add movie genres: Action, Comedy, Romance, Thriller, Drama, Sci-Fi, Horror, etc. Add custom dream genre options where user can add custom genres with correlating color. Max at 3 custom genres.
- Track moods, how well the user thinks they recovered/slept before glancing at statistics, whether the user woke up in the middle of the night to pee, etc. (use Whoop journal for ideas)
- Brainstorm ideas for the UI/look of the app
- Have a way to store characters that people mention in their dreams so AI and readers of dreams know who you dreamed about
- Update dream logs to include ChatSLEEPT for image creation of dreams
- Build a Docker image/workflow that produces a ready-to-install APK (build artifact, not just the dev-env Dockerfile) — goal is to get hands-on Docker experience; e.g. COPY app source into image, run `flutter build apk`, output APK via volume mount or multi-stage build

## Note
- Review BUILD_LOG_TEMPLATE.md before updating
