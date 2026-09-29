# Bug Report — Admin/Manager Notifications Not Dynamic

**Investigation:** 17-phase root-cause process (strict gate rules applied)
**Date:** 2026-09-28
**Verdict:** `BLOCKED — DEVICE VERIFICATION`

> All sections below separate evidence into:
> **AUTOMATED VERIFIED** (local tests/analyze/build) · **REAL BACKEND VERIFIED**
> (measured against `https://agriflow-backend-t8o4.onrender.com`) ·
> **REAL DEVICE VERIFIED** (adb/emulator) · **BACKEND DEPENDENCY** (pending Syed / credentials).

---

## 1. Baseline — AUTOMATED VERIFIED

- `flutter analyze` → **No issues found** (before any change).
- `flutter test` → **528/528 passing** (before any change).
- Symptom under investigation: badge/list appeared static; no real-time updates;
  reports of the notification feed silently freezing.

## 2. Flow trace (app side) — AUTOMATED VERIFIED

`lib/features/admin/presentation/admin_shell.dart` / `lib/features/manager/presentation/manager_shell.dart`:

- `initState()` builds `NotificationController` with
  `FastApiNotificationRemoteDataSource()` and **`widget.session.accessToken`** —
  a token captured **once at shell startup** and stored in a final field.
- `startPolling()` → immediate `refresh()` + `Timer.periodic(30s)`.
- Badge (`SquircleIconButton.hasBadge`) and screen are correctly wired via
  `ListenableBuilder` → `hasUnreadNotifications` / `unreadCount` (dot-only, no count).
- `refresh()` swallows background errors silently (only first-load sets `_error`).
- **No** `WidgetsBindingObserver` anywhere → no refresh on app resume.
- **No** consumer of `GET /api/v1/events/stream` anywhere in `lib/`
  (`getStreamTicket` was dead code before this fix).
- `ApiClient` (`lib/core/network/api_client.dart`) existed but was **never
  instantiated anywhere** — all features used raw `http.Client` + static token.

## 3. Live OpenAPI — REAL BACKEND VERIFIED

- `GET /api/v1/openapi.json` fetched live; notification contracts confirmed:
  - `GET /api/v1/notifications` (page/page_size/sort/order),
  - `PATCH /api/v1/notifications/{id}/read`, `PATCH /api/v1/notifications/read-all`,
  - `POST /api/v1/events/ticket`, `GET /api/v1/events/stream`.
- No Admin/Manager FCM endpoints exist (unlike Farmer). Their real-time channel is SSE.

## 4. Farmer mechanism — REAL BACKEND VERIFIED (no source in workspace)

Farmer app (separate codebase; only UI mockups here) uses:
`/api/v1/farmer/notifications`, `/unread-count`, `POST /fcm-token`, `POST /test-fcm`
→ **FCM push + polling**. Admin/Manager have **no** fcm-token endpoint → SSE is the
designed real-time channel for them.

## 5. Backend notification creation — REAL BACKEND VERIFIED

- `GET /api/v1/notifications` as super admin → **182+ rows**, business-event titles,
  org-wide feed (observed events created by user "Asha"; super-admin name "Super Admin").
- Live event test: `POST /seed-purchases` (201, id `31ad0a50`) → backend created
  notification `99349a0a` "Seed purchase submitted" at `08:57:01.682929Z`
  (stock deducted 3192→3191).
- `POST /market-rates` does **not** create notifications (90s watch) — no such type exists.
- **Conclusion: backend creates notifications correctly. Root cause A eliminated.**

## 6. Recipient targeting — REAL BACKEND VERIFIED (both roles)

- **Admin: verified** — org-wide feed contains the events of §5.
- **Manager: verified live (2026-09-28, credentials `7777777799`)**:
  - `POST /auth/login` → role `manager`.
  - `GET /api/v1/notifications?page=1` → **200, 77 notifications**
    (envelope `{success, data, pagination}`; app parses `data` — compatible),
    business events on page 1: *New warehouse booking*, *Crop scan awaiting review*,
    *New bank change request*, all `is_read: false` (10/10 unread → badge state).
  - `POST /api/v1/events/ticket` → **200** for the manager role
    (ticket present, `expires_in: 30`) — manager's real-time channel is live.

