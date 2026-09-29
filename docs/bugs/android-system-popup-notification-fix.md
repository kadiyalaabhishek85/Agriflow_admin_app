# Final Report — AgriFlow Admin/Manager: Android System Popup Notification Fix

> **Task:** Dynamic Android popup notifications driven by real backend SSE events
> (not just the in-app list/badge), with permission handling, deep-link tap routing,
> tests, and a strict no-go gate.
>
> **Evidence convention used throughout:**
> `AUTOMATED VERIFIED` = proven by analyzer/unit/widget tests/build in this workspace ·
> `REAL BACKEND VERIFIED` = proven against `https://agriflow-backend-t8o4.onrender.com` ·
> `BLOCKED - DEVICE VERIFICATION` = could not be performed (no adb device/emulator).

---

## 1. Root cause of the missing popup — AUTOMATED VERIFIED

The app had **no Android notification machinery at all**:

- `pubspec.yaml` contained no notification plugin (no `flutter_local_notifications`,
  no FCM, no `permission_handler` for notifications) — `grep` across the repo found
  zero notification-plugin invocations.
- `GeneratedPluginRegistrant` registered no notification plugin (build output before
  this fix).
- The only reaction to a real backend `notification.created` SSE event was
  `NotificationController._onStreamEvent`: insert the row into the in-app list and
  `refresh()` the badge count.

Therefore every backend event **was** received (SSE is live and correct) but was
converted into **in-app state only** — never into an OS-level notification. There is
no code path from SSE frame → system notification, which is the root cause.

## 2. Was the existing implementation in-app only? — AUTOMATED VERIFIED

**Yes.** In-app only:

- Notification rows + unread badge dot: `admin_shell.dart:334` (unread count from
  `NotificationController.unreadCount`), `manager_shell.dart` equivalent.
- No channel, no permission, no `show()` call, no payload→system bridge anywhere
  (zero grep matches for plugin APIs before this change).

## 3. Are system notifications now implemented? — AUTOMATED VERIFIED

**Yes.** New layer:

- `lib/features/notifications/presentation/services/system_notification_service.dart`
  (NEW) — `SystemNotificationService` interface + `NoopSystemNotificationService`
  (tests/unsupported platforms) + `LocalSystemNotificationService` (real plugin):
  - Channel `agriflow_business_events`, `Importance.high`, big-text style,
    auto-cancel, `@mipmap/ic_launcher` icon, per-type accent color.
  - Stable int id via FNV-1a hash of the notification uuid (dedupe across pushes).
  - **Payload = the real notification uuid** from the SSE frame — nothing parsed
    from message text, no invented `reference_id`/`reference_type`.
  - All methods wrapped in try/catch so an unavailable platform channel (tests,
    permission denied, wrong platform) can never break feed ingestion.
- Trigger — `notification_controller.dart:126-133`: popup fires **only** on the
  `notification.created` insert branch, guarded by `_presentedPopupIds` (per-id dedupe).
  Polling refresh, resume refresh, and `dashboard.changed` never call `show()`, so
  they cannot duplicate a popup; duplicate SSE frames are no-ops (`:137`).
- Both shells construct the service (`admin_shell.dart:136-143`,
  `manager_shell.dart:138-145`), initialize it, and pass it into the controller
  (`admin_shell.dart:227`, `manager_shell.dart:229`) — real service by default,
  injectable fake in tests.

**Content is 100% backend-driven** — title/message/type come verbatim from the live
`notification.created` payload (widget-verified in the popup test below). No fake,
timer, or hardcoded notifications exist anywhere.

## 4. Permission status — partially verified

- **Manifest:** `android.permission.POST_NOTIFICATIONS` added to
  `AndroidManifest.xml` — confirmed present in the **merged debug manifest**
  (AUTOMATED VERIFIED, `build/app/intermediates/merged_manifests/debug/...`).
- **Runtime flow (implemented):** `ensurePermissionRequested()` sets a
  `SharedPreferences` flag *before* a single `requestNotificationsPermission()` —
  one prompt ever; if previously denied, the app never nags again
  (AUTOMATED VERIFIED via SharedPreferences-mock + real-service widget test).
