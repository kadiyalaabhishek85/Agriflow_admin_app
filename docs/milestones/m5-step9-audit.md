# M5 Step 9 Contract Audit: Market Rates (Mandi Price Board)

**Document Status:** Complete Contract, UI/UX, and Implementation Audit  
**Evaluator:** Antigravity Mobile Engineering Agent  
**Date:** 2026-09-28  
**Target Backend:** `https://agriflow-backend-t8o4.onrender.com`  
**Live OpenAPI Source:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json` (refreshed 2026-09-28, HTTP 200, 184,966 bytes)  
**Workspace:** `c:\Users\DELL\Downloads\Admin Mobile application build`

---

## 1. Module Identification

- **Module Name:** Market Rates (`market-rates`)
- **Module ID:** `NavDestination.marketRates` (`id: 'market-rates'`)
- **Roadmap Sequence:** Milestone 5, Step 9 (immediately follows Step 8 Billing — it is the next placeholder destination in nav order and the module to which the Step 8 test suite explicitly deferred market-rate coverage)
- **Navigation Section:** `NavSection.operations`
- **Module Path:** `lib/features/market_rates/` (`data/`, `domain/`, `presentation/` — each currently contains only `.gitkeep`)
- **Primary Roles:** Admin, Super Admin (mutations); Admin, Super Admin, Manager (read)
- **Approved HTML References:**
  - `AdminMobile UIUX.html` -> `#screen-market-rates` (list + edit icon), `#home-mandi-strip`, `#gs-mandi-strip`, quick-action tile `data-nav="market-rates"`
  - `Manager Dashboard UIUX.html` -> `#screen-market-rates` (read-only grade cards), drawer item `Market Rates`, quick-action tile
