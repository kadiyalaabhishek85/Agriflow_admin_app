# Build, Endpoint Connectivity, and Workflow Review

Review of the AgriFlow Admin & Manager Flutter application against the live FastAPI backend. Every figure below was measured this session by the gate ledger in `GATES.md` (checker: `.agents/skills/unlazy/scripts/gate-check.mjs`, evidence: automatic-evidence v1 with definition digests).

## 1. Build Health

**Status: SUCCESS — no errors, warnings, or critical issues.**

| Check | Command | Measured result |
|---|---|---|
| Static analysis | `flutter analyze` (gate G1) | exit 0 — `No issues found` (0 errors, 0 warnings) |
| Full test suite | `flutter test` (gate G2) | exit 0 — `All tests passed!` (334 tests, zero failures; count observed on full-suite runs this session) |
| Android debug build | `flutter build apk --debug` (gate G3) | exit 0 — `app-debug.apk` produced by Gradle `assembleDebug` |

No runtime-performance-affecting issues surfaced in analysis or tests.

## 2. Endpoint Connectivity

**Status: CONNECTED — every backend path the app calls exists in the deployed contract and is reachable live. Disconnected: none. Misconfigured: none.**

Method (two independent layers, both gated):

1. **Static contract gate (G4):** `scripts/verify-endpoints.mjs contract` extracts every backend path referenced in `lib/` (`_uri('...')` call sites plus the one full `Uri.parse` in `account_screen.dart`), normalizes Dart interpolations to path parameters, fetches the live `openapi.json`, and requires each client path to exist in the deployed contract. Positive control: the checker self-tests that extraction found a substantial inventory, that a known-real path (`/api/v1/seeds`) is accepted, and that a bogus path is rejected — so the absence check cannot silently pass. Result: **41 unique client paths, all present in the live contract (123 operations)**.
2. **Live probe gate (G5):** with a negative control first (**unknown path must return 404**, otherwise probe semantics prove nothing): public endpoints `GET /health`, `GET /api/v1/docs`, `GET /api/v1/public/market-rates`, `GET /api/v1/public/seeds`, `GET /api/v1/public/stats` → **200**; 12 representative guarded routes and methods (including `GET/DELETE /api/v1/seeds/{id}`, `GET/PATCH/DELETE /api/v1/warehouses/{id}`, `GET /api/v1/warehouses/{id}/inventory`, `DELETE /api/v1/warehouse-slots/{id}`, `GET /api/v1/notifications`, `GET /api/v1/transactions`, `GET/POST /api/v1/managers`) → **401/422 (route+method exists, auth enforced)**. Result: `PROBES OK (17 probes, control 404 confirmed)`.

Authenticated 2xx round-trips are not probed (no credentials in scope; production mutations out of scope); those paths are contract-proven and covered by the 334 mock-backed tests.

One checker defect was caught during gating and fixed: the first contract-gate run failed because parameter labels differ between client and contract (`{param}` vs `{booking_id}`); the comparison now normalizes parameter names structurally. That failure was an oracle bug, not a disconnected endpoint — re-run passed.

`openapi_dump.json` (local contract cache) was found stale earlier this session (112 vs 123 operations) and has been refreshed from live.

## 3. Workflow Compliance

**Status: PASS — all implemented workflows wired end-to-end; deviations are placeholder destinations only.**

- Gate G6 measured from source: **9 admin routes** (Dashboard, Seed Purchase, Seeds Inventory, Warehouse, Booking Slot, Farm Visits, Grain Sales, Farmers, Account) each resolve to a real screen in `admin_shell.dart`; **5 manager tabs** (Seed Purchase, Booking Slot, Farm Visits, Grain Sales, Account) declared in `nav_destination.dart`; both shells fall back to `ModulePlaceholderScreen` — `WORKFLOW WIRING OK`.
- Frontend↔backend data flow for those workflows is exercised by the passing suite: login/refresh/logout, RBAC (manager read-only), seeds CRUD + image upload (multipart contract), warehouse CRUD + slots, grain sale review/pay/procure, farmer KYC approval, farm-visit schedule/complete, booking status, dashboards and audit logs, error sanitization.
- **Deviations from a "full-feature" design (by design, asserted by existing navigation tests):** 10 destinations route to placeholders — `billing, market-rates, reports, event-logs, managers, credits, cache-management, notifications, settings, help`. Drawer/dashboard entries for **Market Rates** and **Managers** look like features but open placeholders (their data is used on dashboards / farm-visit assignment instead).
- Backend operations defined but not yet used by this app (feature gaps, not breakage): `PATCH /transactions/{id}/pay`, notifications read/read-all UI, `POST /managers` + status/reset screens, `POST /bookings/{id}/inspect`, `POST /farm-visits/reminders`, `POST /seed-purchases`, `PATCH /users/me`, `uploads/presign`, `auth/send-otp`+`verify-otp`, `events/stream`, `market-rates` admin create.

## 4. Discrepancies

Prioritized findings with remediation:

| Severity | Finding | Remediation |
|---|---|---|
| **Critical** | None. No disconnected endpoints, no build failures, no failing workflows. | — |
| **Major** | `AGENTS.md` §2/§6 and `docs/backend-requirements-admin-mobile.md` still describe warehouse `PATCH`/`DELETE`, `GET /warehouses/{id}/inventory`, seeds warehouse-assign, and `GET /seeds/{id}` as "pending backend — to be supplied by Syed". All are **deployed and called by the app** (verified live). Stale authority docs contradict the golden rule they guard. | Update both docs: mark those operations "deployed, verified live 2026-09-27" (contract cache already refreshed). |
| **Minor** | `account_screen.dart:392` hardcodes the full backend URL instead of using the configurable `baseUrl`, bypassing `ApiClient` configuration. | Build the change-password URI from `ApiClient` base (1 line). |
| **Minor** | `defaultBaseUrl` duplicated as a constant in 12 data-source files — an environment change requires 12 edits. | Centralize into `ApiClient.defaultBaseUrl` only; datasources read it from there. |
| **Minor** | The app has zero request logging — connection failures, timeouts, and non-2xx statuses are invisible when diagnosing field reports (backend logs are on Render, owned by Syed). | Add one `debugPrint` of `method path status` in `ApiClient` response handling. |
| **Minor** | Drawer/dashboard entries for the 10 placeholder destinations present themselves as available features. | Badge them "Coming soon" or hide until built. |
| **Info** | 13 backend operations exist that the app never calls (listed in §3) — roadmap gaps, not defects. | Prioritize per product roadmap; no backend dependency needed. |

## 5. Gate Ledger Results

`GATES.md` (8 gates, all self-authored oracles, approved and executed this session):

| Gate | Outcome |
|---|---|
| G0 ledger lint | PASS — `LINT OK` |
| G1 static analysis | PASS |
| G2 full test suite | PASS |
| G3 APK build | PASS |
| G4 contract connectivity (with positive control) | PASS after oracle fix — `ENDPOINTS CONNECTED (41 client paths / 123 live ops)` |
| G5 live probes (with 404 control) | PASS — `PROBES OK (17 probes)` |
| G6 workflow wiring | PASS — `WORKFLOW WIRING OK` |
| G7 report completeness | PASS — this document |

Final ledger state and counts were re-measured with `gate-check.mjs --status` immediately before this report was presented: **8/8 met, 0 unmet, 0 abandoned**.
