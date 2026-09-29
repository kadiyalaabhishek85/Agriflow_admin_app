# Seed Inventory & Warehouse Investigation Report

**Investigated issues:**
1. Seed Inventory image upload fails with *"Upload completed but did not return a public URL"*.
2. Seed delete appears successful but the same seed reappears after reloading the list.
3. Warehouse capacity semantics — do the displayed *Current Load 908.6 Qtl / Total Capacity 5852.0 Qtl* (and related Available / % values) mean the warehouse capacity is properly consumed?

**Date:** 2026-09-27 · **Mode:** Read-only investigation (no fixes implemented) · **Backend:** `https://agriflow-backend-t8o4.onrender.com` (live OpenAPI is authoritative)

**Evidence classification used throughout:** `VERIFIED` (directly observed in code, live API, or live OpenAPI) · `INFERRED` (strong circumstantial evidence, direct observation impossible under safety rules) · `UNKNOWN` (cannot be determined with permitted methods).

---

## 1. Executive Summary

| # | Symptom | Root cause (short) | Class |
|---|---------|--------------------|-------|
| 1 | Upload shows *"Upload completed but did not return a public URL"* | The sheet **hardcodes this message for every failure mode**: the controller converts *any* `SeedsInventoryException` (HTTP 4xx/5xx, network, parse) to `null`, and the sheet maps `null` → that message (`add_edit_seed_sheet.dart:335`). Flutter's multipart request itself is **contract-correct**. The *actual* upload failure trigger (HTTP error vs. 2xx-missing-field vs. storage/role issue) is **UNKNOWN** — distinguishing it requires a test upload, which is a forbidden mutation. | Flutter defect `VERIFIED`; underlying trigger `UNKNOWN` |
| 2 | Deleted seed reappears after refresh | Delete removes the row **locally**, refresh re-fetches **all** seeds from `GET /seeds` (which has **no filter params** and returns inactive rows), and the default filter `'all'` displays inactive seeds. Persistence of the row after a "successful" delete ⇒ backend delete is **soft** (row kept, `is_active=false`) — proven by the user's observation plus 4 live `is_active=false` rows; the exact `DELETE → is_active=false` mapping is `INFERRED` (a controlled test delete is a forbidden mutation). | Flutter behavior `VERIFIED`; soft-delete semantics `INFERRED` |
| 3 | Are 908.6 / 5852.0 Qtl correct? | **Display math is correct and consistent.** The screenshot values reconcile exactly to the live warehouse **"Help"** (`585,200 kg = 5852.0 Qtl` capacity, `90,856 kg = 908.56 → 908.6 Qtl` load, `494,344 kg → 4943.4 Qtl` available, `15.5%` occupancy). 1 Qtl = 100 kg, identical occupancy formula in approved HTML / React / Flutter. **However**, live data shows `current_load_kg ≠ Σ inventory.quantity_kg` for **6 of 9** warehouses (5 with load > 0 and **zero** inventory rows) → upstream data-integrity issue; which operations write `current_load_kg` is `UNKNOWN` (backend source only). | Display `VERIFIED` correct; load data divergence `VERIFIED` exists; its cause `UNKNOWN` |

No fix was implemented. All findings, recommended fixes, and open backend questions are in §11.

---

## 2. Scope, Method & Constraints

- **Safety rules honored:** no Flutter/backend/DB/migration changes; **no** image upload test; **no** seed/warehouse delete test (stopped at mutation boundary); no test tampering; no invented API fields. Only `POST /auth/login` and **GET** requests were issued against the live backend. The bearer token was never printed or written to disk (login credential pair taken from the documented `scratch/verify_admin_login.js`).
- **Reticle status:** `reticle_session {action:"list"}` → `{"sessions": []}` — no app session has ever connected (no `.reticle.json`, no web `start`/`dev` script; Flutter APK is not served in a browser with the Reticle SDK). **UI screens were therefore verified by source trace + live contract + live data, not by rendered-UI observation.** This limitation is carried into the final gate.
- **Live contract:** fetched fresh from `GET /api/v1/openapi.json` (98 paths). The local cache `openapi_dump.json` is **stale** — see §11 (R6).
- **Read-only probes:** `GET /seeds?page=1&page_size=100`, `GET /warehouses`, `GET /warehouses/{id}/inventory` (×9). Zero mutations.

