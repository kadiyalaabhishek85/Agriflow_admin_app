# Milestone 5 — Step 6: Seeds Inventory Module Contract Audit

**Document Status:** Complete Audit & Contract Discovery  
**Author:** Antigravity Agent  
**Date:** 2026-09-25  
**Workspace:** `c:\Users\DELL\Downloads\Admin Mobile application build`  

---

## 1. Executive Summary

Milestone 5 Step 6 encompasses the **Seeds Inventory** (`seeds-inventory`) module for the AgriFlow Admin & Manager mobile applications. This audit reconciles the four operational authorities:
1. **FastAPI Backend / OpenAPI Specification (`openapi_dump.json`)**: Sole authority for contracts, schema validation, permissions, and available endpoints.
2. **React / Next.js Web Application (`agriflow/agriflow-web`)**: Functional reference for inventory catalog display, creation modal, edit stock workflow, and search filtering.
3. **Approved Mobile UI/UX HTML Specifications (`AdminMobile UIUX.html` & `Manager Dashboard UIUX.html`)**: Visual and interaction design authority for screens, cards, badges, stock indicators, and add/edit forms.
4. **Flutter Production Codebase (`lib/` and `test/`)**: Native production implementation target.

### Key Audit Findings
- **Verified Core Backend APIs:** The FastAPI backend exposes a full suite of seed catalog management endpoints under `/api/v1/seeds`:
  - `GET /api/v1/seeds`: List all seed products with stock and pricing.
  - `POST /api/v1/seeds`: Create a new seed variety with name, price, stock, variety, and description.
  - `PATCH /api/v1/seeds/{seed_id}`: Update seed price, stock quantity, description, and active status.
  - `DELETE /api/v1/seeds/{seed_id}`: Permanently delete/deactivate a seed product.
- **Backend Gaps / Pending Contracts:**
  - **Warehouse Associations on Seed Entity:** In both HTML prototypes and React (`SeedsInventory.jsx`), UI forms present warehouse assignment options (`warehouse_ids` / `warehouses`). However, the authoritative FastAPI schema (`SeedPublic`, `SeedCreate`, `SeedUpdate`) has **NO** warehouse field. Warehouse-specific storage is tracked under `/api/v1/warehouses/{id}/inventory`. Warehouse assignment on seed catalog creation will be omitted or marked as non-persisted without breaking the master seed catalog.
  - **On-Hold Quantity (`onHold`):** The HTML mockups display an on-hold stock metric (`X Qtl on hold`). The backend `SeedPublic` entity does not have an `on_hold` attribute; pending reservations are computed dynamically from active pending seed purchase orders.
  - **Updating Name & Variety:** `SeedUpdate` schema in FastAPI only permits mutating `price_per_kg`, `stock_kg`, `description`, and `is_active`. Seed `name` and `variety` are immutable after creation.
- **Role Differentiation:**
  - **Admin / Super Admin:** Full CRUD authority (view directory, search, add new seed, edit price & stock, toggle active status, delete seed).
  - **Manager:** Read-only directory access and real-time search. Managers can view stock levels and low-stock warnings to coordinate farmer purchases, but mutating the central seed master catalog is restricted to Admin.
- **Gate Recommendation:** **READY FOR IMPLEMENTATION** for all verified capabilities.

---

## 2. Backend Endpoint Inventory

| HTTP Method | Route | Summary | Operation ID | Security | Status |
|:---|:---|:---|:---|:---|:---|
| `GET` | `/api/v1/seeds` | List all seeds in master inventory | `list_seeds_api_v1_seeds_get` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `POST` | `/api/v1/seeds` | Create new seed variety in catalog | `create_seed_api_v1_seeds_post` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `PATCH` | `/api/v1/seeds/{seed_id}` | Update seed price, stock, active status | `update_seed_api_v1_seeds__seed_id__patch` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `DELETE` | `/api/v1/seeds/{seed_id}` | Delete seed variety | `delete_seed_api_v1_seeds__seed_id__delete` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `GET` | `/api/v1/public/seeds` | Public seed catalog (unauthenticated) | `seed_catalog_api_v1_public_seeds_get` | None | **VERIFIED BACKEND (Public)** |

