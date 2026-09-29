# Grain Sales Review & Filter — Implementation Report

## 1. Summary

Both confirmed production bugs are fixed in the Flutter app only, with no backend changes.

- **Bug 1 (production blocker):** Review & Approve used to send the sale UUID as `booking_slot_id`, producing the backend error "Booking slot not found". The fabricated fallback is deleted; the review path now resolves the real booking by joining `GET /api/v1/bookings` on `grain_sale_id == grain sale id` and sends that booking's `id`. When no booking exists (procure-created sales), the review request is never sent and the user sees the exact guard message "This grain sale is not associated with a booking slot and cannot be reviewed yet."
- **Bug 2 (correctness/UX):** the misleading `Pending / Received (0)` chip that actually sent only `status=pending` is replaced by four truthful single-status chips — `All` (`status=null`), `Pending` (`status=pending`), `Received` (`status=received`), `Paid` (`status=paid`) — with all counts removed, matching the approved HTML.

Verification: `flutter test` **319/319 pass** (baseline 313 + 6 new regression tests), `flutter analyze` **No issues found (0)**, `flutter build apk --debug` **exit 0**.

## 2. Scope and Constraints

- Flutter-only: `lib/**` and `test/**` edits confined to the declared write set in `GATES.md` (gate G8, mechanical mtime scan, PASS).
- No backend, database, migration, or contract changes; no invented endpoints, fields, status values, or fake data; no unrelated refactoring; no M5 Step 8 work; no test weakened or deleted.
- Authority: live FastAPI OpenAPI (`https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`) plus the sanctioned investigation report `docs/bugs/grain-sales-review-and-filter-investigation.md`.
- Reticle runtime verification is unavailable for this Flutter project (no session, no web dev script — investigation §11); verification rests on the unit/widget suite, static analysis, and the APK build.

## 3. Contract Evidence

Verified facts used for the Bug 1 decision (confidence assessed at 0.85, above the required 0.70 threshold):

1. Live contract: `GrainSaleReviewRequest` **requires** `booking_slot_id` (uuid), `good_quantity_kg`, `bad_quantity_kg`, `approve`, and its schema description ties the review to "the booking slot's crop_inspection" (Master Plan Module 8 inspect→procure flow); `GrainSalePublic` exposes neither `booking_slot_id` nor `booking_id`, so `GrainSaleItem.fromJson` can never supply it (`lib/features/grain_sales/domain/entities/grain_sale_item.dart:62`).
2. Live contract: `BookingPublic` = `id, farmer_id, warehouse_id, warehouse_slot_id, grain_sale_id, booking_date, grain_type, quantity_kg, status, notes`; `GET /api/v1/bookings` is the sanctioned way to traverse sale↔booking.
3. Project data-model contract (legacy SQL the FastAPI ports): `crop_inspections.booking_slot_id` is written from `booking_slots.id` (`agriflow/agriflow-web/supabase/migrations/20260714080000_seed_purchase_notify_and_units.sql:90`, `:107`, `:126`), and `BookingPublic` maps 1:1 onto the booking-slot row (column match, farmer `book-slot` returns `booking_id`), so `BookingPublic.id == booking_slot_id` for the review payload.
4. Structural corollary: `POST /bookings/{booking_id}/inspect` returns `CropInspectionPublic` carrying `booking_slot_id` — the only booking identifier in the path is the booking id.

This chain is documented as INFERRED where the live OpenAPI does not state it literally; confirmation via one authenticated round-trip remains an open ask (§15, §16).

## 4. Bug 1: Root Cause

The full verified trace is in the investigation report §3.1; root cause in one sentence: a three-term client-side fallback `bookingSlotId ?? existingItem?.bookingSlotId ?? saleId` guaranteed that when no slot was supplied (always — the screen never passes one at `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:65`) and the entity field was always null (neither JSON key exists on `GrainSalePublic`), the **sale id** was submitted as `booking_slot_id` (`lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:252`).

## 5. Bug 1: Fix Design

- The controller no longer accepts or fabricates a slot id: `reviewGrainSale` takes only `saleId` and yield inputs (`lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:184`); the fallback line is gone.
- The repository contract no longer exposes `bookingSlotId` (`lib/features/grain_sales/domain/repositories/grain_sale_repository.dart:29`) — presentation cannot send a wrong value because it never sees the field.
- Resolution happens in the repository implementation, which already orchestrates cross-source data (farmer enrichment): `_resolveBookingSlotId` pages `GET /api/v1/bookings` through the **existing** `BookingRemoteDataSource` (reused, not duplicated) and returns the first row whose `grainSaleId == saleId` (`lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart:117`, `:132`) — newest booking first, since the data source requests `sort=created_at, order=desc`.
- No booking after all pages → `throw GrainSaleException` with the exact message at `lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart:149`; the controller surfaces it via `errorMessage` and returns `false`, so the sheet stays open and the SnackBar shows it — **no PATCH is issued**.
- A `BookingException` during lookup is mapped to `GrainSaleException` so the user sees the booking feature's own network/session messages.
- The data-source payload layer is untouched: `booking_slot_id` remains a required contract field (`lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:31`, `:252`) — only its *value* source changed.
- Wiring: both shells inject the booking data source (`lib/features/admin/presentation/admin_shell.dart:131`, `lib/features/manager/presentation/manager_shell.dart:132`).
- Reject uses the same endpoint and required field, so it is covered by the same guard automatically.

