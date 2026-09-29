# Grain Sales Review & Filter Investigation — Production Bugs

**Target Module:** Grain Sales / Crop Procurement (`lib/features/grain_sales/`)
**Bugs Investigated:**
- Bug 1 — "Booking slot not found" when tapping **Review & Approve**
- Bug 2 — "Pending / Received (0)" filter chip shows an empty list
**Backend Authority:** live FastAPI OpenAPI at `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json` (fetched during this investigation; 98 paths, `info.version` 0.1.0)
**Date:** September 27, 2026
**Status:** Investigation only — no production, backend, test, or contract files were modified.

---

## 1. Executive Summary

### Bug 1 verdict — root cause: client-side ID fallback sends the sale UUID where a booking-slot UUID is contractually required (VERIFIED in code + live contract)

- The live contract requires `booking_slot_id` (uuid) in `GrainSaleReviewRequest` — `required: ["booking_slot_id", "good_quantity_kg", "bad_quantity_kg"]` (see `live_openapi.json` line 1, schema `GrainSaleReviewRequest`; identical in `openapi_dump.json:1`).
- The list response `GrainSalePublic` does **not** contain `booking_slot_id` or `booking_id` (live schema property list verified during this investigation), so `GrainSaleItem.fromJson` always parses `bookingSlotId` as `null` (`lib/features/grain_sales/domain/entities/grain_sale_item.dart:62`).
- The Review screen callback never passes a slot id (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:65`), so the controller executes the fallback chain `bookingSlotId ?? existingItem?.bookingSlotId ?? saleId` (`lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:200`) — the last term always wins and the **sale id is sent as `booking_slot_id`** (`lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:252`).
- The backend rejects the unknown slot and returns its `detail`, which Flutter surfaces verbatim as the SnackBar message (`lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:96`, `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:79`). The exact string "Booking slot not found" appears **nowhere in the Flutter/Dart code or the OpenAPI document**; its lineage is the backend's legacy SQL, where `SELECT * INTO v_slot FROM booking_slots WHERE id = p_slot_id; IF NOT FOUND THEN ... 'Booking slot not found'` (`agriflow/agriflow-web/supabase/migrations/20260720151000_remove_razorpay_and_procurement_update.sql:144` and `:268`).

**One-line cause:** the app has no authoritative sale→booking-slot lookup wired in, so it fabricates a slot id from the sale id, and the backend 404s every Review & Approve attempt.

### Bug 2 verdict — root cause: the chip label promises a two-status union, the query requests one status, and the count shown is the active query's total (VERIFIED in code + live contract + approved HTML)

- Chip label "Pending / Received" is bound to filter key `'pending'` (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:302`), which is sent as the single query parameter `status=pending` (`lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:64`, `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:147`).
- The live contract accepts `status` as a **plain single string** with no enum and no multi-value documentation (`live_openapi.json` line 1, `GET /api/v1/grain-sales` parameters); the status universe is `GrainSaleStatus = pending | received | approved | rejected | paid` (`openapi_dump.json:1`).
- The chip's count is `controller.pagination.total` — the total of whatever query is currently active — rendered only while the chip is active (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:183`, `:300`, `:302`, `:304`).
- Production rows visible under **All** are `received` (not `pending`), so `status=pending` matches nothing → `total = 0` → "Pending / Received (0)" + `DashboardEmptyView` (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:329`).

**One-line cause:** a single-equality `status=pending` query cannot implement a "pending ∪ received" label; the "(0)" is the honest total of the wrong query.

Both findings were partially foreshadowed by the internal deep review: *"grain sales label a `status=pending` query as 'Pending / Received' so `received`, `approved` and `rejected` rows are only reachable under All"* (`docs/deep-review/flutter-03-farmers-visits-grain-booking.md:238`), with the recommendation to split the chip and stop labelling every chip with the unfiltered `pagination.total` (`docs/deep-review/flutter-03-farmers-visits-grain-booking.md:351`).

### Investigation method & limits

| Source | Used | Result |
|---|---|---|
| Live FastAPI OpenAPI (fetched this session) | yes | authoritative for all contract claims below |
| Flutter source (`lib/`, `test/`) | yes | full static trace of both flows |
| Legacy React/Supabase reference (`agriflow/agriflow-web/`) | yes | review-flow lineage + error-string lineage |
| Approved HTML prototypes | yes | intended chips/labels/counts |
| Reticle runtime inspection | **unavailable** | `reticle_session list` returned `sessions: []` — no browser session / nothing listening on scanned ports; this is a Flutter app with no web dev script. All findings are static + contract evidence. |
| Authenticated live API calls | **not attempted** | no test credentials available; no production writes attempted |

---

## 2. Reproduction

### Bug 1 — "Booking slot not found"
1. Sign in as Admin or Manager → open **Grain Sales** (Procurement Desk).
2. Tap a sale whose status pill is `Received` (or create one via **Log Crop** → `POST /grain-sales/procure` → status `received`).
3. In the Procurement Details sheet tap **Review & Approve** (`grain_sale_detail_sheet.dart` button key `grain_sale_review_approve_btn`, line 353).
4. **Observed:** red SnackBar "Booking slot not found"; sheet stays open; status unchanged.
5. **Expected:** review succeeds (`received` → `approved`) per the documented state machine (`docs/bugs/grain-sale-approve-payment-investigation.md:45`), or a precise client-side validation error — never a 404 about an id the client invented.

### Bug 2 — "Pending / Received (0)"
1. Open **Grain Sales**; default chip **All** shows e.g. `All (16)` with rows whose pills read `Received`.
2. Tap **Pending / Received**.
3. **Observed:** chip renders `Pending / Received (0)` (count appears only on the active chip, `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:183`) and the body shows `No Grain Sales Found` (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:327`).
4. **Expected:** the union the label promises (pending **and** received rows), with a count that matches what the chip lists.