---

## 3. Request/Response Schema Audit

### 3.1 `GET /api/v1/seeds`
- **Query Parameters:** None (returns full master catalog list).
- **Security:** Bearer token required.
- **Response `200 OK`:** `SuccessResponse[list[SeedPublic]]`
  ```json
  {
    "success": true,
    "message": "Success",
    "data": [
      {
        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "name": "BPT-5204 (Samba Mahsuri)",
        "variety": "Paddy",
        "price_per_kg": "65.50",
        "stock_kg": "12500.00",
        "description": "High yield pest resistant paddy seeds",
        "image_url": "https://example.com/seed.jpg",
        "is_active": true
      }
    ]
  }
  ```

### 3.2 `POST /api/v1/seeds` (Create Seed)
- **Security:** Bearer token required (Admin / Super Admin).
- **Request Body:** `SeedCreate`
  ```json
  {
    "name": "BPT-5204",                    // required, string (2..120 chars)
    "variety": "Paddy",                     // optional, string or null
    "price_per_kg": 65.50,                  // required, number > 0 or decimal string
    "stock_kg": 12500.0,                    // required, number >= 0 or decimal string
    "description": "High yield variety",    // optional, string or null
    "image_url": null                       // optional, string or null
  }
  ```
- **Response `201 Created`:** `SuccessResponse[SeedPublic]`
  ```json
  {
    "success": true,
    "message": "Success",
    "data": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "name": "BPT-5204",
      "variety": "Paddy",
      "price_per_kg": "65.50",
      "stock_kg": "12500.00",
      "description": "High yield variety",
      "image_url": null,
      "is_active": true
    }
  }
  ```

### 3.3 `PATCH /api/v1/seeds/{seed_id}` (Update Seed)
- **Path Parameter:** `seed_id` (UUID string)
- **Security:** Bearer token required (Admin / Super Admin).
- **Request Body:** `SeedUpdate`
  ```json
  {
    "price_per_kg": 70.0,                   // optional, number > 0 or decimal string
    "stock_kg": 15000.0,                    // optional, number >= 0 or decimal string
    "description": "Updated notes",         // optional, string or null
    "is_active": true                       // optional, boolean or null
  }
  ```
- **Response `200 OK`:** `SuccessResponse[SeedPublic]`

### 3.4 `DELETE /api/v1/seeds/{seed_id}`
- **Path Parameter:** `seed_id` (UUID string)
- **Security:** Bearer token required (Admin / Super Admin).
- **Response `204 No Content`**

---

## 4. React / Next.js Functional Reference (`agriflow-web`)

Source file: `src/pages/admin/SeedsInventory.jsx` (and `src/services/adminService.js`)
- **Query / Data Fetching:** Calls `adminService.getSeeds()` via TanStack Query.
- **Search:** Local search query matching both `name` and `variety`.
- **Add Modal:** Form with Name, Variety, Price/kg, Stock (entered in Quintals, multiplied by 100 to send `stock_kg`), Description, and active flag.
- **Edit Modal:** Pre-populates existing price and stock, allows adjustment.
- **Delete Action:** Confirmation dialog (`window.confirm`) followed by `adminService.deleteSeed(seed.id)`.
- **Stock Conversion:** UI displays stock in Quintals (`stock_kg / 100`).

---

## 5. Approved Mobile HTML UI/UX Reference

### 5.1 Admin Screen: `#screen-seeds-inventory` (`AdminMobile UIUX.html`)
- **Header:**
  - Back button (`data-nav="home"`).
  - Title: "Seeds Inventory" with eyebrow "Stock levels".
  - Action Button: "+ Add Seed" primary button opening `#overlay-edit` / seed form.