- **React Functional Reference:**
  - `agriflow/agriflow-web/src/pages/admin/MarketRates.jsx`
  - `agriflow/agriflow-web/src/services/marketService.js`
  - `agriflow/agriflow-web/src/components/shared/LiveMarketRatesWidget.jsx`
  - `agriflow/agriflow-web/src/pages/public/MarketRatesPage.jsx` (public marketing page — out of this app's scope; listed for behavioural reference only)
- **Existing Flutter Scaffold:**
  - `lib/features/market_rates/{data,domain,presentation}/.gitkeep` (Currently renders `ModulePlaceholderScreen` with text `Route: market-rates`)
  - `lib/core/network/api_contracts.dart` -> `IMarketRatesRepository` (declared, **no implementations exist anywhere**)
  - `lib/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart` -> `MandiRateItem` + `DashboardMandiStrip` (live strip, already consuming `GET /public/market-rates`)

---

## 2. Backend Contract

Reconciled directly against the refreshed live production OpenAPI (`openapi_live2.json` / `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`), plus unauthenticated reachability probes (no credentialed requests were made).

### 2.1 List Public Rates: `GET /api/v1/public/market-rates`
- **Summary:** Market Rates
- **Tag:** `public`
- **Security:** None (anonymous)
- **Query Parameters:** None
- **Response Schema:** `SuccessResponse[list[MarketRatePublic]]` (`200 OK`)
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "940ee6cd-3864-4db5-9b5d-805cb303f44f",
        "crop_type": "Maize",
        "grade": "A",
        "price_per_kg": "21.50",
        "effective_date": "2026-09-27"
      }
    ],
    "message": "Success"
  }
  ```
- **Live Probe:** `200 OK` — 18 live rows returned (Rice, Wheat, Maize, Cotton, Groundnut, Sugarcane × grades A/B/C, one row per crop+grade, prices as strings such as `"21.50"`, `effective_date` ranging 2026-06-15 → 2026-09-27).

### 2.2 List Rates (Authenticated): `GET /api/v1/market-rates`
- **Summary:** List Market Rates
- **Tag:** `market-rates`
- **Security:** Authenticated (`Bearer <access_token>`, OAuth2PasswordBearer)
- **Query Parameters:** None (no filters, no pagination)
- **Response Schema:** `SuccessResponse[list[MarketRatePublic]]` (`200 OK`) — **identical payload to the public endpoint** (no extra fields)
- **Live Probe:** `401 UNAUTHORIZED` (`"Missing bearer token"`) — route exists, auth enforced, no mutation attempted.

### 2.3 Set Rate (Create): `POST /api/v1/market-rates`
- **Summary:** Set Market Rate
- **Tag:** `market-rates`
- **Security:** Authenticated (`Bearer <access_token>`)
- **Request Body:** `MarketRateCreate`
  ```json
  {
    "crop_type": "Rice",
    "grade": "A",
    "variety": "Sona Masoori",
    "price_per_kg": 22.5,
    "effective_date": "2026-09-28"
  }
  ```
  - `crop_type: string` (min 2, max 80) — **required**
  - `grade: GrainGrade` (enum `A` | `B` | `C`) — **required**
  - `variety: string | null` (max 100, optional)
  - `price_per_kg: number (> 0)` or numeric string (regex-guarded) — **required**
  - `effective_date: date (YYYY-MM-DD)` — **required**
- **Responses:** `201 Created`, `422 Validation Error`
- **Live Probe:** unauthenticated `POST {}` → `401 UNAUTHORIZED` (`"Missing bearer token"`) — route exists, auth enforced, no data written.

### 2.4 Farmer Rates (Out of Scope, Reference Only): `GET /api/v1/farmer/market-rates`
- **Summary:** Market Rates (tags `farmer`, `dashboard`)
- **Security:** Authenticated
- **Response Schema:** `SuccessResponse[list[MarketRateOut]]` — `crop_type`, `grade`, `variety`, `price_per_kg`, `price_per_qtl`, `change_percentage`, `effective_date` (**no `id`**)
- **Live Probe:** `401` (auth enforced).
- **Note:** This is the only schema that carries `price_per_qtl` and `change_percentage`; it belongs to the farmer surface and is **not** consumable by the Admin/Manager mobile app.

### 2.5 Schema: `MarketRatePublic` (admin & public list item)
```json
{
  "id": "uuid",
  "crop_type": "string",
  "grade": "A | B | C",
  "price_per_kg": "string (numeric pattern)",
  "effective_date": "date"
}
```
- **Absent from this schema:** `variety`, `price_per_qtl`, `change_percentage`, `set_by`, timestamps.
- **`GrainGrade` enum:** `["A", "B", "C"]`.

### 2.6 Routes That Do NOT Exist
The live OpenAPI contains **no `PATCH`, `PUT`, or `DELETE` route under `/api/v1/market-rates`** (verified by full path enumeration of the spec). Editing and deleting rates therefore cannot be implemented against the FastAPI backend.

---

## 3. React Workflow

From `agriflow/agriflow-web/src/pages/admin/MarketRates.jsx` + `services/marketService.js`:

1. **Rate List:** Loads via React Query key `admin-market-rates`; groups rows by `crop_type` into cards; per-crop header (emoji tile + name), rows sorted by grade with `Grade A/B/C` colour badges and price shown as `₹{price_per_kg}` labelled `/Quintals`.
2. **Search:** Client-side substring filter on `crop_type`.
3. **Set Rate (create):** Button rendered only when `user?.role === 'super_admin'`. Modal picks a crop from `['Rice','Wheat','Maize','Cotton','Groundnut','Sugarcane']` and accepts bulk prices for grades A/B/C (at least one non-empty); submits **one request per filled grade** with `effective_date = today`.
4. **Edit:** Per-row edit button (super_admin only) opens modal with single price field; submits `{price_per_kg, effective_date: today}`.
5. **Delete:** Per-row trash button (super_admin only) with `window.confirm`.
6. **Transport — critical finding:** all four `marketService` methods execute **directly against Supabase** (`.from('market_rates').select/insert/update/delete`), bypassing FastAPI entirely. `setRate` also inserts into Supabase `audit_logs` and writes a `set_by` column — neither of which exists in the FastAPI contract. React therefore **cannot** be treated as executable ground truth for writes; it only demonstrates intended workflows.
7. **Route exposure (`AppRouter`):** `/manager/dashboard/market-rates` (parent guard `['manager','super_admin']`), `/admin/op/market-rates` (super-admin operational portal), public `/market-rates` → `MarketRatesPage`.
8. **`LiveMarketRatesWidget`:** floating widget, 30-second refetch polling, rows display crop, `Grade X`, `₹{price_per_kg}` labelled **`per kg`**.
9. **Unit-label inconsistency:** the admin page labels `price_per_kg` as `/Quintals` while the widget labels it `per kg` — React itself is inconsistent; see §8 decision D2.

---

## 4. Approved HTML Workflow

### Admin — `AdminMobile UIUX.html` (`#screen-market-rates`)
1. **Header:** back button (`#i-chevron-l` → home), eyebrow `"Live mandi prices"` + `#mr-updated-at` showing `"Updated {clock}"`, title `"Market Rates"`, trailing spacer (no add button in header).
2. **List (`#market-rates-list`):** one card per crop — circular emoji tile, crop name, **edit icon button** (36px) — plus a 3-column grade grid (`GRADE A` / `GRADE B` / `GRADE C` tiles with ₹ values; green / neutral / amber styling) and footer caption `"Rates per quintal"`.
3. **Edit flow (`rate-editor` full page):** header `"Edit Market Rate"`, crop name card, three numeric inputs `Grade A (₹/qtl)`, `Grade B (₹/qtl)`, `Grade C (₹/qtl)` prefilled from `gradeA || price`, `gradeB || A×0.95`, `gradeC || A×0.9`; **Save Rates** validates all three non-zero → updates in-memory + toast `"Market rates updated"`.
4. **No create flow and no delete action exist in the approved HTML.**

