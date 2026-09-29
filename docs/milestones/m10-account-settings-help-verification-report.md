# M10 - Account, Settings, Help, Credits, Cache: Verification Report

**Date:** 2026-09-28
**Status:** ✅ DONE — code-complete, **DEVICE VERIFICATION BLOCKED** (device disconnected after M6; `adb devices` empty on 2026-09-28)

---

## 1. Scope & Status

Checklist `m1-m12-remaining-execution-checklist.md` line 67 (M10, split):

| Work item | Outcome |
|---|---|
| `settings` screen (client-side, unblocked) | ✅ Implemented — `SettingsScreen` with notification toggles, Terms, Privacy |
| `help` screen (client-side, unblocked) | ✅ Implemented — `HelpScreen` with support number + 3 FAQs from HTML |
| Profile self-edit on `GET/PATCH /users/me` (cross-ref finding 11) | ✅ Implemented — `_EditProfileSheet` on `AccountScreen` |
| Credits ledger (item 2) | ⛔ **BLOCKED (backend)** — no contract at all → honest "Blocked (backend)" placeholder, never fake data |
| Cache stats/clear (item 14) | ⛔ **BLOCKED (backend)** — no contract at all → honest "Blocked (backend)" placeholder, never fake data |

Design ground truth: `AdminMobile UIUX.html` sections `#screen-settings` (:1134), `#screen-help` (:1165), `#screen-terms` (:1185), `#screen-privacy` (:1199), `#screen-profile-edit` (:1119), account menu rows (:1100-1107).

Contract authority: `openapi_dump.json` — `GET /users/me`, `PATCH /users/me`, schema `UpdateProfileRequest` (`name` 2–255 nullable, `email` nullable — **no** phone/zone/branch). No settings/help/credits/cache endpoints exist in the live contract.

---

## 2. Audit Evidence

- Before M10, the only screen present was `AccountScreen` (wired into both shells). No settings/help/features existed anywhere in `lib/`.
- `ModulePlaceholderScreen` claimed credits/cache were "Coming in a later milestone" — misleading for items that are blocked on backend, not scheduled.
- Both drawers already had Settings / Help / Credits / Cache entries (`custom_drawer.dart` :171-172, :184, :186) landing on the placeholder — no drawer edits needed.
- React web app has no admin settings/help pages (no reference implementation).
- `shared_preferences: ^2.5.5` already in `pubspec.yaml`.

---

## 3. Implementation Evidence

### 3.1 Profile self-edit (contract-scoped) [E-P1]
- `lib/features/account/presentation/screens/account_screen.dart` — new `_EditProfileSheet`:
  - Contract-scoped fields only: **name** (required, 2–255) + **email** (optional, nullable). **Phone is read-only** with caption "Phone changes: Backend API required — to be supplied by Syed."; Zone/Branch **omitted** (not in `UpdateProfileRequest`/`UserPublic`).
  - Direct HTTP `PATCH /users/me` with body **exactly `{name, email}`** (empty email → `null`), 12s timeout, 422 `detail` surfaced inline, `ErrorSanitizer` fallback. Mirrors the `_ChangePasswordSheet` transport pattern.
  - Merge of response into session: `{...widget.user.toJson(), ...decoded}` tolerates wrapped/flat responses.
- `lib/features/auth/presentation/controllers/auth_controller.dart` — new `applyUser(AuthUser)` updates `AuthState.authenticated` and notifies listeners, so `AuthRouter` rebuilds shells and the account card shows the new name/email immediately. **Path B chosen deliberately**: no repository/`RemoteAuthDataSource` interface change (avoids breaking the 8 `implements AuthRepository` sites).
- Three new AccountScreen rows: Edit profile details / Settings & preferences / Help & support (plus shared `_buildMenuRow` helper).

### 3.2 Settings screen [E-P2]
- `lib/features/settings/presentation/screens/settings_screen.dart` — `SettingsScreen` (Scaffold + back button, `AppCard`-based rows), `_ToggleRow`, `_LegalRow`, `LegalDocumentScreen` for Terms/Privacy copy taken verbatim from the HTML.
- `lib/features/settings/data/notification_preferences.dart` — device-local toggles via `shared_preferences` (keys `notif_push_enabled` / `notif_email_enabled` / `notif_sms_enabled`; defaults push ON, email ON, SMS OFF per HTML). `load()` falls back to defaults if the platform store is unavailable (no infinite spinner). **No backend notification-settings endpoint exists — toggles are local only** (documented gap).
- Version footer: "Sri Siva Sai Seeds Admin Console v1.0.0".