- **Search Bar:** Real-time input (`#inventory-search`) filtering by name and variety.
- **Inventory Cards (`#inventory-grid`):**
  - **Header Row:** Seed name, Variety (`—` if null), Status badge (`Active` [good pill] / `Inactive` [neutral pill]).
  - **Metric Row:**
    - Price: `₹{price}/kg` in canopy-deep bold font.
    - Stock: `{stock} Qtl stock` (or kg) with `Low` bad pill if stock < 5 Qtl (500 kg).
    - On Hold indicator: `{onHold} Qtl on hold` (accent warning).
  - **Action Row:**
    - Ghost "Edit" button (opens edit modal).
    - Danger "Delete" button (triggers confirmation dialog).

### 5.2 Manager Screen: `#screen-seeds-inventory` (`Manager Dashboard UIUX.html`)
- **Header:** Title "Seeds Inventory", subtitle "Seeds inventory desc".
- **Search Bar:** Search input (`#search-seeds-input`).
- **Inventory Cards:** Displays stock levels, low-stock alerts, price, and active pill.
- **Permissions:** In Manager HTML prototype, Add/Edit buttons are statically present, but according to the Backend Engineering Specification (`Backend_Technical_Specification.md`, line 559), seed master inventory management is strictly Super Admin restricted.

---

## 6. Admin vs Manager Permission Matrix

| Capability | Super Admin / Admin | Manager | Authority & Enforcement |
|:---|:---|:---|:---|
| **View Seeds Directory** | Full Access | Full Access | FastAPI `GET /api/v1/seeds` |
| **Search Seeds by Name/Variety**| Full Access | Full Access | Client-side reactive filter |
| **Inspect Stock & Low Stock Warnings** | Full Access | Full Access | Business rule (< 5 Qtl / 500 kg) |
| **Add New Seed Variety** | Allowed | Hidden / Disabled | Backend Matrix line 559 (`require_role`) |
| **Edit Price & Stock** | Allowed | Hidden / Disabled | Backend Matrix line 559 (`require_role`) |
| **Delete Seed** | Allowed | Hidden / Disabled | Backend Matrix line 559 (`require_role`) |

---

## 7. Discrepancies & Backend Gaps

| Feature in HTML/React | Backend Contract (`openapi_dump.json`) | Resolution in Flutter Implementation |
|:---|:---|:---|
| **Warehouse Assignment** | Not supported in `SeedCreate` or `SeedPublic` | Exclude warehouse selection from Seed form; warehouse inventory is handled in the Warehouse module. |
| **On-Hold Quantity (`onHold`)** | Not in `SeedPublic` entity | Omit static on-hold metric or calculate dynamically if purchase requests are loaded. |
| **Update Name & Variety** | `SeedUpdate` schema only includes `price_per_kg`, `stock_kg`, `description`, `is_active` | Name & variety will be read-only during edit, editable only upon initial creation. |
| **Stock Unit Representation** | Backend stores `stock_kg` (in kilograms) | Support clear dual display: `Kg` and `Qtl` (1 Qtl = 100 kg), transmitting `stock_kg` to FastAPI. |

---

## 8. Proposed Flutter Architecture Scope

### 8.1 Domain Layer (`lib/features/seeds_inventory/domain/`)
- `entities/seed_inventory_item.dart`:
  - Fields: `id`, `name`, `variety`, `pricePerKg`, `stockKg`, `description`, `imageUrl`, `isActive`.
  - Helpers: `stockQtl`, `isLowStock` (stockKg < 500.0), `displayPrice`.
- `repositories/seeds_inventory_repository.dart`:
  - `Future<List<SeedInventoryItem>> getSeeds({required String accessToken})`
  - `Future<SeedInventoryItem> createSeed({required String accessToken, required String name, required double pricePerKg, required double stockKg, String? variety, String? description})`
  - `Future<SeedInventoryItem> updateSeed({required String accessToken, required String seedId, double? pricePerKg, double? stockKg, String? description, bool? isActive})`
  - `Future<void> deleteSeed({required String accessToken, required String seedId})`
