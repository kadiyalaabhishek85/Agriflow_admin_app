# Deep Review 03 — Farmers, Farm Visits, Grain Sales and Booking Slots (Flutter)

## Scope

This review covers every file that exists under `lib/features/farmers/**`, `lib/features/farm_visits/**`,
`lib/features/grain_sales/**` and `lib/features/booking_slot/**`, including the five `.gitkeep`
placeholders that hold empty layers open. Fifty-eight files are in scope: seventeen for farmers,
fifteen for farm visits, fourteen for grain sales and twelve for booking slots. The contract for
this leaf is `.unlazy/deep-review/gates/leaf-1.1.3.md`, which requires full section coverage,
file-level citations for the whole scope and at least 900 words of substantive prose.

The only backend truth used here is `openapi_dump.json` at the repository root (94 paths). Every
HTTP method, path, query parameter, request body and enum quoted below was read out of that dump
and cross-checked against the Dart call site that issues it. Where a capability the UI wants is
not expressible against the current OpenAPI contract, the report records the literal sentence
`Backend API required - to be supplied by Syed.` rather than inventing a parameter, payload or
table. No `lib/**` file and no `.unlazy/**` file was modified; this document is the only file
written.

Four architectural layers are consistent across all four features: a `data/datasources/*_remote_data_source.dart`
that owns URIs, headers, timeouts and HTTP-status-to-exception mapping; a `data/repositories/*_repository_impl.dart`
that caches enrichment lookups; a `presentation/controllers/*_controller.dart` `ChangeNotifier`
holding list, pagination, filter and mutation state; and `presentation/screens` plus
`presentation/widgets` rendering cards, detail sheets and dialogs. All four data sources hardcode
the same base URL `https://agriflow-backend-t8o4.onrender.com` and `/api/v1` prefix
(farmer_remote_data_source.dart:64, farm_visit_remote_data_source.dart:55,
grain_sale_remote_data_source.dart:44, booking_remote_data_source.dart:31).

## Files reviewed

FILE: lib/features/farmers/data/.gitkeep
FILE: lib/features/farmers/data/datasources/farmer_remote_data_source.dart
FILE: lib/features/farmers/data/repositories/farmer_repository_impl.dart
FILE: lib/features/farmers/domain/.gitkeep
FILE: lib/features/farmers/domain/entities/bank_change_request_item.dart
FILE: lib/features/farmers/domain/entities/farmer_exception.dart
FILE: lib/features/farmers/domain/entities/farmer_item.dart
FILE: lib/features/farmers/domain/entities/farmer_pagination.dart
FILE: lib/features/farmers/domain/entities/farmer_profile_item.dart
FILE: lib/features/farmers/domain/repositories/farmer_repository.dart
FILE: lib/features/farmers/presentation/.gitkeep
FILE: lib/features/farmers/presentation/controllers/farmer_controller.dart
FILE: lib/features/farmers/presentation/screens/farmer_screen.dart
FILE: lib/features/farmers/presentation/widgets/add_farmer_sheet.dart
FILE: lib/features/farmers/presentation/widgets/bank_change_requests_sheet.dart
FILE: lib/features/farmers/presentation/widgets/farmer_card.dart
FILE: lib/features/farmers/presentation/widgets/farmer_detail_sheet.dart
FILE: lib/features/farm_visits/data/.gitkeep
FILE: lib/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart
FILE: lib/features/farm_visits/data/repositories/farm_visit_repository_impl.dart
FILE: lib/features/farm_visits/domain/.gitkeep
FILE: lib/features/farm_visits/domain/entities/farm_visit_exception.dart
FILE: lib/features/farm_visits/domain/entities/farm_visit_item.dart
FILE: lib/features/farm_visits/domain/entities/farm_visit_pagination.dart
FILE: lib/features/farm_visits/domain/repositories/farm_visit_repository.dart
FILE: lib/features/farm_visits/presentation/.gitkeep
FILE: lib/features/farm_visits/presentation/controllers/farm_visit_controller.dart
FILE: lib/features/farm_visits/presentation/screens/farm_visit_screen.dart
FILE: lib/features/farm_visits/presentation/widgets/complete_visit_dialog.dart
FILE: lib/features/farm_visits/presentation/widgets/farm_visit_card.dart
FILE: lib/features/farm_visits/presentation/widgets/farm_visit_detail_sheet.dart
FILE: lib/features/farm_visits/presentation/widgets/reschedule_visit_dialog.dart
FILE: lib/features/grain_sales/data/.gitkeep
FILE: lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart
FILE: lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart
FILE: lib/features/grain_sales/domain/.gitkeep
FILE: lib/features/grain_sales/domain/entities/grain_sale_exception.dart
FILE: lib/features/grain_sales/domain/entities/grain_sale_item.dart
FILE: lib/features/grain_sales/domain/entities/grain_sale_pagination.dart
FILE: lib/features/grain_sales/domain/repositories/grain_sale_repository.dart
FILE: lib/features/grain_sales/presentation/.gitkeep
FILE: lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart
FILE: lib/features/grain_sales/presentation/screens/grain_sale_screen.dart
FILE: lib/features/grain_sales/presentation/widgets/grain_sale_card.dart
FILE: lib/features/grain_sales/presentation/widgets/grain_sale_detail_sheet.dart
FILE: lib/features/grain_sales/presentation/widgets/log_received_crop_sheet.dart
FILE: lib/features/booking_slot/data/datasources/booking_remote_data_source.dart
FILE: lib/features/booking_slot/data/repositories/booking_repository_impl.dart
FILE: lib/features/booking_slot/domain/entities/booking_exception.dart
FILE: lib/features/booking_slot/domain/entities/booking_item.dart
FILE: lib/features/booking_slot/domain/entities/booking_pagination.dart
FILE: lib/features/booking_slot/domain/entities/warehouse_item.dart
FILE: lib/features/booking_slot/domain/repositories/booking_repository.dart
FILE: lib/features/booking_slot/presentation/controllers/booking_controller.dart
FILE: lib/features/booking_slot/presentation/screens/booking_slot_screen.dart
FILE: lib/features/booking_slot/presentation/widgets/booking_card.dart
FILE: lib/features/booking_slot/presentation/widgets/booking_detail_sheet.dart
FILE: lib/features/booking_slot/presentation/widgets/date_selector_strip.dart