---

## 3. Issue 1 — Trace: Seed Image Upload Flow (Flutter)

Flow (all `VERIFIED` in source):

1. `add_edit_seed_sheet.dart:305-347` `_handleSampleUpload()` is triggered by the **"Upload Image"** button (`:689`).
2. It uploads **hardcoded 1×1 transparent PNG sample bytes** (`:312-320`, comment: *"1x1 transparent PNG sample bytes to exercise live upload endpoint"*) with filename `seed_<epoch>.png` (`:325`) — there is no image picker in this flow.
3. `seeds_inventory_controller.dart:282-309` `uploadImage()` calls the repository; on `SeedsInventoryException` it stores `e.message` in `_errorMessage` and **returns `null`** (`:299-301`); generic errors return `null` (`:302-304`).
4. Back in the sheet: if `url == null || url.isNotEmpty` fails → `_uploadError = 'Upload completed but did not return a public URL'` (**hardcoded**, `:335`). The sheet **never displays `controller._errorMessage`**, so the real cause (HTTP 401/500/422, timeout, parse failure) is masked. The sheet's own `catch` (`:338-341`, `'Upload failed: $e'`) is effectively dead for backend errors, because the controller *returns* `null` instead of throwing.
5. Data source `fast_api_seeds_inventory_remote_data_source.dart:443-483` `uploadSeedImage()`:
   - `MultipartRequest('POST', …/uploads)` (`:451`), form fields `bucket='seeds'` (`:453`) and file field `'file'` (`:454-458`).
   - Parses `json['data']['public_url'] ?? json['public_url']`, otherwise throws `SeedsInventoryException('Upload succeeded but did not return a valid public URL.')` (`:465-475`, exact text at `:473`).
   - The `contentType` parameter (`:448`) is **declared but never applied** to `MultipartFile.fromBytes` (minor defect).

---

## 4. Issue 1 — Live Contract & Root-Cause Analysis

**Live contract (`VERIFIED`):** `POST /api/v1/uploads` → `201`, `multipart/form-data` with fields `{file: binary (required), bucket: string (default "documents")}`; response `DirectUploadResponse = {object_path, public_url, size_bytes, content_type}`; error `422` only. Flutter sends exactly `file` + `bucket='seeds'` and parses `data.public_url` → **request construction and response parsing are contract-correct**.

**Live data corroboration (`VERIFIED`):** 4 of 15 seeds carry a non-null `image_url` pointing at `https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uplo…` — the upload path **has succeeded historically** (timing/role of those successes `UNKNOWN`).

**Root cause split:**

- **What the user sees (`VERIFIED` defect):** the misleading message. `:335` fires for *every* failure mode because the controller collapses all exceptions to `null` (`controller:299-301`). This is the reportable Flutter bug — it prevented anyone from diagnosing the real cause.
- **Why the upload itself failed (`UNKNOWN`):** distinguishing `2xx-without-public_url` from `HTTP 4xx/5xx` from storage failure would require executing an upload — a mutation explicitly forbidden by the safety rules (creates an object in production storage). Backend logs are not accessible to this client. Boundary: **stopped**. Discriminating questions for Syed are in §11 (Q1).

---

## 5. Issue 2 — Trace: Seed Delete Flow (Flutter)

All `VERIFIED` in source:

1. `seeds_inventory_screen.dart:198-235` `_confirmDelete()` shows the confirmation dialog.
2. `seeds_inventory_controller.dart:250-279` `deleteSeed()` → repository (`seeds_inventory_repository_impl.dart:101`) → data source `:295-319`: `DELETE /seeds/{id}`, treats `204`/`200` as success.
3. On success the controller **optimistically removes** the item from the in-memory list (`:263` `_seeds.removeWhere`) → seed vanishes immediately (matches "delete appears successful").
4. Reload paths: pull-to-refresh `loadSeeds(refresh: true)` (`seeds_inventory_screen.dart:459`, `:492`), retry (`:451`); `initState` loads only when the cache is empty (`:38-42`).
5. `loadSeeds` (`controller:74+`) **replaces** `_seeds` from a fresh `GET /seeds` — there is no local cache poisoning; whatever the backend returns is what the list shows.

---