## 6. Bug 1: Files Changed

| File | Change |
|---|---|
| `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart` | removed `bookingSlotId` param and `?? saleId` fallback |
| `lib/features/grain_sales/domain/repositories/grain_sale_repository.dart` | removed `bookingSlotId` from the contract |
| `lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart` | added `bookingDataSource` dependency and `_resolveBookingSlotId` join + guard |
| `lib/features/admin/presentation/admin_shell.dart` | wired `BookingRemoteDataSourceImpl` |
| `lib/features/manager/presentation/manager_shell.dart` | wired `BookingRemoteDataSourceImpl` |
| `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart` | **unchanged** (contract layer) |

## 7. Bug 2: Root Cause

The chip label promised a two-status union, the query sent one status, and the number shown was the active query's total, not a per-chip count (investigation §4). The old code rendered `Pending / Received (count)` while `setFilter('pending')` sent only `status=pending` (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:302`), and the contract's `status` parameter is a single string — a truthful union in one request is impossible (`docs/bugs/grain-sales-review-and-filter-investigation.md:124`).

## 8. Bug 2: Fix Design

Option (a) from investigation §9.1 plus §9.2 "remove counts": four chips whose labels equal the single status they query, counts removed entirely to match the approved HTML (which has none):

| Chip | `setFilter` value | Request |
|---|---|---|
| All | `all` | `status` omitted (`null`) |
| Pending | `pending` | `status=pending` |
| Received | `received` | `status=received` |
| Paid | `paid` | `status=paid` |

No multi-value `pending,received` is ever sent. The controller's filter comment now documents the four values (`lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:32`). Approved/rejected remain reachable through list rendering and search but are deliberately not chips (approved HTML parity).

## 9. Bug 2: Files Changed

| File | Change |
|---|---|
| `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart` | `_buildFilterChip` lost the count parameter and `($totalCount)` rendering; chip row now All/Pending/Received/Paid (`:300`-`:306`) |
| `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart` | filter comment updated to the four values (`:32`) |

## 10. Test Changes

Six regression tests added to `test/features/grain_sales/grain_sale_test.dart` (investigation §10 items 1, 2, 3, 4, 6; item 7 already existed; item 5 N/A — option (a) chosen, no union query):

1. **Payload integrity (§10.1)** — real `FastApiGrainSaleRemoteDataSource` behind a `MockClient`; asserts the captured PATCH body has `booking_slot_id: 'b-1'` from the bookings join and **never** equals `s-1` (`:533`).
2. **Bookings join (§10.3)** — page containing `{id: 'b-9', grain_sale_id: 's-join'}` → review submits `b-9`, and the unrelated booking `b-other` is skipped (`:585`).
3. **No booking, repo level** — guard message thrown, review call count stays 0 (`:607`).
4. **Fallback removal (§10.2)** — controller returns `false`, sets the exact guard message, `reviewCallCount == 0`, local state untouched (`:824`).
5. **Filter query shape (§10.4)** — `setFilter('pending'|'received'|'paid')` → repository receives that single status; `setFilter('all')` → `null` (`:844`).
6. **Chip rendering (§10.6)** — four plain labels found, `Pending / Received` absent, no `(<digits>)` count suffix anywhere (`:1312`).

Fixture updates (not test logic changes): repository/controller/widget tests that reach review now seed a linked booking in `_MockBookingRemoteDataSource`; `_MockGrainSaleRemoteDataSource` records `lastBookingSlotId` and requested statuses. No test was deleted or weakened; the pre-existing SnackBar-on-review-failure test (`GrainSaleScreen shows visible error SnackBar on review failure`) still passes and now exercises a successful resolution followed by a real backend-detail error.

## 11. Regression Results

- Baseline (before any edit): `flutter test` → **313/313**, zero failures.
- After implementation: `flutter test` → **319/319 pass, "All tests passed!"** (313 + 6 new; zero failures; no unrelated test touched).
- Grain-sales file alone: 47/47.

## 12. Static Analysis and Build