## Endpoint usage

Every row is an HTTP call issued by these four features. "In dump" means the exact
method-plus-path pair exists as a key under `paths` in `openapi_dump.json`.

| Method | Path | Data source call site | In dump |
| --- | --- | --- | --- |
| GET | `/api/v1/farmers` | farmer_remote_data_source.dart:175 | Yes |
| GET | `/api/v1/farmers` (farmer repo warm-up, page_size 100) | farmer_repository_impl.dart:160 | Yes |
| GET | `/api/v1/farmers` (enrichment lookup) | farm_visit_remote_data_source.dart:318 | Yes |
| GET | `/api/v1/farmers` (enrichment lookup) | grain_sale_remote_data_source.dart:275 | Yes |
| GET | `/api/v1/farmers` (enrichment lookup) | booking_remote_data_source.dart:244 | Yes |
| GET | `/api/v1/farmers/{farmer_id}` | farmer_remote_data_source.dart:223 | Yes |
| PATCH | `/api/v1/farmers/{farmer_id}/approval` | farmer_remote_data_source.dart:264 | Yes |
| POST | `/api/v1/farmers` | farmer_remote_data_source.dart:314 | Yes |
| GET | `/api/v1/farmers/bank-change-requests` | farmer_remote_data_source.dart:395 | Yes |
| PATCH | `/api/v1/farmers/bank-change-requests/{request_id}` | farmer_remote_data_source.dart:445 | Yes |
| GET | `/api/v1/farm-visits` | farm_visit_remote_data_source.dart:137 | Yes |
| PATCH | `/api/v1/farm-visits/{visit_id}/schedule` | farm_visit_remote_data_source.dart:186 | Yes |
| PATCH | `/api/v1/farm-visits/{visit_id}/complete` | farm_visit_remote_data_source.dart:228 | Yes |
| POST | `/api/v1/farm-visits` | farm_visit_remote_data_source.dart:276 | Yes |
| GET | `/api/v1/crops` (crop lookup) | farm_visit_remote_data_source.dart:356 | Yes |
| GET | `/api/v1/managers` (staff lookup) | farm_visit_remote_data_source.dart:389 | Yes |
| GET | `/api/v1/grain-sales` | grain_sale_remote_data_source.dart:147 | Yes |
| POST | `/api/v1/grain-sales/procure` | grain_sale_remote_data_source.dart:191 | Yes |
| PATCH | `/api/v1/grain-sales/{sale_id}/pay` | grain_sale_remote_data_source.dart:236 | Yes |
| GET | `/api/v1/bookings` | booking_remote_data_source.dart:113 | Yes |
| PATCH | `/api/v1/bookings/{booking_id}/status` | booking_remote_data_source.dart:170 | Yes |
| GET | `/api/v1/warehouses` (warehouse lookup) | booking_remote_data_source.dart:216 | Yes |

