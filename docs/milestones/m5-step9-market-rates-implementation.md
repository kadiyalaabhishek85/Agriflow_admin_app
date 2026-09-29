# Milestone 5 Step 9 — Market Rates (Mandi Price Board) Implementation & Verification Report

**Date:** 2026-09-28
**Status:** READY FOR HUMAN APPROVAL
**Audit Source:** `docs/milestones/m5-step9-audit.md` (PARTIALLY READY — IMPLEMENT VERIFIED SUBSET), human-approved with decisions D1 (scope) and D2 (units).

---

## 1. Executive Summary & Scope

Step 9 delivered the **Market Rates / Mandi Price Board** in the Flutter Admin & Manager app against only the verified FastAPI contract:

- `GET  /api/v1/market-rates` — authenticated board read (with documented fallback to the public endpoint)
- `GET  /api/v1/public/market-rates` — anonymous read, identical `MarketRatePublic` payload
- `POST /api/v1/market-rates` — Set Market Rate, one grade per request (`MarketRateCreate`)

Implemented per approved decision **D1**: view, client-side search, pull-to-refresh, kept dashboard mandi strip functional, Admin/Super Admin **Set Rate** creation, Manager read-only. Per **D1**, Edit is retained only as a disabled affordance showing the exact gate notice `"Backend API required — to be supplied by Syed."`, Delete is omitted entirely, and change-% arrows / variety display are not implemented. Per **D2**, backend values stay `price_per_kg`; display converts to **₹/quintal** (`price_per_kg * 100`) at presentation time only.

**No backend, database, migration, or Supabase changes were made. No endpoint, payload field, or business rule was invented.**

---

## 2. Baseline & Verification Summary

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found** (0 errors / 0 warnings / 0 infos) |
| Full test suite | `flutter test` | **528 / 528 passed** (0 failures) |
| Step 9 test file | `flutter test test/features/market_rates/market_rates_test.dart` | **59 / 59 passed** |
| Navigation suite | `flutter test test/features/navigation/navigation_shell_test.dart` | **17 / 17 passed** |
| Android debug build | `flutter build apk --debug` | **Built** `build\app\outputs\flutter-apk\app-debug.apk` |

- Pre-existing tests: **467** — all still passing (zero regressions).
- Step 9 additions: **61** tests (59 in `market_rates_test.dart` + 2 shell-navigation tests in `navigation_shell_test.dart`).
- Gradle emitted a pre-existing plugin warning about `flutter_file_dialog` (KGP migration notice) — unrelated to this step and present before these changes.

---

## 3. Contract Verification (Ground Truth)

- OpenAPI re-verified on 2026-09-28 from `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`: **MD5 `72490454C05B7098F7E51DCBFA9E7895`, 184,966 bytes** — identical to `openapi_dump.json`.
- `MarketRatePublic`: `id`, `crop_type`, `grade` (GrainGrade `A|B|C`), `price_per_kg` (string), `effective_date`.
- `MarketRateCreate`: `crop_type`, `grade` (`A|B|C`), `price_per_kg` (> 0), `effective_date`.
- **No `PATCH`/`PUT`/`DELETE` route exists** for market rates — edit and delete are contract-gated, not implemented.
- Live probes (audit): public GET → 200 with 18 rows; admin GET unauthenticated → 401; POST unauthenticated → 401; nonexistent-path control → 404.

---

## 4. Endpoints Used & Backend Contracts

### 4.1 Implemented (verified live)

| Method | Path | Auth | Usage |
|---|---|---|---|
| GET | `/api/v1/market-rates` | Bearer | Primary board read |
| GET | `/api/v1/public/market-rates` | none | Documented read fallback + anonymous read |
| POST | `/api/v1/market-rates` | Bearer | Set Market Rate (one grade per call) |

### 4.2 Gated / Not Implemented (contract does not exist)

- **Edit Rate** — `"Backend API required — to be supplied by Syed."` (shown by `EditRateDisabledAction`; no network call, no state mutation)
- **Delete Rate** — `"Delete Rate — Backend API required — to be supplied by Syed."` (action omitted from UI; documented only)
- Change-% arrows and variety breakdown — excluded by decision D1.

---

## 5. Feature Implementation Matrix

| Feature | Status | Notes |
|---|---|---|
| Rate board (crop-grouped cards, A/B/C grid) | Implemented | `MarketRateCard`, `MarketRateGroup` |
| ₹/kg → ₹/quintal display (D2) | Implemented | `pricePerKg * 100`, presentation-only, `NumberFormat` en_IN |
| Client-side search | Implemented | case-insensitive contains; clear restores all groups |
| Pull-to-refresh | Implemented | `RefreshIndicator` → `GET` reload |
| Loading / error / empty / no-match states | Implemented | `AppLoadingView`, `AppErrorView` (retry), `EmptyStateView` |
| Set Rate (Admin/Super Admin) | Implemented | one POST per filled grade, `effective_date = today` |
| Manager read-only | Implemented | Set Rate button not rendered (RBAC, not just disabled) |
| Partial-failure reporting | Implemented | accurate `succeeded/failed` + first backend message + always reload |
| Read fallback (auth → public) | Implemented | documented; mutations never fall back |
| Edit | Gated (D1) | disabled affordance + exact backend notice |
| Delete | Omitted (D1) | documented gate string |
| Change-% arrows, variety | Not implemented (D1) | out of approved scope |
| Dashboard mandi strip | Unchanged | `dashboard_mandi_strip.dart` untouched, remains functional |