## 7. Polling audit — AUTOMATED VERIFIED

| Defect | Evidence |
|---|---|
| Static token captured at shell initState | `admin_shell.dart` / `manager_shell.dart` construction |
| Silent error swallow after first load | `refresh()` catch: error set only `if (isFirstLoad)` |
| No refresh on app resume | no `didChangeAppLifecycleState` in repo |
| No 401 handling on notification calls | raw `http.Client`, no retry/refresh |

## 8. Real-time latency (measured) — REAL BACKEND VERIFIED

- Backend push (SSE `notification.created`): **4.4 s** after the triggering event.
- REST first-seen of same row: **9.7 s** (in that run).
- App: **0 s real-time capability** — 30 s poll only, and permanently 0 after token death.
- Farmer parity: FCM push exists for farmers; Admin/Manager equivalent = SSE.

## 9. SSE contract — REAL BACKEND VERIFIED

- `POST /api/v1/events/ticket` → 200, `{data: {ticket, expires_in: 30}}`, single-use,
  Authorization required.
- `GET /api/v1/events/stream?ticket=...` → `Content-Type: text/event-stream`,
  `: connected`, `: keepalive` ~every 20 s, frames:
  - `event: notification.created` — payload: `id/title/message/type` only
    (**no** `is_read`/`created_at`/reference fields),
  - `event: dashboard.changed` — `{"reason": "seed_purchase.create" | "document.upload"}`.
- **No Authorization header** on the stream itself — the ticket is the credential.
- Refresh endpoint (fix dependency): `POST /auth/refresh` with `{"refresh_token"}` →
  200, returns `access_token` + `refresh_token` + `user`; **rotated refresh token
  works** (second refresh → 200); retry with rotated access token → 200.
  **Refresh flow verified live end-to-end (2026-09-28).**

## 10. Root cause classification — REAL BACKEND VERIFIED

Classification from the A–Q taxonomy: **D + H + M + F** (all proven; others eliminated).

| # | Finding | Proof |
|---|---|---|
| **D/H** | Static startup token; JWT `exp = iat + 900 s` | Probe: t=0/10/13 min → **HTTP 200**; **t=15/16/18/20 min → HTTP 401** `UNAUTHORIZED Invalid or expired token`. Background refresh errors swallowed → **permanent silent freeze after 15 min.** |
| **M** | SSE never consumed | `getStreamTicket` had zero presentation-layer callers; backend SSE proven working |
| **F** | No lifecycle resume handling | no observer anywhere → no catch-up on foreground |

Eliminated: **A** (backend creates — §5), **C** (GET returns them — §5),
**I/J/K/L** (badge/listener wiring works — §2), **N/O** (backend SSE correct — §9),
**P** (parsing matches contract — §9).

## 11. Smallest fix — AUTOMATED VERIFIED (user-approved scope: token + resume + SSE)

1. **Token freshness** — `notification_remote_data_source.dart` rewritten to dual-mode:
   optional `ApiClient` (fresh token read from storage per request; on 401 → silent
   refresh → single retry; on refresh failure → clear session + logout callback).
   Legacy static-token path preserved when no `ApiClient` is injected (tests/showcase).
2. **DI wiring** — `main.dart` → `AgriFlowApp(localDataSource)` → `AuthRouter` builds
   `ApiClient(onSessionExpired: logout)` → passed into `AdminShell`/`ManagerShell`.
3. **Resume** — both shells are now `WidgetsBindingObserver`s:
   `didChangeAppLifecycleState(resumed)` → `handleAppResumed()` → immediate refresh +
   SSE reconnect.
4. **Real-time** — new `lib/features/notifications/data/sse/notification_event_stream.dart`:
   `SseFrameParser` (pure incremental parser) + `NotificationEventStream`
   (ticket → stream → auto-reconnect with capped backoff; epoch-guarded; stop/dispose-safe).
   Controller subscribes: `notification.created` → insert-if-unseen (synthesizing
   `is_read:false`/`created_at` since SSE payload omits them) + canonical refresh;
   duplicate frames are no-ops; `dashboard.changed` → refresh.
5. **30 s polling retained** as fallback.
6. No fake/hardcoded/timer-simulated notifications; no token values logged anywhere.