**No call in these four features targets a path that is absent from `openapi_dump.json`.** Query
parameters match the dump as well: `page`, `page_size`, `search`, `status`, `sort`, `order` are the
only documented list parameters (all five list endpoints share that set) and no client code sends
anything else. Request bodies also match: `FarmerApprovalRequest.status`
(farmer_remote_data_source.dart:265), `BankChangeReviewRequest{approve, admin_notes}`
(farmer_remote_data_source.dart:446), `VisitCompleteRequest{verified_acres, report, diagnosis, recommendation}`
(farm_visit_remote_data_source.dart:229), `GrainProcureRequest` (grain_sale_remote_data_source.dart:192)
and `BookingStatusUpdate{status, notes}` (booking_remote_data_source.dart:171) are all present in the
dump with the same field names.

Conversely, four documented endpoints are never called by any file in scope:

| Method | Path | Status in this codebase |
| --- | --- | --- |
| POST | `/api/v1/farm-visits/reminders` | no call site anywhere in `lib/` |
| PATCH | `/api/v1/grain-sales/{sale_id}/review` | no data source method exists |
| PATCH | `/api/v1/grain-sales/{sale_id}/yield` | no data source method exists |
| POST | `/api/v1/bookings/{booking_id}/inspect` | no data source method exists |

## Workflows

**Farmer list, search, pagination.** The screen seeds the controller on first frame
(farmer_screen.dart:41) and wires a scroll listener that calls `loadMoreFarmers()` within 200 px of
the bottom (farmer_screen.dart:56-60). `FarmerController.loadFarmers` (farmer_controller.dart:76)
sends page 1 with the live search query and the active chip; the query is rebuilt by
`FastApiFarmerRemoteDataSource.getFarmers` (farmer_remote_data_source.dart:158-175) and the response
envelope `{data, pagination}` is split into `FarmerItem` rows plus `FarmerPagination`
(farmer_remote_data_source.dart:187-196). `FarmerRepositoryImpl.getFarmers` forwards the result and
seeds the id-to-name cache used later by bank-request enrichment (farmer_repository_impl.dart:26-46).
Search is fired on every keystroke with no debounce (farmer_screen.dart:433, farmer_controller.dart:133),
whereas farm visits and bookings only search on submit (farm_visit_screen.dart:226,
booking_slot_screen.dart:228) and grain sales trim-then-fire per keystroke (grain_sale_screen.dart:202).

**Add farmer.** `AddFarmerSheet` validates locally and calls `onSubmit`
(add_farmer_sheet.dart:114-122) → `FarmerController.createFarmer` (farmer_controller.dart:250) →
`FarmerRepositoryImpl.createFarmer` (farmer_repository_impl.dart:89) → `POST /api/v1/farmers`
(farmer_remote_data_source.dart:314-338), accepting 200/201 as the dump declares 201 for that route.
On success the item is inserted at index 0 and the total bumped locally (farmer_controller.dart:261-264).

**Farmer detail.** Tapping a card selects the row and opens `FarmerDetailSheet`
(farmer_screen.dart:62-128). The sheet renders only the list snapshot; `loadFarmerDetail`
(farmer_controller.dart:147) which would call `GET /api/v1/farmers/{farmer_id}`
(farmer_remote_data_source.dart:223) is never invoked by any screen, so the dedicated detail
endpoint and the richer `FarmerProfileItem` fields (bank status, soil, irrigation, primary crop —
farmer_profile_item.dart:15-19) stay unreachable in the UI.

**KYC approval / rejection / suspension.** The sheet's three callbacks
(farmer_detail_sheet.dart:198-247) route to `approveFarmer` / `rejectFarmer` / `suspendFarmer`
(farmer_controller.dart:187-199), all funnelled through `_updateApprovalStatus`
(farmer_controller.dart:201-233) which PATCHes `/farmers/{id}/approval` with `active`, `rejected` or
`suspended` — exactly the four-value `UserStatus` enum in the dump. The refreshed row from the
response replaces the list entry (farmer_controller.dart:213-220) and the sheet pops with a snackbar
(farmer_screen.dart:79-122).

