# M7 — Admin & Analytics Modules: Verification Report

**Date:** 2026-09-28 · **Milestone:** M7 (checklist items 1–3) · **Verdict:** ✅ **CODE-COMPLETE** — functionality + contract + tests + gates green. **DEVICE VERIFICATION BLOCKED** (device disconnected by user after M6 verification).

---

## 1. Scope & Status

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | **Managers admin** (adminOnly): `GET/POST /managers`, `PATCH /managers/{id}/status`, `POST /managers/{id}/reset-password` | ✅ COMPLETE (code) | [E-C1], [E-T1], [E-T4] |
| 2 | **Reports & Analytics** (adminOnly): `GET /admin/reports/monthly` full screen — month navigation; export BLOCKED (backend) | ✅ COMPLETE (code) | [E-C2], [E-T2], [E-T4] |
| 3 | **Event Logs** (adminOnly): `GET /admin/audit-logs` with pagination/filters | ✅ COMPLETE (code) | [E-C3], [E-T3], [E-T4] |

Checklist item 2 asked for a "date range/type switch". The contract only exposes a **single-month** parameter (`?month=YYYY-MM`, pattern `^\d{4}-\d{2}$`) — there is no range or report-type parameter, so the screen implements prev/next **month navigation**, the honest contract-supported equivalent. Nothing was invented.

## 2. Contract Evidence (openapi_dump.json — authoritative)

[E-C1] **Managers** — all four routes implemented as specified; `PATCH /managers/{id}` (`ManagerUpdate`) exists in the contract but is **intentionally not wrapped** (checklist lists only the four ops above) and is documented as out-of-scope in the repository interface.
- `GET /managers` params `page, page_size(1–100, def 20), search, status, sort(def created_at), order(asc|desc, def desc)` → `PaginatedResponse[ManagerPublic]`.
- `POST /managers` → **201**; body `ManagerCreate` (name≥2, phone 8–20, password 8–128 required; email/assigned_region/department optional; role fixed `manager`).
- `PATCH /managers/{id}/status` body `{status}` (UserStatus enum) → updated `ManagerPublic`.
- `POST /managers/{id}/reset-password` body `{new_password}` (8–128) → `MessageResponse`; backend message rendered in the success snackbar.

[E-C2] **Reports** — `GET /admin/reports/monthly?month=YYYY-MM` → `MonthlyReportResponse{month, total_seed_purchases_amount:str, total_grain_sales_amount:str, total_bookings:int, new_farmers:int}`. Amount strings parsed for display with Indian-grouping formatter (`₹1,25,000`); unparseable input shown raw.

[E-C3] **Event Logs** — `GET /admin/audit-logs` with the standard list params → `PaginatedResponse[AuditLogPublic]`. `old_value`/`new_value` are **JSON objects** (not strings) — parsed as `Map<String, dynamic>?`. `Pagination` = `{page, page_size, total, total_pages}`; `hasNext` derived (`page < total_pages`), same as M6 root fix.

[E-C4] Contract sweep: `node scripts/verify-endpoints.mjs contract` → **50 unique client paths, all present in live contract (123 ops)** (+2: `/admin/reports/monthly`, `/admin/audit-logs`).

## 3. Test Evidence

[E-T1] `test/features/managers/managers_test.dart` — **30/30**: entity (fromJson/defaults/initials/copyWith/pagination), DS HTTP (list query contract, create 201 + role payload, status PATCH, reset-password body, 401/403/404/422/500 → typed exceptions), controller (load/counts, loadMore, server search, status filter, create prepend + failure, status toggle + failure keeps state, reset success/failure, error state), widgets (cards/counters/chips, empty state, chip reload, suspend-with-confirm dialog, reset sheet validation→success snackbar, create sheet validation→success, inline backend failure, standalone sheet wiring).