### Manager — `Manager Dashboard UIUX.html` (`#screen-market-rates`)
1. Same header structure (`"Live mandi prices"` eyebrow, title).
2. **Read-only cards:** per-crop card with leaf tile + name, three full-width rows — coloured `Grade A/B/C` chips with `₹{value}/Quintals` (mock derives `B = A×0.9`, `C = A×0.8`). **No edit affordance, no add, no delete.**

### Shared surfaces (both HTMLs)
- **Home mandi strip (`#home-mandi-strip`):** section header `"Today's Mandi Prices"` + `#mandi-updated-at`; horizontal cards with emoji, crop name, `₹{price}/qtl`, and `▲/▼ {change}%` (large variant).
- **Grain-sales strip (`#gs-mandi-strip`):** compact variant without change arrows, injected by `renderMandi('gs-mandi-strip', false)`.
- **Quick action tile** `data-nav="market-rates"` on home; **manager drawer item** `Market Rates`.
- **Mock data (`marketRatesFull`):** 6 crops with per-quintal magnitudes (`Paddy 2350`, `Maize 2100`, `Cotton 7125`, `Groundnut 5840`, `Bajra 2260`, `Sunflower 6450`) and `change` percentages — confirming the approved display unit is **₹ per quintal**.

---

## 5. Flutter Current State

- **Navigation:** registered in `lib/core/navigation/nav_destination.dart` (L95: `id: 'market-rates'`, title `Market Rates`, icon `Icons.trending_up_rounded`, `NavSection.operations`), included in the navigation list (L189) and `custom_drawer.dart` (L155).
- **Shells:** `AdminShell` and `ManagerShell` route `market-rates` to `ModulePlaceholderScreen`, which renders `"Route: $destinationId"` (`lib/core/widgets/module_placeholder_screen.dart` L83). `test/features/navigation/navigation_shell_test.dart` (L354–362) currently asserts this placeholder.
- **Directory:** `lib/features/market_rates/{data,domain,presentation}/` each contain only `.gitkeep` — no entities, data sources, controllers, screens, or widgets exist.
- **Repository interface:** `lib/core/network/api_contracts.dart` L178 declares `IMarketRatesRepository` with `getMarketRates()` and `updateMarketRate({commodityId, priceGradeA, priceGradeB, priceGradeC})`.
  - **No class implements this interface anywhere in `lib/`.**
  - The `updateMarketRate` signature (commodity id + three grade prices) matches the **HTML mock mental model**, not the live contract (no `commodityId`, no update route at all).