**Bank-change request review.** `initState` fires `loadBankChangeRequests` in parallel with
`loadFarmers` for non-manager roles (farmer_screen.dart:43-45), the controller fetches page 1 with
pageSize 50 (farmer_controller.dart:286-290), the repository enriches rows from the farmer cache
(farmer_repository_impl.dart:121-131) and the sheet renders approve/reject buttons only for
`pending` rows (bank_change_requests_sheet.dart:196-232) → `reviewBankChangeRequest`
(farmer_controller.dart:313) → `PATCH /farmers/bank-change-requests/{request_id}`
(farmer_remote_data_source.dart:445-455) → reload of page 1 (farmer_controller.dart:321).

**Farm visit list, reschedule, complete, reminders.** `FarmVisitScreen` loads on first frame
(farm_visit_screen.dart:41-46); `loadVisits` (farm_visit_controller.dart:68) hits `GET /farm-visits`
(farm_visit_remote_data_source.dart:137) and `FarmVisitRepositoryImpl.getVisits` then warms three
lookups — `/farmers`, `/crops`, `/managers` — in one `Future.wait` before enriching rows
(farm_visit_repository_impl.dart:17-36, 70-76). Reschedule runs `RescheduleVisitDialog` →
`scheduleVisit` (farm_visit_controller.dart:172) → `PATCH /farm-visits/{id}/schedule`
(farm_visit_remote_data_source.dart:186). Complete runs `CompleteVisitDialog` → `completeVisit`
(farm_visit_controller.dart:210) → `PATCH /farm-visits/{id}/complete`
(farm_visit_remote_data_source.dart:228). Reminders have no workflow at all: `POST /farm-visits/reminders`
exists in the dump but nothing in `lib/` calls it.

**Grain sale list, review, pay, procure, yield.** List: `GrainSaleScreen.initState`
(grain_sale_screen.dart:32-39) → `loadSales` (grain_sale_controller.dart:58) →
`GET /grain-sales` (grain_sale_remote_data_source.dart:147) with the farmer catalog fetched in
parallel by the repository (grain_sale_repository_impl.dart:41-57). Procure: the "Log Crop" button
opens `LogReceivedCropSheet`, whose submit converts quintals to kilograms
(log_received_crop_sheet.dart:125-132) → `procureCrop` (grain_sale_controller.dart:153) →
`POST /grain-sales/procure` (grain_sale_remote_data_source.dart:191) and inserts the new row
(grain_sale_controller.dart:163). Pay: the detail sheet button (grain_sale_detail_sheet.dart:259)
→ `payGrainSale` (grain_sale_controller.dart:189) → `PATCH /grain-sales/{id}/pay`
(grain_sale_remote_data_source.dart:236). Review and yield have no workflow: neither endpoint is
reached from any layer of this feature.

**Booking list, date strip, detail sheet, status changes.** `BookingSlotScreen` loads on first frame
(booking_slot_screen.dart:33-37) → `loadBookings` (booking_controller.dart:72) → `GET /bookings`
(booking_remote_data_source.dart:113), then the repository warms `/warehouses` and `/farmers`
(booking_repository_impl.dart:17-35) to enrich farmer and warehouse names. The seven-day
`DateSelectorStrip` (date_selector_strip.dart:26) only sets local state
(booking_controller.dart:158-161); the `bookings` getter then filters the already-loaded pages by
string date (booking_controller.dart:31-36). Detail: `_openDetail` builds `BookingDetailSheet`
(booking_slot_screen.dart:128-146); approve sends `confirmed` and reject sends `cancelled`
(booking_slot_screen.dart:105-108, 80-83) through `updateStatus`
(booking_controller.dart:181) → `PATCH /bookings/{id}/status`
(booking_remote_data_source.dart:170).

## Findings

