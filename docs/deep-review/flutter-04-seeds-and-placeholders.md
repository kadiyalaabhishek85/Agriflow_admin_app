# Deep Review 04 — Seeds Inventory, Seed Purchases and Placeholder Features

## Scope

This report discharges gate leaf-1.1.4 (`.unlazy/deep-review/gates/leaf-1.1.4.md`), which owns this document and prescribes its scope: every file under `lib/features/seeds_inventory` and `lib/features/seed_purchase`, plus every placeholder feature directory that contains only `.gitkeep` markers. The review was read-only; no `flutter`, `dart pub`, formatter or other mutating command was run, and no file outside this report was created, edited or deleted.

Ground truth for all backend claims is `openapi_dump.json` (94 paths), as mandated by `AGENTS.md`. Where the capability a placeholder implies has no corresponding live contract, the literal sentence `Backend API required - to be supplied by Syed.` is recorded. Pending contracts are tracked in `docs/backend-requirements-admin-mobile.md`, which is read and mapped to placeholders below.

The two implemented features follow clean-architecture layering (domain entity + repository contract, data source + repository implementation, ChangeNotifier controller, screen + card/sheet widgets). The seeds feature performs full CRUD against `/api/v1/seeds`; the seed-purchase feature performs paginated read plus a single status mutation against `/api/v1/seed-purchases`, then enriches rows client-side with farmer and seed names because `SeedPurchasePublic` returns only `farmer_id` and `seed_id`.

## Files reviewed

59 in-scope files (12 seeds inventory, 14 seed purchase, 33 placeholder markers):

FILE: lib/features/seeds_inventory/data/.gitkeep
FILE: lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart
FILE: lib/features/seeds_inventory/data/repositories/seeds_inventory_repository_impl.dart
FILE: lib/features/seeds_inventory/domain/.gitkeep
FILE: lib/features/seeds_inventory/domain/entities/seed_inventory_item.dart
FILE: lib/features/seeds_inventory/domain/exceptions/seeds_inventory_exception.dart
FILE: lib/features/seeds_inventory/domain/repositories/seeds_inventory_repository.dart
FILE: lib/features/seeds_inventory/presentation/.gitkeep
FILE: lib/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart
FILE: lib/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart
FILE: lib/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart
FILE: lib/features/seeds_inventory/presentation/widgets/seed_inventory_card.dart
FILE: lib/features/seed_purchase/data/.gitkeep
FILE: lib/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart
FILE: lib/features/seed_purchase/data/repositories/seed_purchase_repository_impl.dart
FILE: lib/features/seed_purchase/domain/.gitkeep
FILE: lib/features/seed_purchase/domain/entities/seed_catalog_item.dart
FILE: lib/features/seed_purchase/domain/entities/seed_purchase_exception.dart
FILE: lib/features/seed_purchase/domain/entities/seed_purchase_item.dart
FILE: lib/features/seed_purchase/domain/entities/seed_purchase_pagination.dart
FILE: lib/features/seed_purchase/domain/repositories/seed_purchase_repository.dart
FILE: lib/features/seed_purchase/presentation/.gitkeep
FILE: lib/features/seed_purchase/presentation/controllers/seed_purchase_controller.dart
FILE: lib/features/seed_purchase/presentation/screens/seed_purchase_screen.dart
FILE: lib/features/seed_purchase/presentation/widgets/seed_purchase_card.dart
FILE: lib/features/seed_purchase/presentation/widgets/seed_purchase_detail_sheet.dart
FILE: lib/features/booking_slots/data/.gitkeep
FILE: lib/features/booking_slots/domain/.gitkeep
FILE: lib/features/booking_slots/presentation/.gitkeep
FILE: lib/features/billing/data/.gitkeep
FILE: lib/features/billing/domain/.gitkeep
FILE: lib/features/billing/presentation/.gitkeep
FILE: lib/features/cache/data/.gitkeep
FILE: lib/features/cache/domain/.gitkeep
FILE: lib/features/cache/presentation/.gitkeep
FILE: lib/features/credits/data/.gitkeep
FILE: lib/features/credits/domain/.gitkeep
FILE: lib/features/credits/presentation/.gitkeep
FILE: lib/features/event_logs/data/.gitkeep
FILE: lib/features/event_logs/domain/.gitkeep
FILE: lib/features/event_logs/presentation/.gitkeep
FILE: lib/features/managers/data/.gitkeep
FILE: lib/features/managers/domain/.gitkeep
FILE: lib/features/managers/presentation/.gitkeep
FILE: lib/features/market_rates/data/.gitkeep
FILE: lib/features/market_rates/domain/.gitkeep
FILE: lib/features/market_rates/presentation/.gitkeep
FILE: lib/features/notifications/data/.gitkeep
FILE: lib/features/notifications/domain/.gitkeep
FILE: lib/features/notifications/presentation/.gitkeep
FILE: lib/features/profile/data/.gitkeep
FILE: lib/features/profile/domain/.gitkeep
FILE: lib/features/profile/presentation/.gitkeep
FILE: lib/features/reports/data/.gitkeep
FILE: lib/features/reports/domain/.gitkeep
FILE: lib/features/reports/presentation/.gitkeep
FILE: lib/features/warehouse/data/.gitkeep
FILE: lib/features/warehouse/domain/.gitkeep
FILE: lib/features/warehouse/presentation/.gitkeep