- **RBAC helper:** `lib/core/models/user_role.dart` L34 `isAdmin => admin || superAdmin`; L74 `canEditMarketRates => isAdmin`.
- **Mandi strip (built & tested):** `MandiRateItem {cropType, grade, pricePerKg, effectiveDate}` parsed from `/public/market-rates`; `DashboardMandiStrip` renders title `"Live Mandi Rates"`, `Updated {time}` caption, horizontal cards. Consumed by:
  - `admin_dashboard_view.dart` L114 (View All → `marketRates.id`), L420 quick tile,
  - `manager_dashboard_view.dart` L83, L260,
  - fed non-blocking by `admin_dashboard_remote_data_source.dart` L55–67 and `manager_dashboard_remote_data_source.dart` L129–141.
- **Tests today:** dashboard tests assert strip presence (`find.byType(DashboardMandiStrip)`); navigation test asserts the placeholder text. **No market-rates feature tests exist.**
- **No admin `GET/POST /market-rates` client code exists anywhere in `lib/`** (only `/public/market-rates` in the two dashboard data sources).

---

## 6. Endpoint Matrix

| Workflow / Capability | Endpoint | Method | Contract Status | Live Probed | Blocker |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **View Rate Board (anonymous fallback)** | `/api/v1/public/market-rates` | `GET` | **EXISTS** (`SuccessResponse[list[MarketRatePublic]]`) | Verified (200, 18 rows) | None |
| **View Rate Board (authenticated)** | `/api/v1/market-rates` | `GET` | **EXISTS** (`SuccessResponse[list[MarketRatePublic]]`) | Verified (401 auth enforced) | None |
| **Create / Set Rate (per grade)** | `/api/v1/market-rates` | `POST` | **EXISTS** (`MarketRateCreate` → `201`) | Verified (401 auth enforced) | None |
| **Edit Existing Rate (HTML `rate-editor`)** | `/api/v1/market-rates/{id}` | `PATCH`/`PUT` | **MISSING IN FASTAPI** | N/A | `Backend API required — to be supplied by Syed.` |
| **Delete Rate (React only)** | `/api/v1/market-rates/{id}` | `DELETE` | **MISSING IN FASTAPI** | N/A | `Backend API required — to be supplied by Syed.` |
| **Change % arrows (`▲/▼`)** | (field on list schema) | — | **MISSING** (`change_percentage` only on farmer schema; no history rows to compute client-side) | N/A | `Backend API required — to be supplied by Syed.` (or explicitly drop the arrows) |
| **`variety` echo on list** | (field on list schema) | — | **MISSING** (accepted on create, never returned) | N/A | Optional — `Backend API required — to be supplied by Syed.` |
| **Grain-sales screen strip (`#gs-mandi-strip`)** | `/api/v1/public/market-rates` | `GET` | **EXISTS** (data ready) | Verified | None — but belongs to the Grain Sales screen (not built there); see §8 note D4 |

---

## 7. RBAC Matrix

Authority chain: `AGENTS.md` §3 ("Super Admin & Admin: Full mutation access to ... Market Rates ..."; Manager strictly read-only for master catalogs) + `docs/audits/pre-m8-stabilization-audit.md` L185 (`Market Rates | Update Rates (POST /market-rates) | Admin: Yes | Super Admin: Yes | Manager: NO | Backend Verified: Yes | Flutter Correct: Yes`) + Flutter `UserRole.canEditMarketRates => isAdmin`.