1. **Farmer pagination is parsed against a contract the backend does not return.**
   `FarmerPagination.fromJson` reads `total_records`, `has_next` and `has_previous`
   (farmer_pagination.dart:26-29), but the dump's `Pagination` schema only has `page`, `page_size`,
   `total`, `total_pages`. `hasNext` is therefore always false, so the `!_pagination.hasNext` guard
   in `loadMoreFarmers` (farmer_controller.dart:105) exits immediately and the farmers list is
   permanently capped at page 1 despite the scroll listener (farmer_screen.dart:56-60). The other
   three features parse `total`/`total_pages` and derive `hasMore` correctly
   (farm_visit_pagination.dart:23-32, grain_sale_pagination.dart:22-27, booking_pagination.dart:20-23).

2. **Dashboard-style counters are page-local.** `activeCount` and `pendingCount` count only the
   loaded rows (farmer_controller.dart:58-59) and are presented as directory totals under ACTIVE /
   PENDING (farmer_screen.dart:338-363), while `totalRecords` — the only true total — is broken by
   finding 1 (farmer_controller.dart:60).

3. **Status enums vs. UI coverage.** Entity-side enums match the dump for farmers
   (farmer_item.dart:13), bank requests (bank_change_request_item.dart:13), visits
   (farm_visit_item.dart:14), grain sales (grain_sale_item.dart:17) and bookings
   (booking_item.dart:124-129). The filter chips do not: farm visits omit `pending_review`
   entirely (farm_visit_screen.dart:30-35), grain sales label a `status=pending` query as
   "Pending / Received" so `received`, `approved` and `rejected` rows are only reachable under All
   (grain_sale_screen.dart:235-239), and grain sales' `isPending` collapses `pending|received|approved`
   into one predicate (grain_sale_item.dart:162-165).

4. **`StatusPill` has no branch for `pending_review` or `inspected`.** Cards pass those raw values
   (farm_visit_card.dart:134, booking_card.dart:108) and the shared pill falls through to its
   default neutral case, rendering `Pending_review` as a label — an unparsed enum leaking to the UI.

5. **Four documented workflows are absent from the client.** Reminders, grain-sale review,
   grain-sale yield and booking inspection have no data source method, repository method, controller
   action or widget anywhere in scope, even though all four endpoints exist in the dump.

6. **Booking date filtering is client-side only.** `GET /api/v1/bookings` documents no date
   parameter, so the strip (booking_slot_screen.dart:164-167) filters only the pages already in
   memory (booking_controller.dart:31-36); a date with bookings beyond page 1 shows "No bookings
   scheduled for the selected date" (booking_slot_screen.dart:341-347). Backend API required - to be
   supplied by Syed.

7. **Slot time cannot be displayed.** `BookingItem.enrichedSlotTime` (booking_item.dart:23) is never
   populated — `BookingRepositoryImpl._enrichItem` passes no `slotTime` (booking_repository_impl.dart:41-47)
   and the dump's `BookingPublic` has no `slot_time` field. Backend API required - to be supplied by Syed.

8. **Inconsistent resilience between features.** Farmers and grain sales wrap every request in a
   15-second timeout (farmer_remote_data_source.dart:179, grain_sale_remote_data_source.dart:150);
   farm visits and bookings have none (farm_visit_remote_data_source.dart:138,
   booking_remote_data_source.dart:114), so a stalled Render host hangs those two lists. Error
   hierarchies are also four near-identical private copies (farmer_exception.dart:2-45,
   farm_visit_exception.dart:2-47, grain_sale_exception.dart:2-44, booking_exception.dart:1-14), and
   farm visits map 409 to a validation exception (farm_visit_remote_data_source.dart:96-110) where
   farmers and grain sales have a dedicated conflict type.

9. **Enrichment is duplicated four times with divergent quality.** Each feature re-implements a
   `GET /farmers?page_size=100` lookup (farmer_repository_impl.dart:160,
   farm_visit_remote_data_source.dart:318, grain_sale_remote_data_source.dart:275,
   booking_remote_data_source.dart:244), each capped at the dump's `page_size` maximum of 100.
   The grain-sales variant reads `village`/`address` off the top-level row
   (grain_sale_remote_data_source.dart:289) where `FarmerAdminView` keeps them under
   `farmer_profile`, so village enrichment always fails and `displayVillage` falls back to the
   hardcoded `'Main Village'` (grain_sale_item.dart:158, farm_visit_item.dart:125).