---

## 3. Bug 1 — Review & Approve sends a fabricated `booking_slot_id`

### 3.1 Verified end-to-end trace (code)

| # | Step | Location |
|---|---|---|
| 1 | Sheet renders **Review & Approve** for `isReceived \|\| status == 'pending'` | `lib/features/grain_sales/presentation/widgets/grain_sale_detail_sheet.dart:325`, button at `:353`, label at `:380` |
| 2 | Screen callback calls `reviewGrainSale(saleId: saleItem.id, approve: true)` — **no `bookingSlotId` argument** | `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:65` |
| 3 | Controller fallback chain `bookingSlotId ?? existingItem?.bookingSlotId ?? saleId` | `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:200` (parameter declared `String?` at `:186`) |
| 4 | `existingItem.bookingSlotId` is always `null` for server data: `fromJson` reads `(json['booking_slot_id'] ?? json['booking_id'])?.toString()` and **neither key exists** on `GrainSalePublic` (live schema verified) | `lib/features/grain_sales/domain/entities/grain_sale_item.dart:62`; parsed at `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:167` |
| 5 | Repository contract marks `bookingSlotId` as `required String` (non-null, so nothing downstream can refuse) | `lib/features/grain_sales/domain/repositories/grain_sale_repository.dart:32`; impl pass-through `lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart:112`, `:121` |
| 6 | Data source sends `PATCH /grain-sales/{sale_id}/review` with body `{'booking_slot_id': slotId, ...}` | `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:252` |
| 7 | Backend 404s: `_handleErrorResponse` reads `body['detail']` → message; 404 → `GrainSaleNotFoundException` | `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:96`, `:118` |
| 8 | Controller stores `e.message` → screen shows it in an error SnackBar | `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:221`; `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:79` |

Because step 4 is structurally always `null` and step 2 never supplies a value, **step 3 always degrades to `saleId`** — the failure is deterministic for every sale, not data-dependent.

### 3.2 Verified contract facts (live OpenAPI, fetched this session)