## 6. Issue 2 — Live Evidence & Root-Cause Analysis

**Live contract (`VERIFIED`):**
- `GET /api/v1/seeds` has **zero query parameters** (no `is_active`, no status filter) — confirmed in live OpenAPI (`parameters` absent).
- `DELETE /api/v1/seeds/{seed_id}` → `204`, summary "Delete Seed", OAuth2 security. Semantics (soft vs. hard) **not stated in the contract**; repo docs are ambiguous: *"Permanently delete/deactivate"* (`docs/milestones/m5-step6-seeds-inventory-contract-audit.md:23`).
- `SeedPublic.is_active` is required; `SeedUpdate` accepts `is_active` (soft-state machinery exists).

**Live data (`VERIFIED`):** `GET /seeds` returned **15 seeds: 11 `is_active=true`, 4 `is_active=false`** (Bajra, Bapam, CO-5 Sugarcane, sambar) — inactive rows are returned by the unfiltered GET.

**Root-cause chain:**
1. **Row persists after a successful delete** — `INFERRED` with high confidence, because a hard delete would make the seed physically absent and the user would never see it again; the reappearance observation *is* the proof that the record survived. Backend keeps the row (soft delete / no-op), `is_active=false` is the most consistent mechanism given the schema (corroborated by 4 live inactive rows). The exact mapping could only be *observed* by performing a delete — forbidden mutation. Boundary: **stopped**. → Q2.
2. **`GET /seeds` returns it** — `VERIFIED` (no params exist; inactive rows present in live response).
3. **Flutter shows it** — `VERIFIED`: default filter `String _currentFilter = 'all'` (`controller:27`); `filteredSeeds` (`:46-71`) hides inactive seeds only under the `'active'` tab; `'all'` displays everything, with an Active/Inactive status pill on the card.

So the reappearance is a **contract+UX gap combination**, not a Flutter caching bug: soft-delete backend + unfiltered GET + default "All" view. Which layer should change (backend hard-delete vs. Flutter default filter/hiding) is a product decision → §11 (R4, Q4).

---

## 7. Issue 3 — Trace: Capacity/Load Display Semantics & Screenshot Reconciliation

**Unit convention (`VERIFIED`):** `1 Qtl = 100 kg` everywhere — `warehouse_item.dart:29-36` (`totalCapacityQtl = kg/100`, `availableCapacityKg = (cap−load).clamp(0, ∞)`), form inputs ×100 on submit (Flutter `add_edit_warehouse_sheet`, React `Warehouse.jsx:93` inventory & `:112` slot), approved HTML inputs in qtl (`AdminMobile UIUX.html:2709`).

**Occupancy formula (`VERIFIED`):** `occupancyPercent = cap ≤ 0 ? 0 : load/cap × 100` (`warehouse_item.dart:45-46`); thresholds `safe <60`, `moderate 60–80`, `near >80 & <100`, `over ≥100` (`:49-52`).

**Screenshot reconciliation (`VERIFIED` — live probe):** the screenshot matches the live warehouse **"Help"** (`768e0126-8dd9-57b6-a049-734b57e98126`) exactly:

| Screenshot | Live value | Display code |
|---|---|---|
| Current Load **908.6 Qtl** | `current_load_kg = 90856.00` → 908.56 → rounds to 908.6 | label `warehouse_detail_sheet.dart:218`, value via entity getters (`:39-41`, `toStringAsFixed(1)`) |
| Total Capacity **5852.0 Qtl** | `total_capacity_kg = 585200.00` → 5852.0 | label `:234` |
| Available **4943.4 Qtl** | 585200−90856 = 494344 → 4943.44 → 4943.4 | `:272` (`availableCapacityQtl…toStringAsFixed(1)`) |
| **15.5%** occupied | 90856/585200×100 = 15.5256 → 15.5 | `:278` (`…toStringAsFixed(1)% occupied`) |

**Verdict (`VERIFIED`):** the numbers **are correct** — they faithfully show the backend's `current_load_kg` vs `total_capacity_kg` in Qtl. "Capacity properly consumed" is therefore a question about **whether `current_load_kg` itself is trustworthy** — answered in §8.