---

## 6. Architecture & Files Changed

### 6.1 New feature module (`lib/features/market_rates/`)

**Domain**
- `domain/exceptions/market_rates_exception.dart` — `MarketRatesException` + 401/403/404/422/500 subclasses
- `domain/entities/market_rate_item.dart` — strict `fromJson` (invalid price/grade **throws**; never fabricates), `effectiveDateTime`, `displayPricePerKg/Qtl(Label)`
- `domain/entities/market_rate_group.dart` — grouping, alphabetical crops, A→B→C grades, latest `effective_date` first on duplicates, `gradeOrder`
- `domain/repositories/market_rates_repository.dart` — `getRates` + `setRate` only (no update/delete by design)

**Data**
- `data/datasources/market_rates_remote_data_source.dart` — abstract contract
- `data/datasources/fast_api_market_rates_remote_data_source.dart` — raw injectable `http.Client`, 15 s timeout, `_handleErrorResponse` → typed exceptions, documented read fallback, exact `MarketRateCreate` payload, 201/200 accepted
- `data/repositories/market_rates_repository_impl.dart` — thin delegation

**Presentation**
- `presentation/controllers/market_rates_controller.dart` — generation-guarded loads, `SetRatesResult` record, `canSetRate` via `UserRole.canEditMarketRates`, search state, `updatedLabel`, ErrorSanitizer integration
- `presentation/screens/market_rates_screen.dart` — header ("Live mandi prices" / "Market Rates" / "Updated HH:mm"), search field, states, SnackBar feedback, Set Rate entry point
- `presentation/widgets/market_rate_card.dart` — crop header + disabled edit + 3-column grade grid + "Rates per quintal" footer
- `presentation/widgets/edit_rate_disabled_action.dart` — disabled edit → dialog with exact gate message
- `presentation/widgets/set_rate_sheet.dart` — 6 React crops, 3 price inputs (₹/kg), validation, "Save Rates"

### 6.2 Modified files

- `lib/features/admin/presentation/admin_shell.dart` — injectable `marketRatesController`, construction/dispose, route branch
- `lib/features/manager/presentation/manager_shell.dart` — same (role passed from session)
- `lib/core/network/api_contracts.dart` — stale `IMarketRatesRepository.updateMarketRate(commodityId, A/B/C)` **replaced** with contract-true `getMarketRates(accessToken)` + `setRate({cropType, grade, pricePerKg, effectiveDate})` (declaration had zero references; `grep updateMarketRate` → no matches remaining)
- `test/features/navigation/navigation_shell_test.dart` — 2 placeholder tests repurposed (Admin → Event Logs, Manager → Settings, both with `ensureVisible` since those items sit below the drawer fold) + 2 new MarketRatesScreen integration tests (Admin sees Set Rate, Manager does not)

### 6.3 New test

- `test/features/market_rates/market_rates_test.dart` — 59 tests across 7 groups (domain, data source incl. fallback/error/timeout, repository, controller, UI, 4 responsive sizes, shell integration)

---

## 7. Role-Based Access Control (RBAC)

- Uses existing `UserRole.canEditMarketRates` (`admin || superAdmin`) — `lib/core/models/user_role.dart:74`.
- **Admin / Super Admin:** view, search, refresh, Set Rate (create). Sheet + button rendered.
- **Manager:** view, search, refresh only — Set Rate action is **not rendered** (app convention for inaccessible actions; verified by tests for both screen-level and shell-level navigation).
- React's super-admin-only mutation restriction was **not** copied (decision: app roles govern UI; the backend enforces its own authorization → 403 mapping tested).

---

## 8. Units & Data Handling (Decision D2)

- Domain keeps `pricePerKg` exactly as returned (`21.50`).
- Presentation: `displayPricePerQtl = pricePerKg * 100` → `₹2,150` (`NumberFormat.currency(locale: 'en_IN', decimalDigits: 0)`); kg label `₹21.50`.
- Creation input is `price_per_kg` (labeled ₹/kg) and is sent as entered — no client-side multiplication on write.
- `effective_date` = `DateFormat('yyyy-MM-dd').format(DateTime.now())`.
- Invalid/missing `price_per_kg` or `grade` in a response **throws** `MarketRatesException` — the UI shows the error state rather than fabricating data.

---

## 9. Error Handling & Resilience

- Typed mapping: 401 → Unauthorized, 403 → Forbidden, 404 → NotFound, 422 → Validation (backend `detail` preserved), other → Server; `SocketException`/timeout → `MarketRatesException(isNetworkError: true)` with safe user text.
- Controller wraps unknown errors with `ErrorSanitizer.sanitize(e, defaultAction: ...)`.
- **Read fallback:** authenticated GET failure → public GET (identical payload); if that fails, its error propagates. Mutations never fall back.
- **Partial failure:** grade-by-grade results aggregated into `SetRatesResult` (`succeeded`, `failed`, first `errorMessage`); full-success SnackBar only when `failed == 0`; board always reloaded afterward so the UI reflects what actually persisted.
- Stale-response protection: monotonic `_requestGeneration` discards superseded loads.