- `PATCH /api/v1/grain-sales/{sale_id}/review` request body: `GrainSaleReviewRequest`, **required = `booking_slot_id`, `good_quantity_kg`, `bad_quantity_kg`**; `booking_slot_id` is `type: string, format: uuid`.
- Schema description: *"Ports the verified inspect_crop -> procure_crop flow (Master Plan Module 8): a manager records good/bad quantity from the booking slot's crop_inspection, which determines wastage_kg and good_material_kg, then the sale moves to `approved`."*
- `GrainSalePublic` (GET list response) properties: `id, farmer_id, crop_id, grain_type, grade, raw_material_kg, wastage_kg, good_material_kg, price_per_kg, total_amount, status, created_at` — **no booking-slot field of any kind**.
- `GrainSaleStatus` enum: `pending, received, approved, rejected, paid`.
- The error text "Booking slot not found" is **not** in the OpenAPI document (string search across the fetched JSON returned only property titles "Booking Slot Id").

### 3.3 How a correct slot id could be obtained (contract-supported)

- `GET /api/v1/bookings` returns `BookingPublic` rows containing **`grain_sale_id` (uuid | null)** plus the booking row's own `id` — an authoritative sale↔booking link exists today, with no new endpoint needed.
- `POST /api/v1/bookings/{booking_id}/inspect` is the only operation returning `CropInspectionPublic` (which carries `booking_slot_id`), so inspections themselves are not readable by the admin list flow.
- **INFERRED (strong evidence chain, not directly executed):** `booking_slot_id` == `BookingPublic.id`. Evidence: (a) legacy SQL `inspect_crop(p_slot_id ...)` looks up `booking_slots WHERE id = p_slot_id` and inserts `crop_inspections (booking_slot_id, ...)` with that same `p_slot_id` (`agriflow/agriflow-web/supabase/migrations/20260714080000_seed_purchase_notify_and_units.sql:90`, `:107`, `:126`); (b) the legacy error string is raised when `booking_slots` has no row for the given id (`agriflow/agriflow-web/supabase/migrations/20260720151000_remove_razorpay_and_procurement_update.sql:142`); (c) FastAPI's `BookingPublic` exposes exactly the legacy `booking_slots` columns, including `warehouse_slot_id` (a distinct concept) and `grain_sale_id`; (d) the FastAPI inspect path names the same entity `booking_id`. Confirmation with one authenticated `GET /bookings` + review round-trip is still outstanding (no credentials in this session).
- **Open contract question for Syed:** sales created by `POST /grain-sales/procure` (`GrainProcureRequest` has no booking/crop linkage) have **no booking row by construction**. What `booking_slot_id` should review receive for them — does the backend auto-associate a slot, or is review only valid for booking-created sales? Backend API required — to be supplied by Syed.

### 3.4 Why the test suite does not catch it

- Controller review tests call `reviewGrainSale` without a slot id and assert only local state transitions against mocks that accept any payload (`test/features/grain_sales/grain_sale_test.dart:582`, `:599`, `:617`).
- The repository "delegates" test passes a dummy `'slot-1'` and never asserts what the data source actually sent (`test/features/grain_sales/grain_sale_test.dart:417`).
- No test captures the PATCH request body, so the fabricated-id path is invisible to the suite.

---

## 4. Bug 2 — "Pending / Received (0)" empty filter

### 4.1 Verified trace (code)

| # | Step | Location |
|---|---|---|
| 1 | Chips row: `All`/`'all'`, **`'Pending / Received'`/`'pending'`**, `Paid`/`'paid'` — all three receive the same `controller.pagination.total` | `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:300`, `:302`, `:304` |
| 2 | Count text rendered **only on the active chip**: `isActive ? '$label ($totalCount)' : label` | `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:183` |
| 3 | `setFilter('pending')` → `loadSales()` with `_currentFilter != 'all' ? _currentFilter : null` | `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:123`, `:64` (same at `:102` for load-more) |
| 4 | Data source appends `status=pending` (lower-cased, single value; 'all' omitted) | `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart:147` |
| 5 | Response pagination replaces `_pagination` → `total` = count of **pending-only** matches | `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:68` |
| 6 | Empty result → `No Grain Sales Found` body | `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:327` |

### 4.2 Why the numbers look contradictory

- Under **All**: server returns every status (16 rows, pills = `Received`) → chip shows `All (16)`.
- Under **Pending / Received**: server applies `status = 'pending'` equality; production rows are `received` → 0 matches → chip shows `(0)` and an empty body.
- The label therefore promises `pending ∪ received` while the query executes `{pending}`. The count is internally consistent with the (wrong) query, which is why the UI looks "broken but arithmetic-correct".