Structural note (`VERIFIED`): warehouse detail has two tabs — *Grain Stock* (inventory rows) and *Booking Slots* (`warehouse_detail_sheet.dart:293-319`); slot capacity (`capacity_kg`/`booked_kg` per slot) is a **separate** metric from warehouse storage load, and seed↔warehouse assignment (`POST/GET/DELETE /seeds/{id}/warehouses`) writes links, **not** inventory.

---

## 8. Issue 3 — Live Data Census: `current_load_kg` vs Inventory

All 9 live warehouses (`VERIFIED`, read-only probe; inventory `GET /warehouses/{id}/inventory` → 200 for all):

| Warehouse | cap (kg) | cap (Qtl) | load (kg) | load (Qtl) | inv rows | Σ qty (kg) | load − Σ |
|---|---|---|---|---|---|---|---|
| Regional Warehouse B | 300,000 | 3000.0 | 140 | 1.4 | 5 | 140 | **0 (EQUAL)** |
| 134e5267890- | 300 | 3.0 | 300 | 3.0 | 0 | 0 | **+300** (100% full) |
| ABC | 1,000 | 10.0 | 23 | 0.23 | 1 | 23 | **0 (EQUAL)** |
| Central Warehouse A | 500,000 | 5000.0 | 1,500 | 15.0 | 6 | 1,500 | **0 (EQUAL)** |
| DHANIYA | 500 | 5.0 | 58 | 0.58 | 0 | 0 | **+58** |
| **Help (screenshot)** | **585,200** | **5852.0** | **90,856** | **908.6** | **0** | **0** | **+90,856** |
| john | 1,000 | 10.0 | 666 | 6.66 | 0 | 0 | **+666** |
| Kurnool Central Warehouse Hub | 100,000 | 1000.0 | 44,638 | 446.4 | 0 | 0 | **+44,638** |
| 12345678998765423456 | 9,500 | 95.0 | 577 | 5.77 | 1 | 18 | **+559** |
| **Fleet total** | **1,497,500** | **14,975.0** | **138,758** | **1,387.6** | — | — | — |

Findings:

1. **6 of 9 warehouses diverge**; every divergence is `load > Σ` (no case of `load < Σ`). 5 warehouses have load > 0 with **zero** inventory rows — including the screenshot's "Help" (90,856 kg load, empty Grain Stock tab).
2. **Clients cannot write `current_load_kg`** (`VERIFIED`, live schema): `WarehouseCreate` = {name, address, total_capacity_kg, location?, contact_number?, manager_id?}; `WarehouseUpdate` = same + `is_active` — **no `current_load_kg` field**. It is backend-maintained.
3. **Procurement does not target a warehouse** (`VERIFIED`): `GrainProcureRequest` = {farmer_id, grain_type, grade, raw_material_kg, good_material_kg, wastage_kg} — no `warehouse_id`.
4. **Two write paths exist** (`VERIFIED`): Flutter → FastAPI (`POST /warehouses/{id}/inventory`, body `{grain_type, quantity_kg}` → 201) vs. React web → **direct Supabase** (`warehouseService.js:36` RPC `add_warehouse_inventory(p_warehouse_id, p_grain_type, p_qty)`; table reads `from('warehouses')` `:5-8`). The React legacy path and FastAPI share the DB but bypass each other's logic.
5. **`INFERRED` (medium):** because all diffs are `load ≥ Σ` and three pure-inventory warehouses are exactly equal, `POST /warehouses/{id}/inventory` likely *does* keep load in sync for its own writes; the extra load comes from other writer(s) (legacy RPC generations, direct DB edits, or a backend operation not derivable from OpenAPI). **Which operations write it: `UNKNOWN`** — backend source only → Q3.
6. **Capacity guard:** Flutter `addInventory` (`warehouse_controller.dart:335-383`) performs **no** `quantity + load ≤ capacity` check (the sheet validates only qty > 0); React likewise (`Warehouse.jsx:80-101`). The **approved HTML does validate** `used ≤ capacity` on the warehouse form (`AdminMobile UIUX.html:2710`). Backend enforcement beyond schema `422` is `UNKNOWN`. `WarehouseInventoryAdd` requires only `{grain_type, quantity_kg}`.

---

## 9. Cross-Platform Comparison: Approved HTML vs React vs Flutter vs Backend