- `entities/seeds_inventory_exception.dart`: Specific exceptions for network, unauthorized, and validation errors.

### 8.2 Data Layer (`lib/features/seeds_inventory/data/`)
- `datasources/seeds_inventory_remote_data_source.dart`:
  - `FastApiSeedsInventoryRemoteDataSource`: HTTP client handling GET, POST, PATCH, DELETE at `/api/v1/seeds`.
- `repositories/seeds_inventory_repository_impl.dart`: Implementation mapping responses and errors.

### 8.3 Presentation Layer (`lib/features/seeds_inventory/presentation/`)
- `controllers/seeds_inventory_controller.dart`:
  - State: `isLoading`, `errorMessage`, `seeds`, `filteredSeeds`, `searchQuery`, `isMutating`.
  - Methods: `loadSeeds()`, `setSearchQuery(String)`, `addSeed(...)`, `updateSeed(...)`, `deleteSeed(String)`.
- `screens/seeds_inventory_screen.dart`:
  - Responsive screen matching `#screen-seeds-inventory`.
  - Search bar with live debounce.
  - Pull-to-refresh (`RefreshIndicator`).
  - Add Seed header button (gated to Admin).
  - Empty, loading, and error state handling.
- `widgets/seed_inventory_card.dart`:
  - Displaying name, variety, status pill, price/kg, stock in Qtl & Kg, low-stock warning.
  - Action buttons: Edit & Delete (Admin only).
- `widgets/add_edit_seed_sheet.dart`:
  - Modal bottom sheet matching `#overlay-edit` with form validation (Name, Variety, Price, Stock, Description, Active toggle).

### 8.4 Navigation Integration
- Hook into `AdminShell` and `ManagerShell` replacing `ModulePlaceholderScreen` for `NavDestination.seedsInventory`.

---

## 9. Required Tests

1. **Domain Model & Entity Tests:**
   - JSON deserialization of `SeedPublic` with string/number decimal values.
   - Conversion between `stockKg` and `stockQtl`.
   - Low-stock condition evaluation (< 500 kg).
2. **Data Source & Repository Tests:**
   - `getSeeds` parsing `SuccessResponse[list[SeedPublic]]`.
   - `createSeed` sending `SeedCreate` payload.
   - `updateSeed` sending `SeedUpdate` payload.
   - `deleteSeed` handling 204 No Content.
   - Error mapping for 401, 403, 422, 500.
3. **Controller Tests:**
   - Initial load state transition.
   - Live search query filtering by name and variety.
   - Mutation states during add, update, and delete.
4. **Widget & Screen Tests:**
   - Rendering seed cards with correct styling and status pills.
   - Low-stock badge rendering when stock < 500 kg.
   - Role gating: Add, Edit, and Delete actions rendered for Admin, hidden for Manager.
   - Form validation in `add_edit_seed_sheet.dart`.
5. **Regression & APK Build:**
   - Full regression across all existing 197 tests.
   - `flutter analyze` reports 0 issues.

---

## 10. Audit Conclusion & Gate Recommendation

### **STATUS: READY FOR IMPLEMENTATION**

- **Module:** Milestone 5 — Step 6: Seeds Inventory (`seeds-inventory`)
- **Backend Readiness:** All endpoints (`GET`, `POST`, `PATCH`, `DELETE` `/api/v1/seeds`) are verified and available in FastAPI.
- **Authority Consistency:** The discrepancies regarding warehouse assignment and static on-hold counts are cleanly identified and will not be invented in Flutter.
- **Role Enforcement:** Clear separation of Admin (full CRUD) vs Manager (read-only catalog inspection) is preserved according to the backend security matrix.

*Awaiting user approval to proceed to Milestone 5 Step 6 implementation.*
