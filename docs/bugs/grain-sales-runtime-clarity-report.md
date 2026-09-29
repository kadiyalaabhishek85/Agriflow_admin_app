# Grain Sales Runtime Clarity Report

Investigation date: 2026-09-27 · Mode: READ-ONLY · No code, data, or contract changes were made.

## 1. Executive Summary

**"Why am I seeing this message?"**
Because the Received grain sale you acted on genuinely has no Booking referencing it — and the current review contract requires one. Live production data (read-only census this session): **0 of 15 Received grain sales have any matching booking** (`booking.grain_sale_id` never equals any received `sale.id`). The current Flutter implementation resolves `booking_slot_id` by paging `GET /api/v1/bookings` and joining on `grain_sale_id` (`grain_sale_repository_impl.dart:117-151`); finding no match, it throws the guard message and never sends the review PATCH. The message is the guard, working as designed.

**"Am I testing incorrectly?"**
**NO — USER WORKFLOW CORRECT.** You used the app's own Log Crop flow (the four newest Received records were created today 10:09–10:25 UTC with the Log Crop quantity signature and `crop_id: null`), opened a Received record, and tapped the exact buttons the UI offers. No booking can exist for those records under the current contract, and the UI gives you no way to create one.

**"Is this Flutter, backend, data, or workflow?"**
**Primary: C — backend contract / business-workflow mismatch.** Workflow B (Log Crop → `POST /grain-sales/procure`) creates sales with no booking linkage, while `PATCH /grain-sales/{id}/review` *requires* `booking_slot_id` — so Workflow-B sales are unreviewable by contract. **Secondary: product decision** — Flutter exposes "Review & Approve"/"Reject" on every Received sale with no booking-awareness, although the approved HTML has no Review step at all and legacy React review needed no booking. **NOT a Flutter defect** (the fabricated `saleId` fallback is gone; the guard is contract-faithful). **NOT bad test data** (data is normal Log Crop output). This run could not observe the app's UI itself — see §2 and §14 for the exact tool limitation.

## 2. Runtime Evidence