10. **Bank-request enrichment races the farmer list.** Both loads start in the same post-frame
    callback (farmer_screen.dart:41-45); if the bank list lands first, `_farmersCache` is empty,
    `copyWithEnrichment` is skipped (farmer_repository_impl.dart:122-131) and the sheet shows the
    opaque `Farmer #12345678` fallback (bank_change_request_item.dart:80-83).

11. **Silent failure paths in sheets and dialogs.** `BankChangeRequestsSheet` receives
    `errorMessage` (bank_change_requests_sheet.dart:11) but never renders it, and `_handleReview`
    gives no feedback on a false result (bank_change_requests_sheet.dart:35-41). The add-farmer
    sheet discards the controller's specific `errorMessage` for a generic string
    (add_farmer_sheet.dart:130 vs farmer_controller.dart:267). Reschedule and complete dialogs stay
    open silently on failure (reschedule_visit_dialog.dart:60-71, complete_visit_dialog.dart:75-93)
    because the screen's error snackbar only runs after the dialog pops (farm_visit_screen.dart:96,
    133). The log-crop sheet (log_received_crop_sheet.dart:134-136) and the grain-sale pay callback
    (grain_sale_screen.dart:60-68) surface success only. By contrast the booking screen does show
    error snackbars (booking_slot_screen.dart:92-99, 117-124).

12. **Bank-change requests have no pagination.** One hardcoded `page: 1, pageSize: 50` fetch
    (farmer_controller.dart:286-290) with no load-more, unlike the farmer list itself and the other
    three features.

13. **Hardcoded credentials, catalogues, units and money.** The registration form pre-fills
    `AgriFlow@123` as the default password (add_farmer_sheet.dart:34). Grain types are a fixed
    six-item client list (log_received_crop_sheet.dart:65-72) against a free-text `grain_type` field
    in `GrainProcureRequest`. The quintal↔kilogram factor of 100 is written out in three places
    (log_received_crop_sheet.dart:129-131, grain_sale_item.dart:110-129, booking_card.dart:91).
    Currency is a hardcoded `₹` with zero decimals (grain_sale_item.dart:136, 142, 150) and land
    units are a hardcoded `'acres'` suffix (farmer_item.dart:94).

14. **Date rendering is inconsistent.** The visit card formats `dd MMM yyyy`
    (farm_visit_card.dart:19-33) while its detail sheet prints the raw `YYYY-MM-DD`
    (farm_visit_detail_sheet.dart:37-40); the booking card shows raw `booking_date`
    (booking_card.dart:98) and its sheet repeats it (booking_detail_sheet.dart:126).

15. **Dead code and dead UI.** `GET /farmers/{id}` is unreachable (finding: `loadFarmerDetail` never
    called), `POST /farm-visits` is unreachable because `createVisit` has no screen caller
    (farm_visit_controller.dart:237), and the "Call <name>" button is a no-op because no shell passes
    `onCallFarmer` (farmer_detail_sheet.dart:178-195, farmer_screen.dart:17-24).

16. **Duplicate card/sheet scaffolding.** `FarmerCard`, `FarmVisitCard`, `GrainSaleCard` and
    `BookingCard` each re-build the same avatar + name + status pill + divider + wrap layout
    (farmer_card.dart:37-113, farm_visit_card.dart:56-190, grain_sale_card.dart:46-127,
    booking_card.dart:50-201), `_buildDetailRow` exists twice with different shapes
    (grain_sale_detail_sheet.dart:38-61, booking_detail_sheet.dart:182-201),
    `_buildDetailCard` is a third variant (farmer_detail_sheet.dart:255-299), initials logic exists
    four times (farmer_item.dart:79-89, farm_visit_item.dart:129-141, grain_sale_item.dart:96-108,
    booking_card.dart:23-30) and the sheet drag-handle/header block is copy-pasted across all
    detail sheets.

17. **Header copy bug on the booking screen.** The eyebrow above "Booking Slots" reads
    "Farm visit scheduling" (booking_slot_screen.dart:204-207), which is the farm-visit module's
    descriptor reused verbatim.

18. **RBAC visibility needs confirmation.** The register-farmer action is shown to both roles
    (farmer_screen.dart:323-332) while `AGENTS.md` restricts managers to KYC approve/reject,
    procurement, visits and read-only catalog access. The dump carries only a global
    `OAuth2PasswordBearer` security requirement with no per-route roles, so enforcement cannot be
    verified from the contract; if the backend rejects it the user only sees a 403 message.