| Role | View Rate Board | Set Rate (`POST /market-rates`) | Edit Rate (`rate-editor`) | Delete Rate |
| :--- | :--- | :--- | :--- | :--- |
| **Super Admin** | Full Access | Full Access | Blocked (no endpoint) | Blocked (no endpoint) |
| **Admin** | Full Access | Full Access | Blocked (no endpoint) | Blocked (no endpoint) |
| **Manager** | Full Access | **NO — read-only** (pre-m8 L185; AGENTS.md §3) | Blocked | Blocked |

- **Discrepancy noted:** the React UI gates Set/Edit/Delete buttons to `super_admin` only, which is narrower than the backend matrix (Admin also allowed). Flutter must follow `AGENTS.md` / pre-m8 / `canEditMarketRates` (Admin + Super Admin), not the narrower React UI restriction.

---

## 8. Feature-by-Feature Readiness

| Feature | Classification | Action Plan |
| :--- | :--- | :--- |
| **1. Rate Board Screen (grouped per-crop cards, grade rows, ₹ price, effective date)** | `READY` | Connect `GET /api/v1/market-rates` (authenticated) with public-endpoint fallback; loading / empty / error states. |
| **2. Header (eyebrow "Live mandi prices", title, "Updated {time}")** | `READY` | Client clock + latest `effective_date` row; pull-to-refresh. |
| **3. Search by crop type** | `READY` | Client-side filter (dataset is 18 rows; server has no query params). |
| **4. Mandi strip on dashboards + quick tile + drawer + View All** | `ALREADY BUILT` | Keep; re-point shell so `market-rates` opens the real screen instead of the placeholder; update navigation tests. |
| **5. Set New Rate (bulk grade A/B/C, `effective_date = today`)** | `READY` | Bulk create via `POST /api/v1/market-rates` (one request per filled grade), gated by `canEditMarketRates` (Admin + Super Admin). **Decision D1:** exists in React and in the backend, but **not** in the approved HTML — see decision below. |
| **6. Edit Existing Rate (`rate-editor`, 3 grade inputs)** | `BACKEND REQUIRED` | Approved HTML workflow, but no PATCH/PUT route → mark `"Backend API required — to be supplied by Syed."`; disable/omit edit affordance until supplied. |
| **7. Delete Rate** | `BACKEND REQUIRED` (and likely out of scope) | React-only workflow; absent from both approved HTMLs; no DELETE route → omit, record as backend gap. |
| **8. Change % arrows (`▲/▼`)** | `BACKEND REQUIRED` | Not in `MarketRatePublic`, no history to derive from → omit arrows pending backend, or approve omission permanently. |
| **9. Unit display (₹/qtl vs ₹/kg)** | `DECISION D2` | Approved HTML labels everything **per quintal** (`/qtl`, `/Quintals`, "Rates per quintal"; mock magnitudes 2100–7125 match `price_per_kg × 100`); React widget labels **per kg** (literal field). See decision below. |
| **10. `variety` display** | `N/A` | Never returned by list schemas; skip. |
| **D4. Grain-sales screen strip (`#gs-mandi-strip`)** | `ADJACENT / OPTIONAL` | HTML shows the compact strip on the Grain Sales screen; Flutter's Grain Sales screen has no strip (belongs to the Step 4 surface) — include only if explicitly approved, otherwise defer. |

**Decision points requiring approval:**

- **D1 — Scope of mutations:** the approved HTML offers *edit only*; React offers *create + edit + delete*; the backend offers *create only*. The contract-true intersection is **View + Create**. Recommended scope: build **View + Create (Admin/Super Admin)**, present Edit with a "Backend API required" disabled affordance (mirroring the Step 8 pattern for ad-hoc bills), and omit Delete (absent from approved HTML, no endpoint).
- **D2 — Price unit:** Recommended: display **₹ per quintal** (`price_per_kg × 100`) with `/qtl` labels to match both approved HTMLs (converting `21.50 → ₹2,150/qtl` aligns exactly with the HTML mock magnitudes), while keeping the raw `price_per_kg` as the API value. Alternative: display the literal `price_per_kg` as `₹/kg` (matches `LiveMarketRatesWidget`). Requires explicit approval since it changes on-screen numbers by 100×.