### 3.3 Help screen [E-P3]
- `lib/features/help/presentation/screens/help_screen.dart` — `supportPhone = '+91 9502662924'`, 3 FAQ questions from HTML, Contact Support card.

### 3.4 Shell routing + placeholder honesty [E-P4]
- `app.dart` passes `authController` to `AdminShell` and `ManagerShell`.
- Both shells route `NavDestination.settings` / `help` to the real screens, back → account (HTML behavior); account branch forwards `authController`.
- `module_placeholder_screen.dart` — `credits` / `cache-management` now render **"Blocked (backend)"** chip + "Backend API required — to be supplied by Syed…" instead of the misleading "later milestone" copy.

---

## 4. Test Evidence

**New tests: 20** (suite 667 → **687/687**):

| File | Tests | Covers |
|---|---|---|
| `test/features/settings/settings_test.dart` | 5 | defaults, persistence round-trip, Terms/Privacy navigation, back-pops |
| `test/features/help/help_test.dart` | 3 | support number, 3 FAQs, back-pops |
| `test/features/account/profile_edit_test.dart` | 10 | `applyUser` unit tests, 3 menu rows + navigation, contract-scoped sheet fields, validation, success PATCH asserts method/URL/body **exactly `{name,email}`** + display + session refresh + toast, empty-email → `null`, 422 surfacing, network-failure message |
| `test/features/navigation/navigation_shell_test.dart` | +2 | Admin/Manager drawer → real `SettingsScreen` / `HelpScreen` (existing placeholder expectation updated to real screen — behavior fix, not a weakened check) |

Test fixes during M10 (root causes, not weakened assertions): pushed screens needed a `Scaffold` (InkWell had no Material ancestor — would have crashed in production too); `ModalBottomSheet` isn't exported by material → sheet scoped via `find.byType(Form)`; `SharedPreferences.setMockInitialValues({})` in setUp; AppToast's `Future.delayed(2500ms)` timer drained before teardown.

---

## 5. Gate Evidence

| Gate | Result |
|---|---|
| `flutter analyze --no-pub` | ✅ 0 issues |
| `flutter test` | ✅ **687/687** |
| `verify-endpoints.mjs contract` | ✅ 50 unique client paths, all in live contract (123 ops) |
| `verify-endpoints.mjs probes` | ✅ 17 probes, control 404 confirmed |
| `flutter build apk --debug` | ✅ `app-debug.apk` built |
| Device QA (T0–T10) | ⛔ **BLOCKED — no device attached** (`adb devices` empty 2026-09-28) |

---

## 6. Gaps & Backend Notes

**All marked: "Backend API required — to be supplied by Syed."**

1. **Credits ledger** (item 2) — no endpoints/contract → honest placeholder shipped; ledger UI blocked.
2. **Cache stats/clear** (item 14) — no endpoints/contract → honest placeholder shipped.
3. **Phone change** — `UpdateProfileRequest` has no phone field → read-only in sheet with inline note.
4. **Zone/Branch on profile** — not in `UpdateProfileRequest`/`UserPublic` → omitted, not faked.
5. **Notification preferences** — no server-side settings endpoint → toggles are device-local only (`shared_preferences`).
6. Manager profile edit (cross-ref finding 11, blocked register item 5) — needs backend policy decision; sheet currently available to whoever sees the row.

---

## 7. Evidence Index

- Implementation: `lib/features/account/presentation/screens/account_screen.dart`, `lib/features/settings/{data/notification_preferences.dart, presentation/screens/settings_screen.dart}`, `lib/features/help/presentation/screens/help_screen.dart`, `lib/features/auth/presentation/controllers/auth_controller.dart`, `lib/app.dart`, `lib/features/{admin,manager}/presentation/*_shell.dart`, `lib/core/widgets/module_placeholder_screen.dart`
- Tests: `test/features/{settings/settings_test.dart, help/help_test.dart, account/profile_edit_test.dart, navigation/navigation_shell_test.dart}`
- Design ground truth: `AdminMobile UIUX.html` (:1100-1213)
- Contract: `openapi_dump.json` (`GET/PATCH /users/me`, `UpdateProfileRequest`)