| Aspect | Approved HTML (authority) | React web | Flutter app | Backend (live) | Verdict |
|---|---|---|---|---|---|
| Capacity unit | *Capacity (qtl)* input `wh-capacity` (`AdminMobile UIUX.html:2709`) | ×100 → kg (`Warehouse.jsx:93`, `:112`) | ×100 → kg (`add_edit_warehouse_sheet`, Qtl field `:217`) | stores kg (`total_capacity_kg`) | **Consistent** (1 Qtl = 100 kg) |
| Used/total display | `"${w.used} / ${w.capacity} qtl capacity used"` (`:2429`) | `Used: load/100 Qtl … Total: cap/100 Qtl` (`:152-154`) | `currentLoadQtl / totalCapacityQtl qtl capacity used` (`warehouse_card.dart:184`) | kg decimal strings | **Consistent** |
| Occupancy % | `round(used/cap*100)` (audit `m5-step7:126`) | `(load/cap)*100`, `toFixed(1)` (`:138`, `:153`) | `load/cap*100`, div-zero guard (`warehouse_item.dart:45-46`) | n/a | **Consistent** |
| Color thresholds | documented ≥… (`m5-step7:364-368`) | red >80, yellow >60 (`:149`) | <60 safe / 60-80 moderate / >80 near / ≥100 over (`:49-52`) | n/a | Equivalent intent |
| Inventory add | modal → qtl (`m5-step7:99`) | Supabase RPC `add_warehouse_inventory` (`warehouseService.js:36`) | `POST /warehouses/{id}/inventory` | `{grain_type, quantity_kg}` → 201 | **Divergent write paths** (legacy RPC vs FastAPI) — see §8.4 |
| Over-capacity guard | **validates `used ≤ capacity`** (`:2710`) | none | **none** | 422 only for schema | **Gap** in Flutter+React vs approved design |
| Editing `current_load` | *Used capacity (qtl)* editable (`:2709-2710`) | not exposed (service has no update) | not exposed | `WarehouseUpdate` has **no** `current_load_kg` (`VERIFIED`) | HTML mockup divergence; backend forbids direct edit |
| Warehouse CRUD | add/edit/delete buttons | create only (`warehouseService.js:18-32`), no update/delete | create/edit/delete implemented | `GET/PATCH/DELETE /warehouses/{id}` exist (`VERIFIED` live) | Flutter now contract-supported; **docs/AGENTS stale** (R6) |
| Seed image upload | — | seeds page (reference) | sample-PNG upload, error masking (§3-4) | `POST /uploads` contract (§4) | Flutter defect (R1) |
| Seed delete visibility | — | catalog list | default `'all'` shows inactive (`controller:27,46-71`) | unfiltered `GET /seeds` (`VERIFIED`) | Combined gap (R4) |

---

## 10. Root-Cause Matrix

| # | Symptom | Root cause | Class | Confidence | Blocked by |
|---|---------|-----------|-------|-----------|-----------|
| 1a | Misleading *"Upload completed but did not return a public URL"* for any failure | Sheet hardcodes message on `null` (`add_edit_seed_sheet.dart:335`); controller collapses all `SeedsInventoryException` to `null` (`controller:299-301`); sheet never shows `controller._errorMessage` | **VERIFIED** | High | — |
| 1b | Actual upload failure trigger (HTTP vs 2xx-missing-field vs storage/role) | Not observable without executing a mutating upload; no backend log access | **UNKNOWN** | — | Q1 (backend logs / disposable-env test) |
| 1c | `contentType` declared but unused on `MultipartFile` | `uploadSeedImage` param `:448` never applied | **VERIFIED** | High | — |
| 2 | Deleted seed reappears after refresh | Soft persistence (row survives) + `GET /seeds` has no filter + default `'all'` shows inactive | Flutter legs **VERIFIED**; `DELETE → is_active=false` **INFERRED** (high) | High | Q2 (confirm semantics) |
| 3a | Screenshot numbers meaning | Correct display of live `current_load_kg`/`total_capacity_kg` in Qtl; exact reconciliation to "Help" warehouse | **VERIFIED** | High | — |
| 3b | `current_load_kg ≠ Σ inventory` on 6/9 warehouses | Backend-internal writer(s); clients cannot set the field; two divergent write paths exist | Divergence **VERIFIED**; writer **UNKNOWN** | — | Q3 (backend source) |