## 12. Dynamic UI / screen / role behavior — AUTOMATED VERIFIED

- Badge flips with `unreadCount` transitions (push insert → unread++, mark-all → 0).
- Screen renders pushed rows (list insertion path tested).
- Role: Admin (4-tab) and Manager (5-tab) shells both wire observer + realtime (tested).

## 13. Real device test — BLOCKED — DEVICE VERIFICATION

- `adb devices` → **no device attached**; no emulator available.
- Cannot produce the required on-device T0–T4 timings (event → badge visible).
- (Manager recipient targeting was verified live from the host instead — §6.)

## 14. Regression — AUTOMATED VERIFIED

- `flutter analyze` → **No issues found** (after fix).
- `flutter test` → **543/543 passing** (528 baseline + 15 new root-cause tests, zero regressions).
- `flutter build apk --debug` → **√ Built app-debug.apk**.

## 15. Root-cause tests — AUTOMATED VERIFIED

New: `test/features/notifications/notification_dynamic_fix_test.dart` (15 tests):

1. **Token freshness (D/H):** expired stored token → 401 → `POST /auth/refresh` →
   retry with rotated token → 200; stale startup-captured argument ignored;
   rotated tokens persisted. (Also live-verified in §9.)
2. **Session expiry path:** refresh failure → storage cleared + `onSessionExpired`
   fired + `AuthException` surfaced.
3. **SSE parser (M):** both live event types, keepalive/comment frames ignored,
   split-chunk framing, orphan frames dropped.
4. **Event stream (M):** ticket obtained, stream opened with ticket & **no**
   Authorization header, frames emitted, `stop()`/`dispose()` end cleanly
   (two real bugs found while writing these and fixed: backoff-completer hang on
   dispose; stale-loop emit after stop-during-connect).
5. **Controller (M):** push insert + dedupe + reconcile; `dashboard.changed` → refresh;
   id-less frames ignored; mark-all → 0 unread.
6. **Lifecycle (F):** both shells start realtime and call `handleAppResumed()` on
   `AppLifecycleState.resumed`.

## 16. Build — AUTOMATED VERIFIED

`flutter build apk --debug` succeeds (Gradle assembleDebug, 18.8 s).

## 17. Gate verdict & report separation

### AUTOMATED VERIFIED
Root cause proven by tests; 543/543 green; analyze clean; APK built; token-refresh,
SSE parsing/streaming, resume wiring and badge dynamics covered by the 15 new tests.

### REAL BACKEND VERIFIED
- Notification creation by backend (seed-purchase event → row in 4.4 s SSE / 9.7 s REST).
- Admin org-wide feed contents.
- **Manager recipient targeting:** role `manager` login → 77 notifications, business
  events, all-unread page 1; manager SSE ticket issued (200).
- SSE ticket + stream contract (both event types, keepalives, no-auth stream).
- JWT 15-minute expiry probe (401 exactly at t=15 min, permanent thereafter).
- `/auth/refresh` contract, retry, and refresh-token rotation (live, end-to-end).

### REAL DEVICE VERIFIED
*None.* No device/emulator attached (§13).

### BACKEND DEPENDENCY
None — all endpoints used exist and were verified live for **both** Admin and
Manager roles (feeds, ticket, refresh). (Farmer FCM parity is out of scope.)

---

## ⛔ GATE: `BLOCKED — DEVICE VERIFICATION`

The root cause is identified (**D/H static-token expiry + M SSE-never-consumed + F no-resume**),
the fix is implemented, all automated tests/analyze/build pass, every backend
assumption is live-verified **including manager recipient targeting** — but the
required **real-device observation of a backend notification reaching the correct
recipient with measured T0–T4 timings** cannot be performed:

1. **No adb device/emulator attached** (`adb devices` empty) → §13 impossible.

**To unblock:** attach a device or start an emulator (`adb devices` shows it), then
run the on-device sequence: login → capture T0 → trigger backend event (e.g.
`POST /seed-purchases`) → T1 SSE frame arrival → T2 badge/list visible → T3 mark-read →
T4 resume-from-background refresh; also repeat once after 15+ minutes of uptime to
prove the token-refresh path on device.