[E-T2] `test/features/reports/reports_test.dart` — **17/17**: entity (fromJson, missing-field defaults, Indian-grouping formatter incl. `1234.56` decimals, negatives, 8-digit grouping, non-numeric passthrough), DS HTTP (month param + auth header + parse; 401/403/422/500 mapping), controller (current-month default, load, prev/next month shift + reload, error), widgets (4 stat cards formatted values, export control blocked with tooltip + footnote, prev/next reload, error state → retry recovery).

[E-T3] `test/features/event_logs/event_logs_test.dart` — **14/14**: entity (contract fields incl. object diffs, null tolerance, `createdLabel` ISO formatting, pagination derivation), DS HTTP (list query contract + parse; 401/403/500 mapping), controller (load, loadMore, server search, error), widgets (tile rendering + header count, empty state, search filter + clear, error state → retry recovery).

[E-T4] **Full regression:** `flutter analyze --no-pub` → **0 issues**; `flutter test` → **640/640 pass** (baseline 580 → +60 net new tests; no tests weakened). Updated `test/features/navigation/navigation_shell_test.dart`: the *Event Logs placeholder* assertion replaced with real-screen navigation + back, plus new drawer tests for **Managers** and **Reports & Analytics** (19/19 in file).

## 4. Gate Evidence

- [E-G1] G1 static analysis: `flutter analyze --no-pub` → **0 issues**.
- [E-G2] G2 full suite: **640/640**.
- [E-G3] G3 debug APK: `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`.
- [E-G4] G4 contract: **50/50 client paths** in live OpenAPI.
- [E-G5] G5 probes: `node scripts/verify-endpoints.mjs probes` → **PROBES OK (17 probes, control 404 confirmed)**.
- [E-G6] G6 wiring: `admin_shell.dart` route branches for `ManagerScreen` (:570), `ReportScreen` (:577), `EventLogScreen` (:584) before the placeholder fallback; three optional controller params injected for tests; `manager_shell.dart` unchanged (adminOnly routes unreachable there by design — `destination.adminOnly` skip at :340, RBAC §3 respected).

## 5. Implementation Notes

1. **RBAC:** all three features are `adminOnly` routes — ManagerShell never reaches them; no manager-side code added (AGENTS §3).
2. **Session TTL:** short-lived test-backend tokens surface the existing 401 snackbar *"Session expired. Please log in again."* — noted for QA runs.
3. **Error surfacing:** sheets follow the M6 pattern (optional `errorMessage` getter + inline `_localError` container, pop only on success); screens use empty/error/loading states with retry.
4. **Ambiguity fixed during tests:** report header back button gained `Key('report_back_btn')` (month navigator has its own chevron-left, making `find.byIcon` ambiguous).

## 6. Gaps & Backend Notes

1. **Report export (PDF/CSV) — BLOCKED (backend):** no export route in the contract. The header Export control renders **disabled** with tooltip *"PDF/CSV export: Backend API required — to be supplied by Syed."* plus an inline footnote on the screen. Never faked.
2. **Date range / report type:** contract is month-scoped only (`month=YYYY-MM`); range/type switch **Backend API required — to be supplied by Syed.**
3. **`PATCH /managers/{id}` (ManagerUpdate):** exists but out of checklist scope — manager edit UI deferred (can be added without contract work if desired).
4. **DEVICE VERIFICATION BLOCKED:** device disconnected after M6 verification; M7 closes as *code-complete, DEVICE VERIFICATION BLOCKED* per checklist rule. On-device QA (drawer → Managers/Reports/Event Logs flows) queued for device re-attach or M12 T0–T10.

## 7. Evidence Index

- Tests: `flutter test` run 2026-09-28 — 640/640; `flutter analyze` — 0 issues.
- Gates: contract 50/50 · probes 17 OK · debug APK built.
- Key sources: `lib/features/managers/**` (7 domain/data + 5 presentation files), `lib/features/reports/**`, `lib/features/event_logs/**`, `lib/features/admin/presentation/admin_shell.dart` (imports ×12, 3 fields/params, `_initManagersReportsEventLogs`, dispose, 3 route branches).
- Tests: `test/features/{managers,reports,event_logs}/*_test.dart`, `test/features/navigation/navigation_shell_test.dart`.