---

## 11. Recommended Fixes (NOT Implemented) & Questions

### Flutter fixes (for approval — not applied)
- **R1 — Surface real upload errors (Issue 1a).** When `url == null`, the sheet must display `controller._errorMessage` (set at `controller:300/303`) instead of the hardcoded `:335` text; data-source HTTP errors should carry the status code (e.g., *"Upload failed (HTTP 500)…"*) so failures are diagnosable.
- **R2 — Apply `contentType`** to `MultipartFile.fromBytes` (`uploadSeedImage`, param `:448`).
- **R3 — Replace the hardcoded 1×1 PNG sample** (`:312-320`) with a real image picker — note: even a *successful* run today stores a transparent 1×1 pixel URL. Product confirmation required (this may be an intentional placeholder).
- **R4 — Delete reappearance (Issue 2):** product decision first (see Q4), then either default the catalog to `'active'`, add an explicit *Inactive* chip with count, or rely on a backend hard-delete — implement only after the decision.
- **R5 — Optional capacity guard** on inventory add (`quantity + load ≤ capacity`), matching approved HTML `:2710` — product decision.
- **R6 — Documentation drift:** `AGENTS.md` §2.6 ("Warehouse PATCH and DELETE … pending") and `m5-seed-inventory-backend-contract-blockers.md` ("`SeedUpdate` does NOT accept `image_url`") are **outdated vs live contract** (`VERIFIED`: `WarehouseUpdate` exists; `SeedUpdate` has `image_url`+`is_active`; `GET /warehouses/{id}/inventory`, `GET/POST/DELETE /seeds/{id}/warehouses` exist). Refresh the local `openapi_dump.json` too.

### Questions for Syed (backend)
- **Q1 (Issue 1b):** Please check logs for `POST /api/v1/uploads` failures — HTTP status, role, and whether storage (Supabase `seeds` bucket) is reachable from Render. Is any role beyond OAuth2 required?
- **Q2 (Issue 2):** Does `DELETE /api/v1/seeds/{id}` set `is_active=false` (soft), hard-delete, or no-op? (DB check: does a previously deleted row still exist?)
- **Q3 (Issue 3b):** Which operations write `warehouses.current_load_kg`? Does `POST /warehouses/{id}/inventory` update it? Explain 5 warehouses with load > 0 and zero inventory rows (table §8) — including "Help" (+90,856 kg).
- **Q4 (Product + backend):** Should `GET /seeds` gain an `is_active` filter, and should delete be hard or soft, given the current UI shows inactive seeds under *All*?

---

## 12. Verification, Regression Baseline & Safety Verification

- **Regression baseline (run after investigation, `VERIFIED`):** `flutter test` → **319/319 passed, EXIT=0**; `flutter analyze` → **No issues found (0), EXIT=0** — identical to the pre-investigation baseline.
- **Write-set:** this report file only. **No** `lib/`, `test/`, config, or migration files were created or modified.
- **Live API usage:** `POST /auth/login` (1×) and GETs only (`/openapi.json`, `/seeds`, `/warehouses`, `/warehouses/{id}/inventory` ×9). **No** POST/PATCH/DELETE against uploads, seeds, warehouses, inventory, or slots. Token never printed/stored. Mutation tests (upload, delete) were **stopped at the safety boundary** and converted into Q1/Q2.
- **Reticle:** non-attach documented in §2 (`sessions: []`); no UI verification was claimed.
- **Temp artifacts:** probe scripts under `C:\Users\DELL\AppData\Local\Temp\opencode\` (`read_only_seed_wh.js`, `openapi_seed_wh.js`, `openapi_expand.js`, `live_openapi_check.js`, `live_procure_check.js`) deleted after this report was written.

---

## 13. Final Status

**INVESTIGATION INCOMPLETE — TOOL/CONTRACT LIMITATION — IMPLEMENTATION NOT STARTED**

Rationale: Issues 2 and 3 (display layer) are traced and reconciled to live data, and Issue 1's user-visible Flutter defect is proven — but three root causes remain `UNKNOWN` behind mutation boundaries or backend-only source (1b upload trigger, 2 soft-vs-hard delete semantics, 3b `current_load_kg` writers). They require Syed's answers to Q1–Q3 before implementation approval. No code was changed.