- **Actual grant/deny state on a device:** **BLOCKED - DEVICE VERIFICATION**
  (no adb device). Reference observation: a prior screenshot of the real device
  showed notifications **toggled OFF** for `agriflow_admin` — treated as a real
  device-state observation (the user's control), not a defect; if the toggle is off,
  the OS suppresses popups while the in-app feed continues to work.
- **Sufficiency for the popup path (Android 13+):** required permission is
  POST_NOTIFICATIONS (declared + requested). **Not required** for this fix:
  SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM (no scheduled notifications),
  FOREGROUND_SERVICE (no background service added), POST_WAKE_LOCK (nothing kept
  awake) — these are intentionally absent, not missing.

## 5. Foreground behavior — implemented, AUTOMATED VERIFIED (device unverified)

App open, process alive → SSE connected → `notification.created` frame →
in-app row + **system popup with real payload** (deduped per id).
Unit/widget-proven: popup shown exactly once for a real SSE frame; polling/resume/
duplicate frames/`dashboard.changed` never re-show.

## 6. Background behavior (app backgrounded, process alive) — conditional

SSE socket stays alive only while Android keeps the process running — **no foreground
service was added** (spec: do not claim background support unless implemented; a
foreground service would need a persistent notification of its own and its own design
decision). Consequence: popups continue while the socket is alive, then stop when the
OS suspends/kills the connection (Doze, minutes-to-hours, device-dependent).
**Honest status: works while the process keeps the SSE connection; not guaranteed;
NOT device-verified.**

## 7. Terminated behavior — BLOCKED: BACKEND/ARCHITECTURE DEPENDENCY

With the app force-stopped, no process exists → no SSE → **client cannot show a
popup**. The delivery mechanism for terminated apps is FCM push. Audit of the live
OpenAPI (REAL BACKEND VERIFIED): Admin/Manager endpoints exist for
`POST /auth/fcm-token`-style flows **only for the Farmer role** — there is **no
`POST /fcm-token` for Admin/Manager** in the live spec, and no server key/config is
in scope. **Required mechanism: FCM push delivery to Admin/Manager — backend work to
be supplied by Syed.** Per spec: FCM was NOT added speculatively; SSE was NOT
replaced; this limitation is documented rather than papered over.

**Cold-start (terminated → launched BY tapping a system notification):** handled
client-side — `getNotificationAppLaunchDetails()` → pending uuid → resolved after
session/shell restoration (`admin_shell.dart:248-250`, `:265-267`;
widget-tested: launch id → `SeedPurchaseScreen`).

## 8. Admin & Manager behavior — AUTOMATED VERIFIED

Both roles get identical popup machinery (both shells own their
`_systemNotifications`, permission flow, and tap resolver). Routing is role-safe:

- **Phase 15 audit (REAL BACKEND VERIFIED):** `GET /api/v1/notifications` REST
  returns `reference_type` + `reference_id`; distinct live types observed:
  `bank_change_request, booking_slot, farm_visit, grain_sale, seed_purchase,
  transaction`. SSE does **not** carry reference fields — routing uses the canonical
  REST item fetched by id, never parsed from message text.
- Route map (`NotificationDestinationResolver`): seed_purchase→`seed-purchase`,
  booking_slot→`booking-slot`, farm_visit→`farm-visits`, grain_sale→`grain-sales`,
  transaction→`billing`, bank_change_request→`all-farmers`; unknown/missing →
  `notifications` screen. **Every mapped route is `adminOnly: false`** — verified
  for all six types, so a Manager can never be sent to an admin-only screen.
- Navigation is **route-level only** (no screen accepts a record-id param; no
  bank-change screen exists) — the app never pretends to open an exact record.
- In-app detail sheet gained an explicit "Open <Module>" action
  (`notification_screen.dart:388`) that routes through the same bridge; unmapped
  references show no misleading button (widget-tested).

## 9. Backend event evidence — REAL BACKEND VERIFIED

Backend emits real `notification.created` events created by real user actions
(e.g., seed purchase create → notification row with `reference_type=seed_purchase`);
REST `GET /api/v1/notifications` supplies the canonical list with
`reference_type`/`reference_id` (400-row sample; 6 distinct types listed above).
Recipient targeting verified for **both** roles (super_admin login + manager login
`7777777799`, 77 notifications returned).

## 10. SSE evidence — REAL BACKEND VERIFIED

`GET /events/ticket` → 200, then SSE frames parsed from the live stream (both roles);
`notification.created` frames carry exactly `{id,title,message,type}` — no reference
fields (that is why routing goes through REST). Original investigation also proved
multi-day reconnect/backoff behavior and measured real-time latency.

## 11. Token-refresh evidence — REAL BACKEND VERIFIED (prior investigation)

`ApiClient` dependency-injected into both shells with `onSessionExpired→logout`;
401 → `POST /auth/refresh` → retry of the original request → 200 (live-verified);
rotation safe. SSE ticket re-fetch rides the same retry, so a mid-session token
expiry cannot silently kill the popup path.

## 12. Files changed — AUTOMATED VERIFIED

| File | Change |
|---|---|
| `pubspec.yaml` | + `flutter_local_notifications: ^22.3.1` |
| `pubspec.lock` | lockfile update (plugin + transitive platform impls) |
| `lib/features/notifications/presentation/services/system_notification_service.dart` | **NEW** — resolver, tap bridge, abstract/noop/real services |
| `lib/features/notifications/presentation/controllers/notification_controller.dart` | `systemNotifications` param; popup on SSE insert only; `_presentedPopupIds` dedupe (`:37,:47,:126-133`) |
| `lib/features/admin/presentation/admin_shell.dart` | service init + permission + launch-id + tap resolution (`:90,:129-143,:227,:236-280`) |
| `lib/features/manager/presentation/manager_shell.dart` | same for Manager (`:91,:131-145,:229,:246-290`) |
| `lib/features/notifications/presentation/screens/notification_screen.dart` | "Open <Module>" sheet action → bridge (`:374,:388,:417`) |
| `android/app/src/main/AndroidManifest.xml` | + `POST_NOTIFICATIONS` |
| `android/app/build.gradle.kts` | core-library desugaring (plugin requirement) |
| `test/features/notifications/system_notification_test.dart` | **NEW** — 10 tests (Phase 13) |

## 13. Dependencies changed — AUTOMATED VERIFIED

- Added: `flutter_local_notifications 22.3.1` (direct) + transitive
  `_linux/_windows/_web/_platform_interface` (pubspec.lock confirmed).
- Added (Android, per plugin docs): `com.android.tools:desugar_jdk_libs:2.1.4`
  with `isCoreLibraryDesugaringEnabled = true`.
- **Not added (and why):** FCM (`firebase_core`/`firebase_messaging`) — spec forbids
  adding it speculatively; no backend Admin/Manager token endpoint exists.
  `permission_handler` — unnecessary; the plugin exposes
  `requestNotificationsPermission()` natively.

## 14. Backend changes — **0**

No backend file was touched. No endpoint invented or modified.

## 15. Database changes — **0**

No migration, schema, or model-layer DB change.

## 16. Test result — AUTOMATED VERIFIED

**`flutter test` → 553/553 passed** (543 baseline preserved, zero regressions,
+ 10 new tests). New coverage (`system_notification_test.dart`):
1. all six live reference types → expected routes; 2. unknown/null → Notifications
fallback; 3. role-safety (all mapped routes non-admin-only, parity Admin/Manager);
4. SSE frame → exactly one popup with real payload; polling/resume/duplicate/
`dashboard.changed` → no re-show; badge updated; 5. permission-off/unsupported
platform: real service never throws, feed ingestion unaffected; 6. Admin tap →
`SeedPurchaseScreen` + bridge cleared; 7. Manager tap → `BookingSlotScreen`;
8. unknown id → Notifications fallback (never an arbitrary record); 9. cold-start
launch id → module; 10. detail-sheet Open action (mapped) / none (unmapped).

## 17. Analyze result — AUTOMATED VERIFIED

`flutter analyze --no-pub` → **No issues found** (11.7s).

## 18. APK result — AUTOMATED VERIFIED

`flutter build apk --debug` → **√ Built `build\app\outputs\flutter-apk\app-debug.apk`**
(139.8s). Desugaring configured, merged manifest contains POST_NOTIFICATIONS,
`.flutter-plugins-dependencies` lists `flutter_local_notifications`.
(Pre-existing, unrelated warning: `flutter_file_dialog` applies Kotlin Gradle Plugin
— present before this task.)

## 19. Device test T0–T10 — **BLOCKED - DEVICE VERIFICATION**

`adb devices` → *List of devices attached* (empty); `adb devices -l` empty;
`flutter emulators` → no AVD images installed. Per the spec's no-go rule, execution
**stopped at implementation + audit** and this report is emitted instead.
T0–T10 on-device checklist (to run when a device is attached):
T0 install APK · T1 grant prompt appears once · T2 fg popup on real backend event ·
T3 popup content == backend payload · T4 badge + row both update ·
T5 duplicate event → single popup · T6 bg (process alive) popup ·
T7 deny/OS-off → no crash, feed works · T8 tap → correct module (Admin) ·
T9 tap → correct module (Manager) · T10 cold-start tap → module after login.
**No popup on a real device has been claimed or demonstrated.**

## 20. Behavior matrix (Phase 2)

| App state | SSE alive? | System popup? | Evidence |
|---|---|---|---|
| Foreground | Yes | **Yes** (implemented; real payload, deduped) | AUTOMATED VERIFIED (device pending) |
| Backgrounded, process alive | While OS keeps it | Yes, then stops when socket dies — no foreground service, Doze-bounded | Code-audited; **not device-verified** |
| Terminated | No | **No — impossible client-side** | BLOCKED: backend dependency (FCM) |
| Permission denied / toggle off | Yes | No (OS suppresses); in-app feed unaffected | AUTOMATED VERIFIED (service) + device state unknown |
| Tap (any state, cold start included) | n/a | Deep-link → module route; fallback Notifications screen | AUTOMATED VERIFIED (5 widget tests) |

## 21. Phase 3 determination — SSE sufficiency

SSE **is sufficient** for foreground and best-effort background popups while the
process lives. SSE is **not sufficient** for terminated-app delivery — the required
mechanism (FCM push to Admin/Manager) does not exist in the live OpenAPI and must be
supplied by the backend lead. No SSE data was extended or fabricated to compensate.

## 22. Limitations & final gate

**Limitations:**
1. No real-device or emulator verification of any popup behavior (no adb target).
2. Terminated-app delivery out of client reach — needs backend FCM for Admin/Manager.
3. Background delivery is process-lifetime bounded (no foreground service by design).
4. Runtime permission grant state on the actual device unknown (screenshot showed
   the OS toggle OFF for `agriflow_admin`).
5. Deep-links are module-level (no screen accepts a record id; no bank-change UI).
6. Pre-existing `flutter_file_dialog` KGP deprecation warning (unrelated, untouched).

**Separation statement:** every claim above is tagged AUTOMATED VERIFIED,
REAL BACKEND VERIFIED, or BLOCKED — DEVICE VERIFICATION. Nothing is claimed as
device-proven.

---

## ? GATE: `BLOCKED - DEVICE VERIFICATION`

Implementation (popup service, dedupe, permission flow, deep-links, Android
wiring) is complete and fully proven by analyzer + 553/553 tests + debug APK build;
backend/dependency invariants hold (backend changes = 0, DB changes = 0, SSE
preserved, no fabricated data, no speculative FCM). The gate cannot open because
T0–T10 require a connected device/emulator, none exists in this environment, and
terminated-app delivery additionally carries a
`BLOCKED - BACKEND/ARCHITECTURE DEPENDENCY` (FCM for Admin/Manager).
**Ready for human approval of the implementation; device verification and the
backend FCM dependency remain open follow-ups.**