---

## 10. Test Evidence (Step 9)

`test/features/market_rates/market_rates_test.dart` — **59 tests, all passing**, covering:
- **Domain (11):** full payload parse, string/lowercase tolerance, no-fabrication throws (invalid/missing price and grade), quintal conversion + en_IN labels, equality/toString, unparsable date, grouping/sorting, duplicate-grade recency, search case-insensitivity + clear restore, exception status codes.
- **Data source (12):** authenticated GET path/headers/parse; public fallback on 401 (2 requests, no auth header on second); both-fail propagation; anonymous public read; exact POST payload keys + date format + 201; 401/403/422(with `detail`)/404/500 mappings; SocketException and TimeoutException → network errors.
- **Repository (1):** delegation of `getRates`/`setRate`.
- **Controller (14):** load success/failure, ErrorSanitizer path, refresh flag, search filter/clear, group ordering, RBAC matrix, one POST per filled grade + reload, filled-grades-only, **partial failure accuracy**, Manager blocked with zero requests, empty-map and empty-crop validation.
- **UI (15):** card grid + ₹/quintal + footer; Edit gate dialog with exact message; header/search/Set Rate render; Manager read-only; search filter + clear; no-match state; empty state; error state + retry; pull-to-refresh reloads; sheet structure; crop/grade/price validations; successful submit posts only filled grades; full-screen success SnackBar.
- **Responsive (4):** 320×568, 360×640, 412×860, 412×960 — zero overflow exceptions.
- **Shell (2):** AdminShell → `MarketRatesScreen` with Set Rate + data; ManagerShell → screen without Set Rate.

Navigation suite additions (2): drawer routing to `MarketRatesScreen` for both roles, with the two repurposed placeholder tests still green.

---

## 11. Security & Compliance Notes

- Bearer tokens passed in memory only; **never logged**; no secrets/keys introduced.
- All user-facing errors flow through `ErrorSanitizer` or typed domain messages — no stack traces or raw server text surfaced beyond backend `detail` messages already user-safe.
- No Supabase usage anywhere in the feature; no SQL/migrations touched; no React mutation logic copied.
- The disabled Edit affordance performs no network calls and mutates no local state.

---

## 12. Backend Changes

**NONE.** No FastAPI code, route, schema, or response shape was modified. Pending contract expansions (Edit/Delete routes, grade-price columns, etc.) remain documented in `docs/backend-requirements-admin-mobile.md` as `"Backend API required — to be supplied by Syed."`

---

## 13. Database Changes

**NONE.** No table, index, migration, or seed change. Existing `market_rates`-backed data accessed exclusively through the three verified endpoints.

---

## 14. Responsive Layout Verification

`MarketRatesScreen` verified at 320×568, 360×640, 412×860, 412×960 with `tester.takeException() == null` (0 RenderFlex overflows). The Set Rate sheet header uses `Expanded` + ellipsis so the title row cannot overflow on narrow widths (an overflow caught by tests during implementation was fixed).

---

## 15. Known Gaps & Deferred Items

1. **Edit Rate** — backend `PATCH/PUT /api/v1/market-rates/{id}` required → `"Backend API required — to be supplied by Syed."`
2. **Delete Rate** — backend `DELETE` required → documented gate string; no UI action.
3. **Change-% arrows / variety display** — excluded by approved decision D1.
4. **Dashboard mandi strip** — left untouched by design (D1: keep functional as-is).

---

## 16. Traceability to Approved Decisions

- **D1 (scope)** — implemented exactly: view/search/refresh/RBAC-create; gated Edit; omitted Delete; excluded arrows/variety.
- **D2 (units)** — `price_per_kg` canonical in domain; `*100` conversion only in presentation labels; create writes kg values as entered.
- **Audit phases 1–3** from `m5-step9-audit.md` completed: domain+data, presentation+shell wiring, contract cleanup + tests + report.

---

## 17. Verification Commands (Reproducible)

```bash
flutter analyze                 # No issues found
flutter test                    # 528/528 passed
flutter test test/features/market_rates/market_rates_test.dart   # 59/59 passed
flutter test test/features/navigation/navigation_shell_test.dart # 17/17 passed
flutter build apk --debug       # build\app\outputs\flutter-apk\app-debug.apk
```

---

## 18. Final Gate

**Status: READY FOR HUMAN APPROVAL**

- All gates green: `flutter analyze` 0 issues, `flutter test` 528/528, debug APK built.
- Zero backend/database/migration/Supabase changes; zero invented endpoints or fields (3 verified endpoints only).
- Decisions D1/D2 fully honored; RBAC matches AGENTS.md §3; gate strings verbatim.
- No pre-existing test regressions (467 baseline tests unaffected).

**STOP — do not begin M5 Step 10 without human approval.**