## Recommendations

**P0 — correctness.**

1. Realign `FarmerPagination` to the dump's `Pagination` schema: read `total` and derive
   `hasNext` as `page < total_pages` (farmer_pagination.dart:22-31), then switch
   `loadMoreFarmers` (farmer_controller.dart:105) and `createFarmer`'s counter bump
   (farmer_controller.dart:262-264) to the derived fields. This restores infinite scroll for the
   farmer directory in one change.
2. Add the four missing client workflows against existing dump endpoints: `POST /farm-visits/reminders`
   (new method beside farm_visit_remote_data_source.dart:267), `PATCH /grain-sales/{sale_id}/review`
   and `PATCH /grain-sales/{sale_id}/yield` (beside grain_sale_remote_data_source.dart:229),
   `POST /bookings/{booking_id}/inspect` (beside booking_remote_data_source.dart:213), each with a
   repository method, a controller action and a sheet/dialog entry point.
3. Add `pending_review` to the visit filter chips (farm_visit_screen.dart:30-35), split the grain
   sales "Pending / Received" chip into the dump's `pending`, `received`, `approved`, `rejected`
   values (grain_sale_screen.dart:235-239), and stop labelling every chip with the unfiltered
   `pagination.total`.
4. Surface mutation failures everywhere: render `widget.errorMessage` in
   `BankChangeRequestsSheet` (bank_change_requests_sheet.dart:11), pass
   `controller.errorMessage` into `AddFarmerSheet` instead of the generic string
   (add_farmer_sheet.dart:130), and pop or show an inline error from
   `RescheduleVisitDialog._submit` / `CompleteVisitDialog._submit`
   (reschedule_visit_dialog.dart:60-71, complete_visit_dialog.dart:75-93).

**P1 — consistency and integrity.**

5. Extract one shared farmer-lookup provider so `/farmers?page_size=100` is called once per
   session (currently four copies: farmer_repository_impl.dart:160,
   farm_visit_remote_data_source.dart:318, grain_sale_remote_data_source.dart:275,
   booking_remote_data_source.dart:244) and fix the grain-sales parser to read
   `farmer_profile.address` (grain_sale_remote_data_source.dart:289).
6. Add the 15-second timeout used by the other two features to
   `farm_visit_remote_data_source.dart:138` and `booking_remote_data_source.dart:114`, and merge
   the four exception hierarchies into one shared type with a 409 conflict case
   (farm_visit_remote_data_source.dart:96-110).
7. Call `loadFarmerDetail` when opening `FarmerDetailSheet` (farmer_screen.dart:62) so
   `GET /farmers/{farmer_id}` (farmer_remote_data_source.dart:223) is exercised and the profile
   fields declared in farmer_profile_item.dart:15-19 become visible; delete or wire
   `FarmVisitController.createVisit` (farm_visit_controller.dart:237).
8. Sequence bank-request loading after the farmer cache is warm, or fetch the lookup first, to
   remove the `Farmer #12345678` fallback race (farmer_screen.dart:43-45,
   farmer_repository_impl.dart:121-131).
9. Give bank-change requests real pagination using the same `page`/`page_size` contract as the
   farmer list (farmer_controller.dart:286-290).

**P2 — polish and shared components.**

10. Replace the hardcoded default password with an empty field (add_farmer_sheet.dart:34), move the
    grain-type list behind a constant shared with any other intake form (log_received_crop_sheet.dart:65-72),
    centralise the 100 kg quintal factor and the `₹` formatter (grain_sale_item.dart:110-151), and
    add a `pending_review`/`inspected` case to the shared status pill used at
    farm_visit_card.dart:134 and booking_card.dart:108.
11. Consolidate the four card layouts, the three detail-row builders, the four initials helpers and
    the repeated sheet handle/header block into shared widgets (farmer_card.dart:37,
    grain_sale_detail_sheet.dart:38, booking_detail_sheet.dart:182, farmer_detail_sheet.dart:255).
12. Format all dates through one helper so the visit detail sheet and booking cards stop showing
    raw ISO dates (farm_visit_detail_sheet.dart:37-40, booking_card.dart:98), and correct the
    booking header eyebrow (booking_slot_screen.dart:204-207).
13. For server-side date filtering of bookings and for exposing `slot_time` on `BookingPublic`,
    Backend API required - to be supplied by Syed.