### 4.3 Contract constraints (live)

- `GET /api/v1/grain-sales` `status` parameter: single `string | null` — **no enum, no documented multi-value or comma-separated form** (`live_openapi.json` line 1).
- The backend cannot be *proven* to accept `pending,received` from the contract; nothing in the OpenAPI suggests it does.
- A truthful union today can only be built from **existing** endpoints: issue the two single-status queries (`status=pending`, `status=received`) and merge client-side, or fetch unfiltered and filter locally (trade-off: pagination correctness). A single-request multi-status filter would be a backend feature: **Backend API required — to be supplied by Syed.**

### 4.4 Prior internal finding

The deep review already flagged this exact defect and its count flaw, recommending a split into the enum values and removal of the unfiltered-total labelling (`docs/deep-review/flutter-03-farmers-visits-grain-booking.md:238`, `:351`). It was not yet implemented when these bugs were reported.

---

## 5. React / legacy reference implementation

Cross-check against `agriflow/agriflow-web/` (the legacy web stack the FastAPI backend was ported from):

- **Legacy review never required a booking-slot id.** `managerService.reviewGrainSale(saleId, status, finalAmount, adminId)` (`agriflow/agriflow-web/src/services/managerService.js` line 73) → Supabase RPC `review_grain_sale` with `{p_sale_id, p_status, p_final_amount, p_admin_id}` (`agriflow/agriflow-web/supabase/functions/manager-api/index.ts` line 253). The slot requirement is new in the FastAPI port's `GrainSaleReviewRequest`.
- **Legacy flow was slot-centric elsewhere:** booking creation inserts `booking_slots` and returns its id (`.../20260720151000_remove_razorpay_and_procurement_update.sql:100`); approval and procurement RPCs look the slot up by id and raise **'Booking slot not found'** when absent (`:144`, `:268`); inspection writes `crop_inspections.booking_slot_id` (`.../20260714080000_seed_purchase_notify_and_units.sql:126`).
- **Error-string lineage (VERIFIED in repo, INFERRED as the FastAPI source):** the phrase exists only in those legacy SQL functions — it is absent from all Dart code, all HTML prototypes, and the OpenAPI document. The backend's 404 `detail` almost certainly carries this legacy string through the FastAPI port; the Flutter side merely relays `detail` (verified) — this session could not execute an authenticated review call to capture the literal response body.
- **Legacy admin UI had no per-sale review action wired to a slot id either** — the earlier internal report's roadmap step "Connect Review Action to Backend Contract" (`docs/bugs/grain-sale-approve-payment-investigation.md:147`) produced the current Flutter implementation, which satisfied the endpoint call but not the slot-identity contract.

---

## 6. Approved HTML prototypes

Root copies are byte-identical (SHA-256 verified this session) to the `agriflow/ui-ux/` reference copies for both Admin and Manager.

- **Admin — `AdminMobile UIUX.html` (line 830):** grain-sales chip row is `All` / `Pending Payment` (`data-filter="pending"`) / `Paid` (`data-filter="paid"`) — **no counts** on these chips (counts exist only in the seed-purchase section, ids `sp-count-*`, line 655).
- **Manager — `Manager Dashboard UIUX.html` (line 796):** chip row is `All` / **`Received`** (`data-filter="pending"`) / `Paid` (line 798) — again **no counts**.
- **Prototype behaviour:** client-side single-equality filter `g.status === filter` over mock rows (`AdminMobile UIUX.html` line 1690); wire-up `wireChipRow('gs-chip-row', ...)` (Admin line 2253, Manager line 3005).
- **Deviation by the Flutter build:**
  1. Label: neither approved screen uses "Pending / Received" (Admin: "Pending Payment"; Manager: "Received"). Flutter merged both into a label that over-promises relative to its query.
  2. Counts: the approved chips carry none; Flutter added counts and wired all three chips to the **same** active-query total, which makes inactive chips stateless and the active chip's count misleading for any union label.
  3. Filter semantics: the prototypes filter single statuses against mock data — they never claimed a union either, so the union expectation exists only in the Flutter label.