For feature-parity comparison the two React admin pages were also read: `agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx` and `agriflow/agriflow-web/src/pages/admin/SeedPurchases.jsx`. They are cited inline but are not part of this leaf's coverage scope.

## Endpoint usage

Every HTTP call made by the two implemented features, with its caller and its presence in `openapi_dump.json`:

| # | Method | Path (with query) | Caller (file:line) | In openapi_dump.json |
|---|---|---|---|---|
| 1 | GET | `/api/v1/seeds` | lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart:65 | Yes — `GET /api/v1/seeds` ("List Seeds"), no query parameters, 200 → `SuccessResponse[list[SeedPublic]]` |
| 2 | POST | `/api/v1/seeds` | fast_api_seeds_inventory_remote_data_source.dart:121 | Yes — body `SeedCreate`, 201 → `SuccessResponse[SeedPublic]` |
| 3 | PATCH | `/api/v1/seeds/{seed_id}` | fast_api_seeds_inventory_remote_data_source.dart:160 | Yes — body `SeedUpdate`, 200 → `SuccessResponse[SeedPublic]` |
| 4 | DELETE | `/api/v1/seeds/{seed_id}` | fast_api_seeds_inventory_remote_data_source.dart:189 | Yes — 204 (204/200 accepted at :194) |
| 5 | GET | `/api/v1/seed-purchases?page&page_size&sort&order&search&status` | lib/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart:111 | Yes — all six query params exist with those names; 200 → `PaginatedResponse[SeedPurchasePublic]` (`data` array + `pagination` object) |
| 6 | PATCH | `/api/v1/seed-purchases/{purchase_id}/status` | seed_purchase_remote_data_source.dart:145 | Yes — body `SeedPurchaseStatusUpdate{payment_status}` with enum `pending|paid|failed`; 200 → `SuccessResponse[SeedPurchasePublic]` |
| 7 | GET | `/api/v1/seeds` (catalog for enrichment) | seed_purchase_remote_data_source.dart:169 | Yes (same as #1) |
| 8 | GET | `/api/v1/farmers?page=1&page_size=100` (farmer lookup for enrichment) | seed_purchase_remote_data_source.dart:190 | Yes — `page_size` maximum is 100, so the single-page fetch is at the schema ceiling |

All eight calls send `Authorization: Bearer <token>` plus JSON accept headers (fast_api_seeds_inventory_remote_data_source.dart:53, seed_purchase_remote_data_source.dart:50) and a 15-second timeout. Not called by this slice: `POST /api/v1/seed-purchases` (farmer checkout flow), `GET /api/v1/public/seeds`, and `POST /api/v1/uploads` / `/api/v1/uploads/presign`.

Schema alignment worth recording, because it proves the mobile DTOs were written against the spec rather than guessed:

- `SeedInventoryItem.fromJson` (seed_inventory_item.dart:45) maps exactly the eight `SeedPublic` keys — `id`, `name`, `variety`, `price_per_kg`, `stock_kg`, `description`, `image_url`, `is_active`. `price_per_kg` and `stock_kg` are declared as *strings* in `SeedPublic` but *numbers* in `SeedOut`, and `_parseDouble` (seed_inventory_item.dart:58) tolerates both.
- `SeedCreate` declares required `name` (2–120 chars), `price_per_kg` (exclusiveMinimum 0) and `stock_kg` (minimum 0), and has **no** `is_active` field — which is why the sheet only offers the availability switch in edit mode (add_edit_seed_sheet.dart:326) and why its validators at add_edit_seed_sheet.dart:96 and :106 mirror the schema bounds exactly.
- `SeedUpdate` has no `name` or `variety`, so both fields are disabled while editing (add_edit_seed_sheet.dart:253, :273) with an explicit on-screen explanation at :260. This is correct, not a bug.
- `SeedPurchaseItem.fromJson` (seed_purchase_item.dart:40) maps exactly `SeedPurchasePublic`: `farmer_id`, `seed_id`, `quantity_kg`, `price_per_kg`, `total_amount`, `payment_status`, `invoice_number`, `created_at`. The admin-flavoured `SeedPurchaseOut` schema additionally carries `grade`, `pickup_date`, `warehouse_id` and a nested `seed`, but `GET /seed-purchases` does not return it.
- The repository-level enrichment (`seed_purchase_repository_impl.dart:17`–`:47`) is a deliberate, spec-compliant workaround: farmer/seed names are resolved in memory rather than assumed to arrive on the purchase row.

**Documented schema gap (AGENTS.md).** The live seed contract carries base price only (`price_per_kg`). Grade A/B/C pricing (`price_grade_a/b/c`), warehouse assignment (`warehouse_id`) and `max_order_quantity_kg` are pending backend additions from Syed, exactly as recorded in `AGENTS.md` §2 item 5 and detailed as Priority 0 in `docs/backend-requirements-admin-mobile.md` §3 (rows 1–2 of the delta table at line 321). Consequently the add/edit sheet cannot collect grade prices or a dispatch warehouse, and the purchase detail sheet cannot show grade, warehouse or pickup date. `Backend API required - to be supplied by Syed.`

## Placeholder features

Eleven directories contain only `.gitkeep` markers — three each under `data/`, `domain/` and `presentation/` (all 33 listed in Files reviewed). No Dart file anywhere in `lib/` imports them; they exist purely as reserved feature skeletons, and their navigation entries resolve to `ModulePlaceholderScreen` (lib/features/admin/presentation/admin_shell.dart:287), which renders status copy without mock data.

- **`lib/features/booking_slots/`** — implies warehouse/booking-slot scheduling. Navigation `booking-slot` exists (lib/core/navigation/nav_destination.dart:47) but the *implemented* feature lives in the singular `lib/features/booking_slot/` (12 Dart files), so this plural directory is a duplicate reservation. Backend: `GET/POST /api/v1/bookings`, `PATCH /api/v1/bookings/{id}/status`, `POST /api/v1/bookings/{id}/inspect` and `GET/POST/PATCH /api/v1/warehouse-slots` already exist; only `DELETE /warehouse-slots/{slot_id}` is pending. `docs/backend-requirements-admin-mobile.md` covers that pending row (§3 row 5, delta row 7).
- **`lib/features/billing/`** — implies "Billing & Invoices" (nav id `billing`, nav_destination.dart:88). No billing, invoice, credit or payment-setup path exists in `openapi_dump.json`. `Backend API required - to be supplied by Syed.` Not covered by `docs/backend-requirements-admin-mobile.md`.
- **`lib/features/cache/`** — implies cache administration (nav id `cache-management`, nav_destination.dart:142). Covered by the doc: `GET /admin/cache/stats` and `POST /admin/cache/clear` (§3 Priority 2 item 2, delta row 14).
- **`lib/features/credits/`** — implies farmer/staff credit balances (admin-only nav id `credits`, nav_destination.dart:134). No path exists in `openapi_dump.json`. `Backend API required - to be supplied by Syed.` Not covered by the doc.
- **`lib/features/event_logs/`** — implies an audit/activity feed (admin-only nav id `event-logs`, nav_destination.dart:110). Backend candidates already exist: `GET /api/v1/admin/audit-logs`, `GET /api/v1/events/stream`, `GET /api/v1/events/ticket`. Not covered by the doc.
- **`lib/features/managers/`** — implies the managers directory (admin-only nav id `managers`, nav_destination.dart:126). `GET /managers`, `POST /managers`, `PATCH /managers/{id}/status` and `POST /managers/{id}/reset-password` exist; profile edit and delete are pending and are covered by the doc (§3 Manager & Staff Administration, delta rows 11–12). Note the separate implemented `lib/features/manager/` (shell + dashboard), so this placeholder is a duplicate reservation like `booking_slots`.
- **`lib/features/market_rates/`** — implies market-rate browsing (nav id `market-rates`, nav_destination.dart:95). Backend exists: `GET/POST /api/v1/market-rates` and `GET /api/v1/public/market-rates`. Not covered by the doc; this is an unbuilt UI, not a backend gap.
- **`lib/features/notifications/`** — implies an in-app notification centre (nav id `notifications`, nav_destination.dart:151). Backend exists: `GET /api/v1/notifications`, `PATCH /{id}/read`, `PATCH /read-all`. Not covered by the doc.
- **`lib/features/profile/`** — implies the signed-in user's account/settings screens (nav ids `account` and `settings`, nav_destination.dart:158, :166). Backend exists for self-service: `GET/PATCH /api/v1/users/me`, `POST /api/v1/auth/change-password`. The doc's "Farmer Profile Management" section (§3 Priority 1) is a different subject (admin editing *farmers*, delta rows 8–10), so this placeholder is not covered by it.
- **`lib/features/reports/`** — implies "Reports & Analytics" (admin-only nav id `reports`, nav_destination.dart:102). `GET /api/v1/admin/reports/monthly` exists; the PDF/CSV export is pending and is covered by the doc (§3 Priority 2 item 1, delta row 13).
- **`lib/features/warehouse/`** — implies warehouse management (nav id `warehouse`, nav_destination.dart:81). `GET/warehouses`, `POST /warehouses`, `POST /warehouses/{id}/inventory`, `GET /warehouses/{id}/slots` exist; single-warehouse GET/PATCH/DELETE and the inventory *read* are pending and are covered by the doc (§3 Priority 0 "Warehouse Management CRUD", delta rows 3–6).

Summary of coverage: `docs/backend-requirements-admin-mobile.md` covers **warehouse, managers, reports, cache** (fully), **booking_slots** (partially, the slot DELETE row), and the implemented **seeds** feature's pending schema extension. It does **not** cover **billing, credits, event_logs, market_rates, notifications, profile**.

## Findings

**F1 (High) — Quintal round-trip silently corrupts stock and price on edit.** The edit sheet seeds its buffer from the *display* getters, which round to two decimals: `seed.displayStockQtl` (add_edit_seed_sheet.dart:69) and `seed.displayPrice` (:65), both defined as `toStringAsFixed(2)` in seed_inventory_item.dart:38 and :34. On submit, `_handleSubmit` re-multiplies by 100 (add_edit_seed_sheet.dart:129). Editing a seed stored as 1234.56 kg without touching stock writes back 1235.00 kg — the record drifts on every save. The React page avoids this by keeping full float precision (`s.stock_kg / 100` at SeedsInventory.jsx:63, `* 100` at :87).

**F2 (High) — Relationship enrichment can be permanently poisoned.** `SeedPurchaseRemoteDataSourceImpl.getSeeds` swallows *every* failure and returns `[]` (seed_purchase_remote_data_source.dart:179-182), and `getFarmerLookup` likewise returns `{}` (:209-212). `_ensureCatalogsLoaded` therefore believes it succeeded and latches `_catalogsLoaded = true` (seed_purchase_repository_impl.dart:31) on an empty result; the `catch (_) {}` retry path at :32-34 becomes unreachable. One transient 5xx during first load means every subsequent list shows `Farmer #ab12cd` / `Seed #ff33aa` fallbacks (seed_purchase_item.dart:104, :110) until the app restarts.

**F3 (High) — Farmer enrichment is capped at the first 100 farmers.** The lookup requests `page=1, page_size=100` only (seed_purchase_remote_data_source.dart:190), and `page_size` cannot exceed 100 per the schema. There is no follow-up page loop, so purchases by farmer 101+ never resolve a name or phone even when the API is healthy. Combined with F2, name resolution fails in two independent ways.

**F4 (High) — "Approve & Mark Paid" is a one-tap irreversible money action with no confirmation, and no role gate.** Reject correctly asks first (seed_purchase_screen.dart:54-102, "Confirm Reject" at :73); approve executes immediately from both the card (seed_purchase_screen.dart:104-126, button at seed_purchase_card.dart:170) and the detail sheet (seed_purchase_detail_sheet.dart:159-171). Once the status leaves `pending`, both action bars disappear (seed_purchase_card.dart:143, seed_purchase_detail_sheet.dart:135), so a mis-tap cannot be undone from this screen. The React page has no confirmation for either action (SeedPurchases.jsx:35-46), so mobile is ahead on reject but equal on approve. Additionally `SeedPurchaseScreen` receives no role flag from either shell (admin_shell.dart:243-246, manager_shell.dart:259-262) even though the manager lands on it as tab 0 (nav_destination.dart:44, manager_shell.dart:149); whether Manager may approve seed purchases is not enumerated in `AGENTS.md` §3, whose manager list covers stock inspection, grain intake, farm visits and farmer KYC only — this is an ambiguity to resolve, not an assumption to make.

**F5 (Medium) — Refresh failures are silent in both features.** The seeds screen only renders `DashboardErrorView` when the list is *empty* (seeds_inventory_screen.dart:397); a failed pull-to-refresh with data present sets `errorMessage` (seeds_inventory_controller.dart:81) and then shows nothing. The purchase screen checks only `isError` (seed_purchase_screen.dart:308), and `refreshPurchases` never sets that status on failure (seed_purchase_controller.dart:104-107), so refresh errors vanish identically. `loadMorePurchases` swallows its error entirely (seed_purchase_controller.dart:133-135).

**F6 (Medium) — Divergent, duplicated HTTP error handling leaks technical text.** The seeds data source maps 401/403/404/422/5xx to typed exceptions while preserving the server's `detail` (fast_api_seeds_inventory_remote_data_source.dart:248-267); the purchase data source discards the parsed message for 401/403/404 and substitutes fixed strings (seed_purchase_remote_data_source.dart:71-85). The purchase data source also never catches `TimeoutException` around its `.timeout(15s)` calls (seed_purchase_remote_data_source.dart:113-115, :148-150) whereas the seeds data source does (fast_api_seeds_inventory_remote_data_source.dart:86-89). The consequence is controller-level `catch (e)` blocks that interpolate `e.toString()` into user-facing copy: `An unexpected error occurred: ${e.toString()}` (seed_purchase_controller.dart:79), `Refresh failed:` (:107), `Status update failed:` (:181) — versus the seeds controller's clean static string (seeds_inventory_controller.dart:83).

**F7 (Medium) — The edit sheet's error banner and image field are dead code.** `_submitError` is only ever assigned `null` (add_edit_seed_sheet.dart:93, :133), yet a full error banner is rendered at :230-245 — a branch no code path can reach, which misleads reviewers into thinking inline errors exist. Separately `_imageUrlController` is created (:46), seeded (:72), disposed (:83) and forwarded to `onAdd` (:158) but is never attached to any `AppTextField` in `build`, so `image_url` is always null in practice. The backend *does* accept it (`SeedCreate.image_url`) and exposes `POST /api/v1/uploads` for the file itself, and the web page implements picker-plus-preview (SeedsInventory.jsx:249-263). This is a client-side omission, not a backend gap.

**F8 (Medium) — A description cannot be cleared.** In edit mode an emptied description field is coerced to `null` (add_edit_seed_sheet.dart:142-144), and the data source omits null fields from the PATCH payload (fast_api_seeds_inventory_remote_data_source.dart:154). `SeedUpdate` accepts an explicit `null` for `description`, so sending it would clear the value; the current code silently keeps the old text.

**F9 (Medium) — Feature-parity gaps against the React admin site.** (a) *Warehouse assignment*: the web form has a warehouse multi-select (SeedsInventory.jsx:18, :224-247) and renders warehouse badges (:135-137, :169-172); the mobile sheet has nothing, and `SeedCreate`/`SeedPublic` in the live spec carry no warehouse field for seeds — `Backend API required - to be supplied by Syed.` (b) *On-hold stock*: the web shows `on_hold_kg` per seed (SeedsInventory.jsx:133, :167); `SeedPublic` has no such property — `Backend API required - to be supplied by Syed.` (c) *Invoice export*: the web downloads a client-generated invoice (SeedPurchases.jsx:48-81, buttons at :168 and :214); the mobile detail sheet only displays the invoice number (seed_purchase_detail_sheet.dart:46) — no backend needed. (d) *Pagination*: the web fetches the whole purchase list and filters in memory (SeedPurchases.jsx:19-31) while mobile paginates server-side — mobile is ahead, but the mobile search box promises "farmer, seed or invoice" (seed_purchase_screen.dart:223) while forwarding the raw `search` param (seed_purchase_remote_data_source.dart:104-106); farmer and seed names are not columns on `SeedPurchasePublic`, so matching them requires a backend join the schema does not document — confirm the searchable columns with Syed before trusting the hint. (e) *RBAC divergence*: the web lets `manager` open "Add Seed" (SeedsInventory.jsx:103) while `AGENTS.md` §3 forbids manager write access and the mobile app correctly passes `isAdmin: false` for managers (manager_shell.dart:268) — mobile matches the written contract, web does not.

**F10 (Medium) — Copy-paste duplication across features.** `_confirmAndReject`/`_approvePurchase` in seed_purchase_screen.dart:54-126 is byte-for-byte identical to booking_slot_screen.dart:54-126 apart from identifiers and labels (verified line-by-line: same dialog shape, same SnackBar blocks at :86/:93/:111/:118). The card triad `booking_card.dart`, `grain_sale_card.dart` and `seed_purchase_card.dart` all hand-roll the same Material→InkWell→avatar→`StatusPill.fromStatus`→`Divider`→action-row structure (seed_purchase_card.dart:42-195), while the seeds card alone uses the shared `AppCard` (seed_inventory_card.dart:25) — the only feature card in `lib/` to do so. `AddEditSeedSheet` likewise replicates `AddFarmerSheet`'s drag-handle + `SquircleIconButton` + `AppTextField` + `_validate()` scaffold (add_edit_seed_sheet.dart:188, :221, :87 versus add_farmer_sheet.dart:156, :196, :59). Feedback surfaces are inconsistent *within this slice*: seeds uses `AppToast.show` (seeds_inventory_screen.dart:74, :79, :130, :173) while seed purchase uses `ScaffoldMessenger.showSnackBar` (seed_purchase_screen.dart:86, :93, :111, :118); every sibling feature uses SnackBar, making seeds the outlier.

**F11 (Low) — Transport configuration is duplicated nine times.** The base URL `https://agriflow-backend-t8o4.onrender.com` is hardcoded in both in-scope data sources (fast_api_seeds_inventory_remote_data_source.dart:39, seed_purchase_remote_data_source.dart:30) and in seven other feature data sources, with no shared client, no shared timeout policy and no shared error mapper. Any environment change requires nine edits.

**F12 (Low) — Stale contract duplicates the real repository.** `lib/core/network/api_contracts.dart:122` declares `ISeedsInventoryRepository` with `adjustStock`, `addSeedVariety(... warehouseIds ...)` and `imagePath` — members the live repository does not have (seeds_inventory_repository.dart:4-35) and a type (no `List<dynamic>` discipline) nothing consumes. The interface has zero references outside its own file, so it is drift-prone dead code that contradicts the shipped API.

**F13 (Low) — State-handling rough edges.** `deleteSeed` resolves the removed row via `firstWhere(..., orElse: () => _seeds.first)` (seeds_inventory_controller.dart:199), which itself throws `StateError` if `_seeds` is empty; it also reinserts created seeds at index 0 regardless of the active search/filter (seeds_inventory_controller.dart:130), so a newly added seed can be invisible under an active filter. On the purchase side, `setFilter`/`setSearch` flip the view to full-screen `DashboardLoadingView` (seed_purchase_controller.dart:145, :152 with seed_purchase_screen.dart:304) instead of filtering in place as the seeds screen does (seeds_inventory_controller.dart:41-64), and a `loadMorePurchases` in flight when the filter changes can append the wrong page (seed_purchase_controller.dart:131). The empty state is not wrapped in a `RefreshIndicator` (seed_purchase_screen.dart:317-340) whereas the seeds empty state is (seeds_inventory_screen.dart:407-437).

**F14 (Positive) — Delete confirmation exists and RBAC for mutations is correct on seeds.** The seeds screen asks `Delete Seed Product?` with an explicit destructive button (seeds_inventory_screen.dart:147-194), which is stronger than the web's `window.confirm` (SeedsInventory.jsx:73). Admin receives `isAdmin: true` (admin_shell.dart:252) and manager `false` (manager_shell.dart:268), matching `AGENTS.md` §3.

## Recommendations

**P0**
1. Fix the quintal round-trip: initialise the edit buffers from full-precision values (`seed.stockKg / 100.0`, raw `pricePerKg`) and round only for display — add_edit_seed_sheet.dart:65-70, conversion at :129, getters at seed_inventory_item.dart:34-43.
2. Stop latching enrichment on failure: let `getSeeds`/`getFarmerLookup` propagate errors (seed_purchase_remote_data_source.dart:179-182, :209-212) so the `catch` in seed_purchase_repository_impl.dart:32-34 can retry, or retry explicitly before setting `_catalogsLoaded`.
3. Add a confirmation dialog for approve/mark-paid symmetric with reject (seed_purchase_screen.dart:104-126), and resolve the Manager-role question for `SeedPurchaseScreen` (admin_shell.dart:243-246, manager_shell.dart:259-262) by amending `AGENTS.md` §3 — then pass an `isAdmin` flag and hide the action bars accordingly (seed_purchase_card.dart:143-185).

**P1**
4. Surface refresh/load-more failures: show a toast or inline banner when `errorMessage` is set but data exists (seeds_inventory_screen.dart:397-402, seed_purchase_screen.dart:308-313, seed_purchase_controller.dart:104-107, :133-135).
5. Add `TimeoutException` handling to the purchase data source and replace `e.toString()` interpolations with static copy (seed_purchase_remote_data_source.dart:113-115; seed_purchase_controller.dart:79, :107, :181), aligning its message mapping with fast_api_seeds_inventory_remote_data_source.dart:248-267.
6. Render an image control (URL field now, or wire `POST /api/v1/uploads`) so `image_url` becomes reachable, and either bind or delete `_submitError` (add_edit_seed_sheet.dart:46, :158, :230-245).
7. Allow clearing `description` by sending an explicit JSON null instead of omitting the key (add_edit_seed_sheet.dart:142-144 with fast_api_seeds_inventory_remote_data_source.dart:154).

**P2**
8. Deduplicate the shared HTTP layer: one `ApiClient` (base URL, headers, timeout, error mapping) replacing the nine copies, starting with fast_api_seeds_inventory_remote_data_source.dart:39 and seed_purchase_remote_data_source.dart:30.
9. Extract the approve/reject dialog and SnackBar helpers shared with `booking_slot` (seed_purchase_screen.dart:54-126), unify feedback on one primitive (seeds_inventory_screen.dart:74 uses `AppToast` while :86 of seed purchase uses SnackBar), and put `SeedPurchaseCard` on `AppCard` like seed_inventory_card.dart:25.
10. Delete or rewrite `ISeedsInventoryRepository` so it cannot drift from seeds_inventory_repository.dart:4-35 (api_contracts.dart:122).

**P3**
11. Harden pagination: guard `loadMorePurchases` against filter changes (seed_purchase_controller.dart:115-139), move filter changes to in-place updates instead of full-screen loading (:142-153), wrap the empty state in a `RefreshIndicator` (seed_purchase_screen.dart:317-340), fix `orElse: () => _seeds.first` (seeds_inventory_controller.dart:199), and re-filter after local insert (seeds_inventory_controller.dart:130).
12. Chase the parity items that need Syed: grade A/B/C pricing, seed warehouse assignment and `max_order_quantity_kg` (delta rows 1–2 of `docs/backend-requirements-admin-mobile.md`), `on_hold_kg` on `SeedPublic`, and confirmation of the columns behind `GET /seed-purchases?search=`. For the first three: `Backend API required - to be supplied by Syed.` Build invoice download client-side meanwhile (no backend needed, cf. SeedPurchases.jsx:48-81), and resolve the duplicate `booking_slots/` vs `booking_slot/` and `managers/` vs `manager/` directory reservations before either placeholder is populated.
