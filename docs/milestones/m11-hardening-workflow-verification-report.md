# M11 - Hardening & Workflow Alignment: Verification Report

## 1. Scope & Status

M11 closes the pre-M8 stabilization audit verify-only items, the flutter-03 recommendations 5/6/10, the client-side halves of the workflow cross-reference gaps (bank-change sheet, seed-purchase invoice, dashboard "today" labels), and the shared-exception/timeout hardening across farmers, farm-visits, bookings and grain sales.

- **Status:** code-complete. All five implementation items (A-E) shipped with tests. **DEVICE VERIFICATION BLOCKED — device disconnected after M6** (`adb devices` empty on 2026-09-28).
- **Boundary honored:** Flutter frontend only. No endpoint, field or payload was invented. Items without contract support are marked: *Backend API required — to be supplied by Syed.*
- **Gates:** analyze 0 · tests **712/712** (+25 M11) · contract 50/50 (50 unique paths, 123 ops) · probes 17 OK (control 404) · debug APK builds.

## 2. Audit Evidence

### 2.1 Pre-M8 Phase 2 verify-only items

| Item | Verdict | Evidence |
|---|---|---|
| P1-01 grain `booking_slot_id` fallback | ✅ Verified — no `saleId` fallback, scans bookings by `grainSaleId`, throws a clear error when unresolved | `lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart:120-151` |
| P1-02 manager dashboard `scheduled` vs `in_progress` | ✅ Verified — `in_progress` is **not** a member of `VisitStatus` (`scheduled\|pending_review\|completed\|cancelled` in `openapi_dump.json`); the shipped count was already `scheduled` | contract schema + implementation (reworked in §3.1) |
| P2-03 admin trend `Future.wait()` | ✅ Verified — the six monthly report calls are concurrent | `lib/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart:108` |
| P2-01 bookings date query params | ⛔ BLOCKED — client-side date filter only; contract has no date params on `GET /bookings` → *Backend API required — to be supplied by Syed.* | `lib/features/booking_slot/presentation/controllers/booking_controller.dart:33-36` |

### 2.2 flutter-03 recommendations in scope

- **Rec 5 (shared farmer lookup):** four copies of farmer-name/phone resolution existed (farmer repository, grain repository, farm-visit DS, booking DS). Three were HTTP-direct and uncached per load.
- **Rec 6 (exception merge + 409):** four parallel exception hierarchies exposed the same three fields (`message`, `statusCode`, `isNetworkError`) with no common interface; HTTP 409 from farm-visits/bookings surfaced as generic errors instead of typed conflicts.
- **Rec 10 (status-pill cases):** `StatusPill` had no case for `pending_review` (VisitStatus) or `inspected` (BookingStatus).
- **Out of scope for M11 (per checklist):** default-password flows, grain list, formatters.

### 2.3 Cross-reference findings

- **Bank-change sheet load-more + error display:** already shipped in M7/M8 — `loadMoreBankRequests` at `lib/features/farmers/presentation/screens/farmer_screen.dart:258-261`, sheet `errorMessage` handling, covered by `test/features/farmers/farmer_test.dart:1064,1075`. **Verify-only, no code change.**
- **Invoice download (workflow-cross-reference.md:241):** Flutter displayed only the invoice number; React generates/downloads an invoice client-side. Needs no backend → **implemented (§3.5)**.
- **Dashboard "today" labels (finding 8):** all-time totals and fabricated constants labelled as today's figures → **relabeled to honest basis (§3.1)**; server-side date-scoped aggregates remain *Backend API required — to be supplied by Syed.*
- **Finding 11 (self-service profile editing):** closed in M10 (profile self-edit on `GET/PATCH /users/me`).

## 3. Implementation Evidence

### 3.1 Manager dashboard honesty relabels [E-A]

- `manager_dashboard_data.dart`: field renames making the data basis explicit — `bookingsToday→bookingsTotal`, `farmVisitsToday→farmVisitsCount`, `farmVisitsInProgress→farmVisitsScheduled`, `todayRevenue→revenueMtd`, `grainSalesToday→grainSalesTotal`; deleted `slotsRemaining` and `salesDelta`.
- `manager_dashboard_remote_data_source.dart`: visit count uses `status == 'scheduled'` (the previous `in_progress` check could never match any `VisitStatus` member); `todaySeeds` is a real `created_at`-today count (was `min(5, list.length)`); the two fabricated constants (slots remaining `10`, sales delta) removed.
- `manager_dashboard_view.dart`: strip label "Revenue (month-to-date)"; cards "Bookings", "Farm visits" (with "N scheduled" delta), "Grain sales"; every fabricated delta ("new today", "slots left", "vs yesterday") removed.
- **No false claim survives:** old label strings assert `findsNothing` in the updated test.

### 3.2 StatusPill rec 10 [E-B]

- `lib/core/widgets/status_pill.dart`: `pending_review → PillType.warn` (auto label "Pending review"), `inspected → PillType.info`.

### 3.3 Shared AppApiException + typed 409 conflicts [E-C]

- New `lib/core/network/api_exception.dart`: `AppApiException { message, statusCode, isNetworkError }`.
- `FarmerException`, `GrainSaleException`, `BookingException`, `FarmVisitException` now `implements AppApiException`.
- New typed conflicts: `FarmVisitConflictException` and `BookingConflictException` (both `statusCode: 409`), thrown from `_handleErrorResponse` on HTTP 409 in farm-visit and booking data sources.
- Network failures uniformly expose `isNetworkError == true` (status 0 / timeout).