- `flutter analyze` → **No issues found!** (0 issues, run after all edits).
- `flutter build apk --debug` → exit 0, `√ Built build\app\outputs\flutter-apk\app-debug.apk` — 175,129,754 bytes, sha256 `044c9cccf5a515a4eb826cd2abd67c0d04724f04ece3d303fcc1e2320f8c0796`.

## 13. Backend Changes

**None.** No file outside the declared write set was modified (gate G8, PASS): no backend, database, migration, OpenAPI, or contract files were touched, and the existing `docs/backend-requirements-admin-mobile.md` proposal set was not edited. Backend asks remain documented, unchanged, under the AGENTS.md golden rule.

## 14. Deviations from Investigation

- **§9.3 "the controller should own the lookup" → implemented one layer deeper, in `GrainSaleRepositoryImpl`.** Rationale: (i) the repository already orchestrates cross-source data (farmer enrichment via `Future.wait`), (ii) the presentation layer never gains a cross-feature dependency on the booking feature, and (iii) "correct by construction" is stronger — no caller of `GrainSaleRepository.reviewGrainSale` *can* pass a wrong slot because the parameter no longer exists. Screen callbacks (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:65`, `:89`) needed no change.
- **§9.2 "confirm with one authenticated round-trip before shipping"** was not possible (no credentials; Reticle cannot attach to this Flutter project) — downgraded to a documented residual risk with the exact confirmation ask (§15, §16), not silently dropped.
- **§9.1 offered options a/b/c for Bug 2** — option (a) with counts removed was selected per the approved HTML (investigation §6, §9.2), making §10's optional union test inapplicable.
- Bug 1's alternate wording in §9.1 ("This sale has no booking slot yet — review unavailable") was replaced by the exact message mandated by the implementation brief; same meaning, specified string.

## 15. Contract Clarifications Required

For Syed (backend), none of which blocked this Flutter fix:

1. **`booking_slot_id` identity:** confirm that `GrainSaleReviewRequest.booking_slot_id` expects `BookingPublic.id` (booking-slot row id). Evidence chain in §3; one authenticated review round-trip should confirm before release. *Backend API required — to be supplied by Syed (confirmation only).*
2. **Procure-created sales:** `POST /grain-sales/procure` creates sales with no booking row by construction, so review/reject for them is now client-blocked with the guard message. Define review-without-slot rules. *Backend API required — to be supplied by Syed.*
3. **Optional join removal:** add `booking_slot_id` directly to `GrainSalePublic` so clients stop joining `GET /bookings` (already listed in investigation §7 gap 1 and `docs/backend-requirements-admin-mobile.md`). *Backend API required — to be supplied by Syed.*
4. **Optional union filter:** multi-value `status` (e.g. `pending,received`) if a single-request union chip is ever required (investigation §7 gap 2). *Backend API required — to be supplied by Syed.*

## 16. Residual Risks

1. **Inferred id identity (medium):** if the backend ever interprets `booking_slot_id` as something other than `BookingPublic.id`, reviews would fail with the backend's own error message shown honestly in the SnackBar — never a fabricated id. Mitigation: §15.1 confirmation.
2. **Lookup paging cost (low):** resolution pages `GET /bookings` at `page_size=100` until match; very large booking tables slow the review tap. Mitigation future: §15.3 field removes the join.
3. **Multiple bookings per sale (low):** the first match in `created_at desc` order wins (most recent booking). Deterministic and documented; revisit if product wants another tie-break.
4. **No runtime UI verification (low):** Reticle cannot attach; widget tests cover the chips and SnackBar paths, but a human device pass of the two flows is still worthwhile.

## 17. Final Gate

- **G0** ledger lint — PASS (`LINT OK (3 warnings)`, all warnings are the accepted manual-gate type; evidence recorded in `GATES.md`).
- **G1** baseline recorded pre-edit (313/313, analyze 0) — PASS (evidence in `GATES.md`).
- **G2** booking slot id comes only from the bookings join, never the sale id — PASS (mechanical check, evidence in `GATES.md`).
- **G3** chips All/Pending/Received/Paid, no counts, matching controller comment — PASS (mechanical check).
- **G4** required §10 regression tests present — PASS (mechanical check).
- **G5** full suite green (319/319) and analyze clean (0 issues) — PASS (evidence in `GATES.md`).
- **G6** debug APK built — PASS (exit 0, sha256 recorded in `GATES.md`).
- **G7** report structure + mandated final line — PASS (mechanical check).
- **G8** write set confined to declared files — PASS (mechanical mtime scan).
- Gate summary: **9 met, 0 unmet, 0 abandoned.** Runtime caveat: Reticle unavailable for Flutter (no session possible); all claims rest on tests, analysis, APK build, and the live-contract evidence cited above.

IMPLEMENTATION COMPLETE — AWAITING HUMAN APPROVAL