---

## 7. Backend Contract (live OpenAPI facts)

Verified by fetching `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json` during this session (saved copy: local `live_openapi.json`; cache comparison: `openapi_dump.json:1` — 94 paths vs live 98, **identical** on every grain-sale fact below).

| Fact | Value |
|---|---|
| Review endpoint | `PATCH /api/v1/grain-sales/{sale_id}/review`, body `GrainSaleReviewRequest` |
| Review required fields | `booking_slot_id` (uuid), `good_quantity_kg`, `bad_quantity_kg` (`approve` defaults `true`, `rejection_reason` nullable) |
| List response | `GrainSalePublic` — no `booking_slot_id`, no `booking_id`; has nullable `crop_id` |
| Status query param | single `string`, no enum, no multi-value documented |
| Status universe | `pending, received, approved, rejected, paid` |
| Sale↔booking link | `GET /api/v1/bookings` → `BookingPublic.grain_sale_id` (uuid \| null) + `id` |
| Inspection read | only `POST /bookings/{booking_id}/inspect` returns `CropInspectionPublic`; no admin GET for inspections |
| Procure body | `GrainProcureRequest` = farmer_id, grain_type, grade, raw/good/wastage kg — **no booking/crop linkage** |
| Security | global `OAuth2PasswordBearer` only — **no per-route roles in the contract** (RBAC unverifiable from the contract; consistent with `docs/deep-review/flutter-03-farmers-visits-grain-booking.md:333`) |

### Contract gaps (all marked per AGENTS.md golden rule)

1. `GrainSalePublic` exposes no booking-slot id → clients must join via `GET /bookings`. Exposing `booking_slot_id` directly on the sale would remove the guess: **Backend API required — to be supplied by Syed.**
2. No multi-value `status` filter → a truthful one-request "Pending / Received" chip is impossible today: **Backend API required — to be supplied by Syed.**
3. Review semantics for `procure`-created sales (no booking row exists by construction) are undefined in the contract: **Backend API required — to be supplied by Syed.**
4. Runtime error `detail` strings (e.g. "Booking slot not found") are not represented in the schema — informational only; no change demanded.

---

## 8. Ownership Matrix

| # | Item | Owner | Type |
|---|---|---|---|
| 1 | Remove `?? saleId` fallback; never submit a fabricated `booking_slot_id` (`lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:200`) | Flutter app team (this repo) | Code fix |
| 2 | Resolve the real slot via `GET /bookings` → `grain_sale_id` match, pass it through screen → controller; clear client-side message when no booking exists | Flutter app team | Code fix |
| 3 | Chip semantics: split/relabel to match single-status queries, or union-query client-side; stop rendering one active-query total as if it were per-chip counts (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:183`, `:300-304`) | Flutter app team + Design sign-off (approved HTML has no counts) | Code fix / UX decision |
| 4 | `booking_slot_id` on `GrainSalePublic`; multi-status `status` param; review-without-slot rules for procure-created sales | Syed (backend) | **Backend API required — to be supplied by Syed.** |
| 5 | Regression tests: payload assertions for review; filter/count widget tests | Flutter app team / QA | Tests |
| 6 | Per-route RBAC visibility in the contract | Syed (backend) | Documented gap (pre-existing) |

---

## 9. Recommended Fix

> Recommendations only. Nothing below has been implemented; no file outside this report and `GATES.md` was written during the investigation.

### Bug 1 (priority: production blocker)
1. **Delete the fallback** `?? saleId` in `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart:200`. Make `bookingSlotId` genuinely required at the controller boundary or fail fast with a clear message ("This sale has no booking slot yet — review unavailable").
2. **Resolve the slot authoritatively** before review: query `GET /api/v1/bookings` and match `grain_sale_id == sale.id`; use that row's `id` as `booking_slot_id` (inference documented in §3.3 — confirm with one authenticated round-trip before shipping).
3. **Wire the value through:** the sheet/screen currently omits it (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:65`); the controller should own the lookup so every caller is correct by construction.
4. **Handle the no-booking case explicitly** (procure-created sales): show an informative in-sheet error instead of firing a request that cannot succeed; log the open contract question to Syed (§7 gap 3).
5. **Optional contract ask:** add `booking_slot_id` to `GrainSalePublic` to remove the join — **Backend API required — to be supplied by Syed.**