---

## 9. Backend Dependencies

1. **Edit / Update Rate (`PATCH` or `PUT /api/v1/market-rates/{id}`):** required to realise the approved HTML `rate-editor` workflow (all three grades per crop, or a single grade row price). Recorded as: `"Backend API required — to be supplied by Syed."`
2. **Delete Rate (`DELETE /api/v1/market-rates/{id}`):** required for the React delete workflow. Recorded as: `"Backend API required — to be supplied by Syed."` (low priority — not in approved HTML; may be dropped from scope.)
3. **`change_percentage` (or rate history) on the admin/public list schema:** required for the HTML `▲/▼` arrows. Recorded as: `"Backend API required — to be supplied by Syed."` (or approve permanent omission.)
4. **`variety` echoed on list responses (optional):** required only if variety should be visible after creation. Recorded as: `"Backend API required — to be supplied by Syed."`
5. **`POST` repeat semantics (question for Syed):** the OpenAPI does not document upsert/idempotency — whether re-posting the same `crop_type + grade` replaces the row or inserts a duplicate is unspecified. Implementation will avoid re-posting unchanged grades; no blocker, but confirm before bulk-edit workflows are built.
6. **Zero blockers for view + create:** `GET` (public & authenticated) and `POST /api/v1/market-rates` are fully operational on production (probed).
7. **React's Supabase bypass** (`marketService` + `audit_logs` insert) is not reproducible from Flutter — the app is FastAPI-only by golden rule; Flutter must use the FastAPI contract exclusively.

---

## 10. Frontend Dependencies

- Reuse `AppCard`, `StatusPill`, `AppTextField`, `SquircleIconButton`, `EmptyStateView` (and the established loading/error-state patterns) from `lib/core/widgets/`.
- Reuse `AppColors` and `AppTypography`; crop emoji/colour tiles per approved HTML.
- Reuse `MandiRateItem` / `DashboardMandiStrip` (already parse `MarketRatePublic` — the entity can be shared or mapped 1:1).
- Gate mutation affordances with `UserRole.canEditMarketRates` (existing helper, `user_role.dart` L74).
- Extend `AdminShell` and `ManagerShell` to wire `MarketRatesController` and replace `ModulePlaceholderScreen` for `market-rates`; update `navigation_shell_test.dart` assertions accordingly.

---

## 11. Proposed Implementation Scope (Clean Architecture)

```
lib/features/market_rates/
├── data/
│   ├── datasources/
│   │   ├── market_rates_remote_data_source.dart
│   │   └── fast_api_market_rates_remote_data_source.dart
│   └── repositories/
│       └── market_rates_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── market_rate_item.dart          (id, cropType, grade, pricePerKg, effectiveDate)
│   │   └── market_rate_group.dart         (crop + sorted grade rows)
│   ├── exceptions/
│   │   └── market_rates_exception.dart
│   └── repositories/
│       └── market_rates_repository.dart
└── presentation/
    ├── controllers/
    │   └── market_rates_controller.dart   (load, refresh, search, create bulk, RBAC flags)
    ├── screens/
    │   └── market_rates_screen.dart
    └── widgets/
        ├── market_rate_card.dart          (per-crop card + grade grid, approved-HTML styling)
        ├── set_rate_sheet.dart            (bulk A/B/C create; Admin/Super Admin only)
        └── edit_rate_disabled_action.dart ("Backend API required" affordance for rate-editor)
```

Plus: retire `IMarketRatesRepository`'s stale `updateMarketRate(commodityId, A/B/C)` signature (or align it with the real contract) in `api_contracts.dart`, and wire the feature into both shells.

---

## 12. Proposed Test Scope

Preserve baseline: **446 / 446 tests**

### New Tests to Implement:
1. **Domain & JSON Serialization Tests (6 tests):**
   - Parsing `MarketRatePublic` JSON (string `price_per_kg` → double, date, enum grade).
   - Missing/nullable field tolerance and value equality.
   - Grouping logic: rows → per-crop groups sorted by grade (A, B, C).
   - Price conversion for per-quintal display (D2: ×100) vs per-kg display.