### 3.4 Shared FarmerLookupService + 15s timeouts [E-D]

- New `lib/features/farmers/data/farmer_lookup_service.dart`: single-flight, per-(baseUrl, token) in-memory cache; canonical parse reads `farmer_profile.address` with top-level `village` fallback (fixes the grain parser's broken `item['village'] ?? item['address']`); failures return `{}` and are **never cached**; 15s request timeout; `@visibleForTesting clear()`.
- Farm-visit, booking and grain data sources all route their farmer lookups through the service; the farmer repository keeps its own repository-cached path (tests fake it).
- **15s timeout** added to all 7 farm-visit and 4 booking client calls, with `TimeoutException` catches mapping to `FarmVisitNetworkException` / `BookingException(... isNetworkError: true)` — a hung backend now surfaces "Server request timed out" instead of hanging the UI.

### 3.5 Seed-purchase invoice PDF download [E-E]

- New `lib/features/seed_purchase/domain/services/`:
  - `seed_invoice_data.dart` — `SeedInvoiceData.fromItem` (formatted, immutable inputs; `invoice_<number>.pdf` file name with raw-id fallback).
  - `seed_invoice_pdf_builder.dart` — pure `buildSeedInvoicePdf` (A4, NotoSans font for the ₹ glyph, invoice number, colored payment status, farmer/phone, seed/variety, quantity, price/kg, grand total, "No signature required" footer). Mirrors the billing receipt builder.
  - `seed_invoice_downloader.dart` — `InvoiceDownloader` interface + `AndroidInvoiceDownloader` with seam-injectable `loadFont`/`buildPdf`/`saveFile`; saves through the SAF system picker (`flutter_file_dialog`, **no storage permissions, no new pubspec dependencies**); every failure maps to a fixed sanitized message (`pdfFailure`/`saveFailure`/`permissionDenied`/`cancelled`) — raw exception text never reaches the UI.
- `seed_purchase_detail_sheet.dart`: new "Download invoice" action (always available, including for paid rows; duplicate taps ignored while in flight; spinner state; result surfaced via `AppToast`).
- **No backend involved** — client-side export from the already-loaded row, exactly as the React reference does.

## 4. Test Evidence

| Suite | Tests | Notes |
|---|---|---|
| `test/features/farmers/m11_workflow_hardening_test.dart` | 9 | canonical parse + cache + single-flight + token-bypass + failure-not-cached; AppApiException contract across 4 hierarchies; farm-visits 409 → `FarmVisitConflictException`; bookings 409 → `BookingConflictException` |
| `test/features/seed_purchase/seed_invoice_test.dart` | 15 | `fromItem` mapping + id fallback; real-font PDF render (`%PDF`); downloader seams ×7 (success, builder failure, font failure, SAF cancel, permission, io error, generic save failure); sheet ×4 (paid-row action, pending-row coexistence, seam tap → success toast, failure toast, duplicate-tap guard) |
| `test/widget_test.dart` | +1 | `StatusPill` maps `pending_review` and `inspected` |
| `test/features/manager/manager_dashboard_test.dart` | 11 | updated fixtures/labels + `findsNothing` honesty assertions for every removed false claim |

- Regression: farm-visit / booking / grain / farmer suites re-run after §3.4 → **150/150 pass** (static cache cannot leak across test files — each file runs in its own isolate).

## 5. Gate Evidence

```
flutter analyze --no-pub   → No issues found!
flutter test               → 712/712 (687 at M10 close + 25 M11)
node scripts/verify-endpoints.mjs contract → ENDPOINTS CONNECTED (50 unique client paths, 123 ops)
node scripts/verify-endpoints.mjs probes   → PROBES OK (17 probes, control 404 confirmed)
flutter build apk --debug  → √ Built build\app\outputs\flutter-apk\app-debug.apk
```

Device gate: **BLOCKED** — no device attached (`adb devices` empty).

## 6. Gaps & Backend Notes

1. **Booking date filtering** — client-side only; contract exposes no date params. Backend API required — to be supplied by Syed.
2. **Server-side "today" aggregates and delta-vs-yesterday** — the root cause behind cross-ref finding 8; dashboard now labels its honest basis (all-time / month-to-date) instead of faking per-day numbers. Backend API required — to be supplied by Syed.
3. **Timeout surface** — 15s is a client-side guardrail, not a contract-level SLA; server-side slow endpoints still resolve as `isNetworkError` timeouts.
4. **Invoice format** — PDF chosen over the React reference's HTML (matches the billing receipt path already shipped, needs no new dependency). Revisit only if a backend-issued invoice endpoint appears.
5. **Manager dashboard API** — still assembled client-side from list routes; a single dedicated endpoint remains *Backend API required — to be supplied by Syed.*

## 7. Evidence Index

- Checklist: `docs/milestones/m1-m12-remaining-execution-checklist.md` (M11 entry, line 72)
- Audit sources: `docs/audits/pre-m8-stabilization-audit.md` (P1-01/P1-02/P2-01/P2-03), `docs/deep-review/flutter-03-farmers-visits-grain-booking.md` (recs 5/6/10), `docs/deep-review/workflow-cross-reference.md:241` (invoice), `:293` (finding 8), `:299` (finding 11)
- Contract: `openapi_dump.json` (`VisitStatus`, `BookingStatus`, `FarmerAdminView`)
- Implementation: §3.1-§3.5 files listed above
- Tests: §4 file list; full run 712/712