### Bug 2 (priority: correctness/UX)
1. **Make the label and query agree.** Minimal truthful options using existing endpoints only:
   - a) Relabel chips to the single statuses they query (`Pending`, `Received`, `Paid`, …) and optionally add a `Received` chip (`status=received`);
   - b) Keep "Pending / Received" but issue **two** requests (`status=pending` + `status=received`) and merge/paginate client-side;
   - c) Split into per-enum chips as previously recommended (`docs/deep-review/flutter-03-farmers-visits-grain-booking.md:351`).
2. **Fix counts:** either show a per-chip total computed from that chip's own query (requires the dual-query of option b or fetching totals per status), or remove counts to match the approved HTML, which has none.
3. **Do not** send `pending,received` as one parameter hoping the backend parses it — the contract does not support it; if product requires one-request unions: **Backend API required — to be supplied by Syed.**

---

## 10. Regression Protection

Required tests once implementation is approved (none exist today that would catch either bug):

1. **Unit — review payload integrity:** capture the `PATCH /grain-sales/{id}/review` request body from the mocked HTTP client; assert `booking_slot_id` equals a fixture booking id resolved via the bookings lookup and **never** equals `sale_id`.
2. **Unit — fallback removal:** `reviewGrainSale` with no resolvable booking must return `false`, set a specific `errorMessage`, and **make no HTTP call**.
3. **Unit — bookings join:** given a `GET /bookings` page containing `{id: 'b-1', grain_sale_id: 's-1'}`, reviewing `s-1` submits `booking_slot_id: 'b-1'`.
4. **Unit — filter query shape:** `setFilter('pending')` → repository receives `status: 'pending'`; `setFilter('all')` → `status: null` (extends the existing pattern at `test/features/grain_sales/grain_sale_test.dart:542`).
5. **Unit — union behaviour (if option b chosen):** merged list contains both pending and received fixtures; pagination totals computed from the merge, not from one sub-query.
6. **Widget — chip rendering:** active chip shows `Label (count)` for its own query total; inactive chips show plain labels (`lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:183`); empty-but-filtered state renders `No Grain Sales Found` with the correct chip active.
7. **Widget — review failure feedback:** tapping Review & Approve with a backend `detail` error shows that text in an error SnackBar and keeps the sheet open (protects the existing behaviour at `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart:79`).
8. **Full suite:** all existing grain-sales tests (file `test/features/grain_sales/grain_sale_test.dart`, ~1080 lines) must stay green; controller review tests at `:575`-`:624` will need fixture updates once the lookup is mandatory.

---

## 11. Final Gate

- **G0** ledger lint — PASS (automatic evidence recorded in `GATES.md`).
- **G1** report structure + mandated final line — PASS (see `GATES.md` evidence).
- **G2** live OpenAPI reachable with grain-sale paths/schemas — PASS (automatic evidence recorded in `GATES.md`; full fetch also saved this session).
- **G3** every `file:line` citation resolves — PASS (see `GATES.md` evidence; ≥8 citations checked mechanically).
- **G4** cross-checked across code, live contract, and reference implementation; **no production file modified** — PASS. Write-set this session: this report, `GATES.md`, and throwaway extraction scripts under `%TEMP%\opencode\` only; `lib/**` and `test/**` untouched by this investigation (checked via mtime scan — newest grain-sales source mtimes predate this session's reads).
- **G5** verified vs inferred separated (§1 method table, §3.2 verified contract facts, §3.3/§5 explicitly labelled INFERRED), recommendations without implementation (§9), regression tests listed (§10) — PASS.
- **Reticle note:** no browser session exists for this project (`reticle_session list` → `sessions: []`; no dev server listening, Flutter app has no web dev script) — runtime verification was unavailable and every claim above rests on static code trace plus the live OpenAPI document.

Gate summary: **6 met, 0 unmet, 0 abandoned.**

INVESTIGATION COMPLETE — IMPLEMENTATION NOT STARTED — AWAITING HUMAN APPROVAL