2. **Remote Data Source & Repository Tests (7 tests):**
   - `GET /api/v1/market-rates` authenticated success (200) and anonymous fallback to `/public/market-rates`.
   - `POST /api/v1/market-rates` bulk create (one request per filled grade, `effective_date` today, correct `MarketRateCreate` body).
   - Error mappings for 401, 403, 422, 500, and socket timeout.
3. **Controller Tests (7 tests):**
   - Initial load, pull-to-refresh/reload, search query filtering.
   - Create flow success (cache invalidation / list refresh) and failure (sanitised error).
   - RBAC: `canEditMarketRates` true (admin, super admin) vs false (manager) gates the create affordance.
   - Loading, empty, and error states.
4. **Widget & Screen UI Tests (8 tests):**
   - Renders grouped per-crop cards with grade badges and formatted ₹ prices (correct unit per D2).
   - Header eyebrow + updated timestamp present; back button behaviour.
   - Search filters cards; empty-search state.
   - Set Rate sheet: visible for admin, hidden for manager; validation requires ≥1 grade price; submits correct payloads.
   - Edit affordance shows the "Backend API required" notice (not a working form).
5. **Responsive Layout Verification (4 tests):**
   - 320x568, 360x640, 412x860, 412x960 (zero layout overflows — incl. long crop names and 3-column grade grids).
6. **Navigation Integration (2 updated tests):**
   - Update `navigation_shell_test.dart` to assert the real `MarketRatesScreen` replaces `Route: market-rates` placeholder in both shells.

Estimated new tests: **34 tests** (Final expected: 480 / 480).

---

## 13. Known Blockers

- **Edit (approved HTML `rate-editor`) has no FastAPI endpoint.** The screen workflow will be surfaced with a clear `"Backend API required — to be supplied by Syed."` disabled affordance while view, search, refresh, and Admin/Super-Admin rate creation remain 100% functional.
- **Delete has no FastAPI endpoint and no approved-HTML presence** → omitted from scope (recorded as backend gap).
- **Change-% arrows have no data source** (`change_percentage` exists only on the farmer schema; one row per crop+grade means no client-side derivation) → omitted pending backend or explicit approval.
- **React writes go directly to Supabase** — React flows cannot be replayed against FastAPI; only read workflows are comparable, and mutation payloads were reconciled field-by-field against `MarketRateCreate` instead.
- **Decision D1 (create in scope?) and D2 (unit display)** must be resolved by human approval before implementation.

---

## 14. Recommended Implementation Order

1. **Phase 1: Domain & Data Layer** (`MarketRateItem`/`MarketRateGroup` entities, `FastApiMarketRatesRemoteDataSource`, repository with authenticated GET + public fallback + bulk POST; retire stale `updateMarketRate` contract signature).
2. **Phase 2: State Management** (`MarketRatesController` with load/refresh/search/grouping, create flow, RBAC gating).
3. **Phase 3: Presentation Layer** (`MarketRateCard`, `SetRateSheet`, backend-required edit affordance, `MarketRatesScreen` matching approved HTML).
4. **Phase 4: Shell Integration** (wire into `AdminShell` + `ManagerShell`, replace placeholder, update navigation tests).
5. **Phase 5: Automated Testing & Verification** (unit, widget, responsive, and full regression — `flutter analyze`, full test suite, debug APK build).

---

## 15. Final Gate

**`PARTIALLY READY — IMPLEMENT VERIFIED SUBSET`**

*(Rate board viewing, search, refresh, dashboard strip integration, and Admin/Super-Admin rate creation are 100% backend-ready and live-probed. Rate editing (approved HTML), rate deletion (React), and change-% display are gracefully gated pending backend endpoints from Syed. Decisions D1 (scope: View + Create recommended) and D2 (unit: ₹/qtl ×100 recommended) require explicit human approval.)*

---

**Awaiting user approval to proceed to M5 Step 9 implementation.**