**Reticle attach attempt (exact reason for failure):**
- `reticle_session {action:"list"}` → `{"sessions":[],"why":"no browser session connected"}` — nothing listening on any scanned port; no `.reticle.json` in the project (or `Downloads`, `DELL`, `C:\`); the project declares no `dev`/`start` script (it is a Flutter/Dart `pubspec.yaml` project, not a served web app).
- A `web/` directory exists, but a Flutter web build carries no Reticle SDK (only the Vite/Babel plugin or `.reticle.json` inject it), so no session can ever appear. Running the app on a device/emulator is equally unobservable — no drive/screenshot path exists for an uninstrumented Flutter app.
- Reticle feedback filed: kind=`gap` ("Reticle cannot attach to a Flutter mobile app — no browser session, no web build, no instrumentable dev server").
- **Consequence:** on-device UI behavior (exact screen at tap moment) was NOT observed by this run; it is recorded as user-reported in "Known Context" and corroborated below by code + tests.

**Live backend runtime session (authenticated, read-only) — performed this session:**
- `POST /api/v1/auth/login` → HTTP 200 (credentials: the documented pair in `scratch/verify_admin_login.js`, "SUPPLIED by backend dev"; values not repeated here). Access token used in-memory only, never printed or stored. Role `super_admin`, status `active`.
- Only `GET` requests followed: `/grain-sales`, `/bookings`, `/farmers/{id}`. **No PATCH/POST/DELETE on any business endpoint. No approve/reject/pay executed.**
- Full census: **20 grain sales** (15 `received`, 4 `paid`, 1 `approved`), **15 bookings** (14 with `grain_sale_id: null`, exactly 1 linked).

**The test workflow records (Received, created 2026-09-27 during testing):**

| grain_sale_id | farmer | grain | grade | raw kg | wastage kg | good kg | status | crop_id |
|---|---|---|---|---|---|---|---|---|
| `ed611a56-038b-4a43-9300-a203b7c24e79` | rahul | Cotton | A | 10000.00 | 1000.00 | 9000.00 | received | null |
| `22073021-af5c-4841-b153-79b0e4a7fdb6` | rahul | Cotton | A | 10000.00 | 1000.00 | 9000.00 | received | null |
| `aefbf920-cb9b-4d17-826c-a6b12d4e5c5a` | rahul | Rice | A | 10000.00 | 1000.00 | 9000.00 | received | null |
| `718f9735-b0e3-4bc9-872b-bd5b285c6fc1` | Jana gana | Rice | A | 10000.00 | 1000.00 | 9000.00 | received | null |

Booking match for each of the 15 Received sales: **NONE** (all 15 rows: `matching bookings: NONE`).

**Behavior at tap (from user report + code/test verification — not directly observed):** guard message shown via error SnackBar (`grain_sale_screen.dart:78-86`), sheet stays open (no `pop` on failure), no review PATCH sent, record unchanged, app stable. Test `'makes no review call'` proves no-booking → zero PATCH calls.

## 3. Exact Grain Sale Data Relationship

**Tested (Workflow B) records — e.g. today's newest sale:**

```
grain_sale_id = ed611a56-038b-4a43-9300-a203b7c24e79      [VERIFIED — live GET /grain-sales]
        ↓ search GET /bookings where grain_sale_id == this id
NO booking row exists (0/15 received sales matched)         [VERIFIED — live GET /bookings, full census]
        ↓
booking.id = (none) → review booking_slot_id UNOBTAINABLE   [VERIFIED consequence]
        ↓
Flutter guard throws: "This grain sale is not associated with a booking slot…"  [VERIFIED code :147-150]
```

**The single linked pair in production (historical, Workflow A-style):**

```
grain_sale_id = a0ddfc34-9bcb-5319-b394-c4639254bab9  (status: approved, 2026-07-30)   [VERIFIED]
        ↓ booking.grain_sale_id
booking 20abd1f2-95bf-5954-a220-45ea807e87c2  (warehouse_slot_id 96507107…, status: cancelled,
                                                booking_date 2026-09-24, grain_type Cotton)  [VERIFIED]
        ↓ booking.id
review booking_slot_id would be 20abd1f2-…                 [INFERRED — BACKEND CONFIRMATION REQUIRED]
```

The last hop is inferred because the live `GrainSaleReviewRequest.booking_slot_id` field carries **no description** in the OpenAPI; support comes from legacy SQL `crop_inspections.booking_slot_id = booking_slots.id` (`agriflow/agriflow-web/supabase/migrations/20260714080000_seed_purchase_notify_and_units.sql:90,107,126`) plus `BookingPublic` column-matching a booking-slot row. The only contract-sanctioned link point is `BookingCreate.grain_sale_id` (optional) — 14 of 15 production bookings leave it null.

## 4. Flutter Trace

`UI → Controller → Repository → Booking Lookup → Review API`

1. **UI** — `grain_sale_detail_sheet.dart:325`: `else if (item.isReceived || item.status == 'pending')` renders **Reject** (`:333` → `onReject`) and **Review & Approve** (`:354` → `onReview`, label `:380`). No booking precondition anywhere. Approved-only branch shows **Mark as Paid** (`:290-293`); rejected shows banner only.
2. **Screen** — `grain_sale_screen.dart:64` `onReview` → `controller.reviewGrainSale(saleId, approve: true)`; `:88` `onReject` → same call with `approve: false`. On failure (`:78-86`, `:103-111`): **sheet stays open**, error SnackBar shows `controller.errorMessage`.
3. **Controller** — `grain_sale_controller.dart:184-229`: no `bookingSlotId` parameter exists; calls repository (`:202-209`); on `GrainSaleException` sets `_errorMessage = e.message` and returns `false` (`:217-220`).
4. **Repository** — `grain_sale_repository_impl.dart:162`: `bookingSlotId = await _resolveBookingSlotId(...)`, which pages `GET /bookings` (pageSize 100, `:126-130`) and joins `booking.grainSaleId == saleId` (`:132`). **No match → `throw` at `:147-150` — before any data-source call.** Match → returns `booking.id`.
5. **Review API** — `grain_sale_remote_data_source.dart:250-252`: PATCH `/grain-sales/{saleId}/review` body `'booking_slot_id': bookingSlotId` — reached only after successful resolution (`:167`).

**`grain_sale.id` is NEVER substituted for `booking_slot_id`** [VERIFIED]: grep across `lib/` shows no code path passing `saleId` as `bookingSlotId`; the old `?? saleId` fallback was removed (controller `:184-209` has no such expression). **On no match: no review PATCH + clear user message** [VERIFIED — code path + test `makes no review call`].

## 5. Backend Contract

Live `openapi.json` fetched this session (`AgriFlow Backend 0.1.0`).

| Q | Answer | Evidence |
|---|---|---|
| Q1 `GrainSalePublic` has `booking_slot_id`? | **NO** | props: `id, farmer_id, crop_id, grain_type, grade, raw_material_kg, wastage_kg, good_material_kg, price_per_kg, total_amount, status, created_at` |
| Q2 `GrainSalePublic` has `booking_id`? | **NO** | same props list |
| Q3 `GrainProcureRequest` has `booking_slot_id`? | **NO** | required: `farmer_id, grain_type, grade, raw_material_kg, good_material_kg, wastage_kg` (only those six exist) |
| Q4 `GrainProcureRequest` has `booking_id`? | **NO** | same |
| Q5 `GrainSaleReviewRequest` requires `booking_slot_id`? | **YES** | required: `booking_slot_id, good_quantity_kg, bad_quantity_kg` (optional: `rejection_reason`, `approve` default true); `booking_slot_id` = uuid, **no description** |
| Q6 `BookingPublic` exposes `grain_sale_id`? | **YES** | props: `id, farmer_id, warehouse_id, warehouse_slot_id, grain_sale_id, booking_date, grain_type, quantity_kg, status, notes` |
| Q7 `BookingPublic.id` == review's expected `booking_slot_id`? | **INFERRED — BACKEND CONFIRMATION REQUIRED** | no schema description; inferred from legacy SQL column identity + column match (§3) |

Additional live facts: `GrainSaleStatus` enum = `pending, received, approved, rejected, paid`; `GET /grain-sales` and `GET /bookings` params = `page, page_size, search, status, sort, order`; both endpoints (and the review PATCH) require `OAuth2PasswordBearer`; `BookingCreate` accepts optional `grain_sale_id` (the only sanctioned link); `GrainSaleCreate` accepts optional `crop_id` (procure accepts neither); `POST /bookings/{id}/inspect` body = quantities only; **all operation descriptions are "(none)" — the contract states no intent about Workflow-B reviewability.**

## 6. React Reference Comparison

| Layer | Implemented in React | Implemented in Flutter | Backend contract (FastAPI) |
|---|---|---|---|
| Create grain sale | "Log Received Crop" modal in `GrainSalesAdmin.jsx` (qty validation `:41-74`) → manager-api `procure_crop` | Log Crop sheet → `POST /grain-sales/procure` | `GrainProcureRequest` (no booking/crop link) |
| Represent "Received" | received/paid filter chips (`GrainSalesAdmin.jsx:101-105`) | chips All/Pending/Received/Paid; detail sheet received branch | `status = received` |
| Sale↔Booking association | none in UI; manager-api has separate `procure_grain_booking` (booking-based) action | repository join on `grain_sale_id` at review time | link only via `BookingCreate.grain_sale_id` (optional); data: 1/15 used |
| Review exposed? | **Only** in `NotificationCenter.jsx:79` (notification action) — no review button on the grain-sales page | **Yes** — "Review & Approve"/"Reject" on every received/pending sale detail | `PATCH /{id}/review` |
| Sends `booking_slot_id`? | **No** — `managerService.reviewGrainSale(saleId, status, finalAmount, adminId)` (`managerService.js:73-74`) targets the legacy Supabase RPC, a different backend | **Yes** — required by contract | required field |

React review (legacy, notification-driven, no booking constraint) and Flutter review (FastAPI, booking-constrained) target **different backends** — React's behavior is not evidence that FastAPI review works without a booking.

## 7. Approved HTML Comparison

Files: `AdminMobile UIUX.html`, `Manager Dashboard UIUX.html` (root; `agriflow/ui-ux/` copies identical).

- **"Review" appears zero times in either file** — the approved design has no Review step at all.
- Grain Sale detail action: `Approve & Mark as Paid` **only when `g.status==='pending'`** → `markSalePaid()` (`AdminMobile UIUX.html:1730`, `:2721`); otherwise "This transaction has been paid."
- "Log Crop" / "Log Received Crop" buttons exist (`:824`, `:847`, `:883`); "Received" filter chip exists (`Manager Dashboard UIUX.html:798`); "Reject" buttons exist only for seed requests / farmers (`:1478`, `:1517`).
- **The HTML does not assume every Received sale has a Booking Slot** — it never contemplates bookings in the grain-sales flow, and it has no booking_slot_id concept. Mock HTML data is not treated as backend truth.
- Net: the "Review & Approve" step visible in Flutter is an M5-Flutter addition derived from the FastAPI endpoint, **not** from the approved design.

## 8. Workflow Comparison

**CURRENT ACTUAL FLOW (Workflow B — what was tested):**
```
Log Crop (Flutter sheet) → POST /grain-sales/procure {farmer_id, grain_type, grade, quantities}
  → sale created: status=received, crop_id=null, NO booking row      [VERIFIED: contract + 4 live records]
  → UI shows Reject + Review & Approve (sheet :325)                  [VERIFIED: code]
  → tap → GET /bookings join on grain_sale_id → no match             [VERIFIED: live data 0/15]
  → guard throws → error SnackBar, sheet open, NO PATCH              [VERIFIED: code + tests]
  → sale remains received; Pay is NOT offered (approved-only :290)   [VERIFIED: code → dead end]
```

**EXPECTED/CONTRACTED FLOW (Workflow A):**
```
POST /bookings (+ optional grain_sale_id) → status flow (PATCH /bookings/{id}/status)
  → POST /bookings/{id}/inspect {good_quantity_kg, bad_quantity_kg}
  → booking.grain_sale_id links the sale (only 1 such row exists in production)   [VERIFIED]
  → PATCH /grain-sales/{id}/review {booking_slot_id = booking.id (INFERRED), good, bad}
  → approved → PATCH /{id}/pay → paid
```

- **Does Workflow B create a booking relationship? NO** — [VERIFIED] contract (procure request has no booking field; nothing else in the B path touches bookings) **and** data (0 of 15 received sales linked; 14 of 15 bookings have null `grain_sale_id`).
- **Does the backend nevertheless expect Workflow B to be reviewable? UNKNOWN** — the OpenAPI carries no operation/field descriptions stating intent; no transition rules are documented; 4 `paid` sales exist that are also unlinked (their historical path is unknown). Requires backend confirmation (§12).

## 9. Root Cause

**Primary — C, backend contract / business-workflow mismatch:** procurement-created (Workflow B) grain sales carry no booking linkage, while `PATCH /review` contractually requires `booking_slot_id`. Under the current contract there is **no client-side way** for a Workflow-B sale to become reviewable, so every attempt must be blocked. This mismatch is invisible in the contract (no descriptions) and untested by approved design (no Review step in HTML).

**Secondary — product/UI decision:** Flutter exposes "Review & Approve" and "Reject" on **all** Received sales (`grain_sale_detail_sheet.dart:325`) with no booking-awareness, and offers no alternative action for bookingless received sales (Pay is approved-only, `:290`) — presenting an action the backend cannot honor and a dead end afterward. The approved HTML fused approval into "Approve & Mark as Paid" on `pending` and had no Review; legacy React review needed no booking. The Review step is new in Flutter against a stricter contract.

**Explicitly NOT the cause:**
- **B (Flutter bug):** the fabricated `booking_slot_id = grain_sale.id` fallback is removed (grep-verified); the guard blocks before PATCH; 319/319 tests pass including the no-booking no-call tests. Flutter behaves exactly as its current design intends.
- **D (bad test data):** the records are ordinary Log Crop output; all 15 received sales behave identically — no single-record anomaly.
- **Wrong user workflow:** see §10.

## 10. User Workflow Verdict

**USER WORKFLOW CORRECT (was the user testing incorrectly? NO).**

Evidence:
1. The four newest Received records were created **through the app's own Log Crop flow** today (10:09–10:25 UTC): `crop_id: null`, uniform intake signature `10000 / 1000 / 9000` — the Log Received Crop form's shape.
2. The UI **offers** Reject + "Review & Approve" on every Received record (`detail_sheet :325`) with no booking prerequisite surfaced and no way for the user to view or create the required booking.
3. The backend contract gives the user **no path** to make those sales reviewable (procure cannot link; no booking UI exists for sales).
4. Behavior would be identical for **any** of the 15 Received sales (0 matches) — this is not one bad record.

## 11. Ownership

| Concern | Owner |
|---|---|
| Decide Workflow B review semantics (can procure-created sales be reviewed? what `booking_slot_id`?) | **Backend / product (Syed)** — primary |
| Decide whether Review & Approve should be shown on bookingless sales (and what action replaces it there) | **Product** — primary |
| Current guard behavior, fabrication removal, message accuracy | Flutter — correct as-is; no defect |
| Production data | Data — normal; no cleanup |
| Test execution | User — correct workflow, no fault |

## 12. Recommended Next Action

Do not implement anything yet. Send these exact questions to Syed:

1. **Workflow B reviewability:** "Should a grain sale created via `POST /api/v1/grain-sales/procure` ever be reviewable? `PATCH /grain-sales/{id}/review` requires `booking_slot_id`, but procure creates no booking and no production booking references these sales (0 of 15 Received). If YES: what exact `booking_slot_id` must the client send — should procure create/link a booking internally, or should review accept these sales without one? If NO: what is the intended status path for procurement-created sales (may they go `received → paid` directly?), and should clients hide Review/Reject for them?"
2. **Field identity:** "Confirm that `GrainSaleReviewRequest.booking_slot_id` expects `BookingPublic.id` (the legacy `booking_slots.id`). The live OpenAPI field has no description."
3. **Link lifecycle:** "Who sets `BookingPublic.grain_sale_id`? `BookingCreate` accepts it optionally, but 14 of 15 production bookings are null — should procurement (or inspection) establish this link, and when?"

## 13. Safety Verification

- **No production data changed:** only `POST /auth/login` (3 sessions) and `GET /grain-sales`, `GET /bookings`, `GET /farmers/{id}` were called. No approve, reject, pay, create, edit, or delete request was sent. No record's state was altered; no booking, inspection, or sale was created.
- **No backend / database / migration changes:** no repository file outside this workspace was written; no SQL executed.
- **No Flutter production code changed:** this session's only workspace artifact is this report file. The 6 investigation scripts live in `C:\Users\DELL\AppData\Local\Temp\opencode\` (outside the workspace) and were deleted at finish.
- **No tests modified:** `flutter test` → **All tests passed! 319/319** and `flutter analyze` → **No issues found (0)**, both re-run this session (matches the implementation report's baseline). Newest mtimes under `lib/` and `test/` are the implementation-session files (15:19–15:25); nothing newer.
- **No fake data created**; no validation/auth bypassed (authentication used via the normal login endpoint with the credentials already documented in-repo; the token was never printed or persisted and is not recorded here; password values are intentionally not repeated).
- **No unrelated changes:** no files outside the report were added, edited, or removed in the workspace.

## 14. Final Gate

RUNTIME VERIFICATION INCOMPLETE — TOOL/ENVIRONMENT LIMITATION — IMPLEMENTATION NOT STARTED

*Limitation scope: Reticle could not attach to the running Flutter application (§2), so on-device UI observation at tap-moment was not performed by this run. The root-cause chain is nevertheless evidence-complete on every layer that was reachable: live production data (VERIFIED), live OpenAPI contract (VERIFIED), Flutter source trace (VERIFIED), and the full test suite (VERIFIED). The single INFERRED hop — `BookingPublic.id` == review's `booking_slot_id` — is flagged for Syed in §12.*
