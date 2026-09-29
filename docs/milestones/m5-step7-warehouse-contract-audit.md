# Milestone 5 — Step 7: Warehouse Module Contract Audit

**Document Status:** Complete Contract & Specification Audit  
**Evaluator:** Antigravity Mobile Engineering Agent  
**Date:** September 26, 2026  
**Target Backend:** `https://agriflow-backend-t8o4.onrender.com`  
**Live OpenAPI Source:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`  
**Workspace:** `c:\Users\DELL\Downloads\Admin Mobile application build`  

---

## 1. Executive Summary

Milestone 5 Step 7 encompasses the **Warehouse Management** (`warehouse`) operational module for the AgriFlow Admin and Manager Mobile Flutter applications.

This audit evaluates and reconciles the four operational authorities:
1. **Live Deployed FastAPI Backend (`https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`):** Absolute data authority, schema validation, permissions, and available endpoints.
2. **React Functional Web Reference (`agriflow/agriflow-web/src/pages/admin/Warehouse.jsx` & `src/services/warehouseService.js`):** Functional baseline for warehouse capacity tracking, grain inventory intake, and booking slot scheduling.
3. **Approved Mobile UI/UX HTML Specifications (`AdminMobile UIUX.html` & `Manager Dashboard UIUX.html`):** Visual, typographic, and interaction design authority (`screen-warehouse`, warehouse cards, capacity fill meters, `warehouse-form`, inventory modals).
4. **Current Flutter Mobile Codebase (`lib/features/warehouse/`, `AdminShell`, `ManagerShell`):** Target native implementation.

### Major Finding: Complete Backend Readiness
In earlier project reviews (e.g. `docs/backend-requirements-admin-mobile.md`), the Warehouse module was identified as partially blocked due to missing endpoints for warehouse updating (`PATCH`), warehouse deletion (`DELETE`), grain inventory listing (`GET .../inventory`), and slot hard deletion (`DELETE .../slots/{id}`).

**Our live inspection of the production OpenAPI schema confirms that backend developer Syed has now DEPLOYED all of these endpoints to production.**
- `GET /api/v1/warehouses`: List all warehouses (VERIFIED LIVE)
- `POST /api/v1/warehouses`: Create warehouse (VERIFIED LIVE)
- `GET /api/v1/warehouses/{warehouse_id}`: Single warehouse detail (VERIFIED LIVE)
- `PATCH /api/v1/warehouses/{warehouse_id}`: Update warehouse metadata & status (VERIFIED LIVE)
- `DELETE /api/v1/warehouses/{warehouse_id}`: Delete warehouse (VERIFIED LIVE)
- `GET /api/v1/warehouses/{warehouse_id}/inventory`: List grain inventory breakdown (VERIFIED LIVE)
- `POST /api/v1/warehouses/{warehouse_id}/inventory`: Add grain stock (VERIFIED LIVE)
- `GET /api/v1/warehouses/{warehouse_id}/slots`: List slots for warehouse (VERIFIED LIVE)
- `GET /api/v1/warehouse-slots`: List slots with query filters (VERIFIED LIVE)
- `POST /api/v1/warehouse-slots`: Create booking slot (VERIFIED LIVE)
- `PATCH /api/v1/warehouse-slots/{slot_id}`: Update slot capacity / status (VERIFIED LIVE)
- `DELETE /api/v1/warehouse-slots/{slot_id}`: Delete booking slot (VERIFIED LIVE)

No backend blockers exist. The module is **READY FOR IMPLEMENTATION**.

---

## 2. Exact Step 7 Module

- **Module Name:** Warehouse (`warehouse`)
- **Module Title:** Warehouse / Storage Locations
- **Roadmap Sequence:** Milestone 5, Step 7
- **Module Path:** `lib/features/warehouse/`
- **Section Group:** `NavSection.operations`
- **Primary Roles:** Admin, Super Admin, Manager

---

## 3. Navigation Reference

The warehouse destination is formally defined in `lib/core/navigation/nav_destination.dart`:
```dart
static const warehouse = NavDestination(
  id: 'warehouse',
  title: 'Warehouse',
  icon: Icons.warehouse_outlined,
  section: NavSection.operations,
);
```

### Access Points in Native Navigation:
1. **Admin Drawer:** Located under `Operations` section -> `Warehouse`.
2. **Manager Drawer:** Located under `Operations` section -> `Warehouse`.
3. **Admin Dashboard Quick Actions Grid:** 
   - Icon: `Icons.warehouse_outlined`
   - Color: Purple container (`#F4F2F7`, icon `#6B4C9A`)
   - Target route: `NavDestination.warehouse.id`
4. **Manager Dashboard Quick Actions Grid:**
   - Icon: `Icons.warehouse_outlined`
   - Color: Purple container (`#F4F2F7`, icon `#6B4C9A`)
   - Target route: `NavDestination.warehouse.id`
5. **Dashboard Storage Facility Card:** Tapping the live storage overview on the Admin dashboard routes directly to `warehouse`.

---

## 4. React Functional Reference

**Files:** `agriflow/agriflow-web/src/pages/admin/Warehouse.jsx` and `src/services/warehouseService.js`

### Key Functional Workflows:
1. **Warehouse Catalog & Occupancy Tracking:**
   - Displays all warehouses sorted by name.
   - Computes occupancy percentage: `(current_load_kg / total_capacity_kg) * 100`.
   - Color-codes capacity fill bars:
     - `< 60%`: Green (`warehouse-fill-green`)
     - `60% - 80%`: Yellow (`warehouse-fill-yellow`)
     - `> 80%`: Red (`warehouse-fill-red`)
   - Dual-unit display: Shows values in Quintals (`Qtl`) and Kilograms (`kg`) where `1 Qtl = 100 kg`.
2. **Add Warehouse Flow (Admin Only):**
   - Modal form requesting: `name`, `address`, `total_capacity_kg`.
   - Admin enters capacity in Quintals; web app converts to kg (`parseFloat(form.total_capacity_kg) * 100`).
3. **Selected Warehouse Detail Panel:**
   - Triggered on selecting a warehouse card.
   - Displays grain inventory breakdown (`grain_type`, `quantity_kg` in Quintals, `% of total capacity`, `last_updated`).
   - Action `+ Add Inv`: Adds stock of a specific grain type (e.g. "Rice", "Wheat", "Maize", or custom seed type) in Quintals.
   - Action `+ Add Slot`: Creates a farmer procurement intake slot (`slot_date`, `start_time`, `end_time`, `total_capacity_kg` in Quintals).
   - Time Slots list: Displays time window, booked capacity vs total capacity in Quintals, and percentage booked.

---

## 5. Approved HTML Reference

**Files:** `AdminMobile UIUX.html` (lines 905-915, 2414-2432, 2709-2712) and `Manager Dashboard UIUX.html` (lines 835-845, 3140-3160)

### UI/UX Design System Specifications:
1. **Screen Shell (`id="screen-warehouse"`):**
   - Header: Back button (`#i-chevron-l`), eyebrow `Storage locations`, title `Warehouse` (20px, font-weight 600).
   - Admin Action: Header action button or list banner `+ Add Warehouse` (`btn primary block` with `#i-plus`).
2. **Warehouse Card (`.card` with 14px padding):**
   - Top Row:
     - Rounded icon container (36x36px, background `#F4F2F7`, border radius 11px) with purple warehouse icon `#6B4C9A`.
     - Title: 13.5px font-weight 800 (`w.name`).
     - Subtitle: 11.5px text-muted (`w.location` or `w.address`).
     - Status Pill: `.pill.good` ("Active") or `.pill.neutral` ("Inactive").
     - Admin Action: Edit icon button (`icon-btn`, 36x36px with `#i-edit`).
   - Progress Bar:
     - Track: `.slot-bar-track` (10-12px top margin, background `var(--line)`).
     - Fill: `.slot-bar-fill` (width `%`, background `var(--forest)` or red if >= 100%).
   - Bottom Row:
     - Left: `${w.used.toLocaleString('en-IN')} / ${w.capacity.toLocaleString('en-IN')} qtl capacity used` (11px, `var(--text-faint)`).
     - Right: `${Math.round(w.used / w.capacity * 100)}%` (10.5px, font-weight 800, `var(--text-muted)`).
3. **Warehouse Form Sheet (`openWarehouseForm`):**
   - Header: "Add Warehouse" / "Edit Warehouse".
   - Subtitle: "Enter the warehouse details below."
   - Fields:
     - `Warehouse name` (`wh-name`): string input.
     - `Location` (`wh-location`): string input.
     - `Capacity (qtl)` (`wh-capacity`): numeric input.
     - `Used capacity (qtl)` (`wh-used`): numeric input (during edit).
   - Action: Primary block button "Add Warehouse" / "Save Changes".

---

## 6. Live Backend Contract

All endpoints below were queried directly from `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`.

| HTTP Method | Route | Operation ID | Security | Status |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/v1/warehouses` | `list_warehouses_api_v1_warehouses_get` | OAuth2 Bearer | **VERIFIED LIVE** |
| `POST` | `/api/v1/warehouses` | `create_warehouse_api_v1_warehouses_post` | OAuth2 Bearer | **VERIFIED LIVE** |
| `GET` | `/api/v1/warehouses/{warehouse_id}` | `get_warehouse_api_v1_warehouses__warehouse_id__get` | OAuth2 Bearer | **VERIFIED LIVE** |
| `PATCH` | `/api/v1/warehouses/{warehouse_id}` | `update_warehouse_api_v1_warehouses__warehouse_id__patch` | OAuth2 Bearer | **VERIFIED LIVE** |
| `DELETE` | `/api/v1/warehouses/{warehouse_id}` | `delete_warehouse_api_v1_warehouses__warehouse_id__delete` | OAuth2 Bearer | **VERIFIED LIVE** |
| `GET` | `/api/v1/warehouses/{warehouse_id}/inventory` | `get_inventory_api_v1_warehouses__warehouse_id__inventory_get` | OAuth2 Bearer | **VERIFIED LIVE** |
| `POST` | `/api/v1/warehouses/{warehouse_id}/inventory` | `add_inventory_api_v1_warehouses__warehouse_id__inventory_post` | OAuth2 Bearer | **VERIFIED LIVE** |
| `GET` | `/api/v1/warehouses/{warehouse_id}/slots` | `list_slots_api_v1_warehouses__warehouse_id__slots_get` | OAuth2 Bearer | **VERIFIED LIVE** |
| `GET` | `/api/v1/warehouse-slots` | `list_warehouse_slots_api_v1_warehouse_slots_get` | OAuth2 Bearer | **VERIFIED LIVE** |
| `POST` | `/api/v1/warehouse-slots` | `create_warehouse_slot_api_v1_warehouse_slots_post` | OAuth2 Bearer | **VERIFIED LIVE** |
| `PATCH` | `/api/v1/warehouse-slots/{slot_id}` | `update_warehouse_slot_api_v1_warehouse_slots__slot_id__patch` | OAuth2 Bearer | **VERIFIED LIVE** |
| `DELETE` | `/api/v1/warehouse-slots/{slot_id}` | `delete_warehouse_slot_api_v1_warehouse_slots__slot_id__delete` | OAuth2 Bearer | **VERIFIED LIVE** |

---

## 7. Request/Response Schemas

### 7.1 `WarehousePublic` (Response DTO)
Returned by `GET /api/v1/warehouses`, `POST /api/v1/warehouses`, `GET /api/v1/warehouses/{id}`, `PATCH /api/v1/warehouses/{id}`.
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "Kurnool Storage Facility",
  "address": "Industrial Area, Kurnool, AP",
  "location": "Kurnool",
  "contact_number": "+91 98765 43210",
  "total_capacity_kg": "100000.00",
  "current_load_kg": "45000.00",
  "manager_id": "3fa85f64-5717-4562-b3fc-2c963f66af99",
  "is_active": true
}
```
*Note:* `total_capacity_kg` and `current_load_kg` are formatted as decimal strings.

### 7.2 `WarehouseCreate` (Request DTO)
Used in `POST /api/v1/warehouses`:
| Field | Type | Required | Constraints |
| :--- | :--- | :--- | :--- |
| `name` | string | Yes | Min 2, max 160 characters |
| `address` | string | Yes | Min 4 characters |
| `total_capacity_kg` | number / string | Yes | `> 0`, numeric pattern |
| `location` | string / null | No | Optional geographic tag |
| `contact_number` | string / null | No | Optional contact phone |
| `manager_id` | UUID / null | No | Optional manager assignment |

### 7.3 `WarehouseUpdate` (Request DTO)
Used in `PATCH /api/v1/warehouses/{warehouse_id}`:
| Field | Type | Required | Constraints |
| :--- | :--- | :--- | :--- |
| `name` | string / null | No | Max 160 characters |
| `address` | string / null | No | Min 4 characters |
| `total_capacity_kg` | number / string / null | No | `> 0`, numeric pattern |
| `location` | string / null | No | Optional geographic tag |
| `contact_number` | string / null | No | Optional contact phone |
| `manager_id` | UUID / null | No | Optional manager assignment |
| `is_active` | boolean / null | No | Active status toggle |

### 7.4 `WarehouseInventoryPublic` (Response DTO)
Returned by `GET /api/v1/warehouses/{warehouse_id}/inventory` and `POST .../inventory`:
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66af11",
  "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "grain_type": "Wheat",
  "quantity_kg": "15000.00"
}
```

### 7.5 `WarehouseInventoryAdd` (Request DTO)
Used in `POST /api/v1/warehouses/{warehouse_id}/inventory`:
| Field | Type | Required | Constraints |
| :--- | :--- | :--- | :--- |
| `grain_type` | string | Yes | Min 2, max 80 characters |
| `quantity_kg` | number / string | Yes | `> 0`, numeric pattern |

### 7.6 `WarehouseSlotPublic` (Response DTO)
Returned by `GET /api/v1/warehouses/{id}/slots`, `GET /api/v1/warehouse-slots`, `POST /api/v1/warehouse-slots`, `PATCH /api/v1/warehouse-slots/{id}`:
```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66af22",
  "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "slot_date": "2026-09-30",
  "start_time": "09:00:00",
  "end_time": "13:00:00",
  "capacity_kg": "10000.00",
  "booked_kg": "4500.00",
  "status": "active"
}
```

### 7.7 `WarehouseSlotCreate` (Request DTO)
Used in `POST /api/v1/warehouse-slots`:
| Field | Type | Required | Constraints |
| :--- | :--- | :--- | :--- |
| `warehouse_id` | UUID | Yes | Target warehouse UUID |
| `slot_date` | string (date) | Yes | Format `YYYY-MM-DD` |
| `start_time` | string (time) | Yes | Format `HH:MM:SS` |
| `end_time` | string (time) | Yes | Format `HH:MM:SS` |
| `capacity_kg` | number / string | Yes | `> 0`, numeric pattern |

### 7.8 `WarehouseSlotUpdate` (Request DTO)
Used in `PATCH /api/v1/warehouse-slots/{slot_id}`:
| Field | Type | Required | Constraints |
| :--- | :--- | :--- | :--- |
| `status` | string / null | No | Regex `^(active\|cancelled)$` |
| `capacity_kg` | number / string / null | No | `> 0`, numeric pattern |

---

## 8. Role-Based Access Control (RBAC) Matrix

| Operation | Super Admin | Admin | Manager | Farmer | Backend Enforcement |
| :--- | :---: | :---: | :---: | :---: | :--- |
| List Warehouses | Allowed | Allowed | Allowed | Allowed (Farmer API) | Bearer Token |
| View Warehouse Detail | Allowed | Allowed | Allowed | Allowed (Farmer API) | Bearer Token |
| Create Warehouse | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** | `require_admin` dependency |
| Update Warehouse | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** | `require_admin` dependency |
| Delete Warehouse | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** | `require_admin` dependency |
| View Warehouse Inventory | Allowed | Allowed | Allowed | **FORBIDDEN (403)** | Bearer Token |
| Add Grain Inventory Stock | Allowed | Allowed | Allowed | **FORBIDDEN (403)** | Bearer Token |
| View Warehouse Slots | Allowed | Allowed | Allowed | Allowed (Farmer API) | Bearer Token |
| Create Warehouse Slot | Allowed | Allowed | Allowed | **FORBIDDEN (403)** | Bearer Token |
| Update / Cancel Slot | Allowed | Allowed | Allowed | **FORBIDDEN (403)** | Bearer Token |
| Delete Booking Slot | Allowed | Allowed | Allowed | **FORBIDDEN (403)** | Bearer Token |

---

## 9. Admin vs Manager Capability Matrix

| Feature / UI Flow | Admin / Super Admin | Manager | Flutter Mobile UX Rule |
| :--- | :---: | :---: | :--- |
| "+ Add Warehouse" Button | Visible & Active | **Hidden** | Hide button in header/appbar when `!isAdmin`. |
| Edit Warehouse Action | Visible & Active | **Hidden** | Hide `#i-edit` button on card when `!isAdmin`. |
| Delete Warehouse Action | Visible & Active | **Hidden** | Hide delete action when `!isAdmin`. |
| View Inventory Breakdown | Visible & Active | Visible & Active | Both roles can inspect stored grain stocks. |
| Add Grain Stock Intake | Visible & Active | Visible & Active | Both roles can record incoming grain batches. |
| Create Booking Slot | Visible & Active | Visible & Active | Both roles can configure operational slots. |
| Cancel Booking Slot | Visible & Active | Visible & Active | Both roles can cancel active booking slots. |
| Delete Booking Slot | Visible & Active | Visible & Active | Both roles can delete unbooked slots. |
| 403 Forbidden Handling | Visible error dialog | Visible error banner | If server rejects with 403, display clear toast/dialog. |

---

## 10. Flutter Current State

- Directory structure exists under `lib/features/warehouse/`:
  - `lib/features/warehouse/data/` (only `.gitkeep`)
  - `lib/features/warehouse/domain/` (only `.gitkeep`)
  - `lib/features/warehouse/presentation/` (only `.gitkeep`)
- Shell Integration:
  - Both `AdminShell` and `ManagerShell` map `NavDestination.warehouse.id` to `ModulePlaceholderScreen`.
- Shared Dependencies:
  - `lib/features/booking_slot/domain/entities/warehouse_item.dart` contains a minimal entity used for booking dropdowns.
  - A comprehensive, first-class entity set is required for the dedicated `warehouse` feature.
- Test Coverage: 0 tests exist for `lib/features/warehouse/`.

---

## 11. Feature-Parity Matrix

| Feature | React Web | Approved HTML | Live FastAPI | Current Flutter | Parity Status |
| :--- | :---: | :---: | :---: | :---: | :--- |
| Warehouse Listing | Yes | Yes | `GET /api/v1/warehouses` | Placeholder | VERIFIED |
| Capacity Progress Bar | Yes | Yes | `total_capacity_kg`, `current_load_kg` | Placeholder | VERIFIED |
| Quintal Conversions | Yes (1 Qtl = 100 kg) | Yes | Backend is Kg | Placeholder | VERIFIED |
| Add Warehouse | Yes | Yes | `POST /api/v1/warehouses` | Placeholder | VERIFIED |
| Edit Warehouse | No (direct DB) | Yes | `PATCH /api/v1/warehouses/{id}` | Placeholder | VERIFIED |
| Delete Warehouse | No | No | `DELETE /api/v1/warehouses/{id}` | Placeholder | VERIFIED |
| Grain Inventory Breakdown | Yes | No | `GET /api/v1/warehouses/{id}/inventory` | Placeholder | VERIFIED |
| Add Grain Stock | Yes | No | `POST /api/v1/warehouses/{id}/inventory` | Placeholder | VERIFIED |
| List Booking Slots | Yes | No | `GET /api/v1/warehouses/{id}/slots` | Placeholder | VERIFIED |
| Create Booking Slot | Yes | No | `POST /api/v1/warehouse-slots` | Placeholder | VERIFIED |
| Cancel Booking Slot | Yes | No | `PATCH /api/v1/warehouse-slots/{id}` | Placeholder | VERIFIED |
| Delete Booking Slot | No | No | `DELETE /api/v1/warehouse-slots/{id}` | Placeholder | VERIFIED |

---

## 12. Backend Gaps

**NONE.**  
All 12 required endpoints and their request/response schemas are deployed and verified live in OpenAPI 3.1.

*Note on Pagination:*  
`GET /api/v1/warehouses` and `GET /api/v1/warehouses/{id}/inventory` return complete array listings in `data: [...]` without pagination offset/limit query parameters. The Flutter client will parse and manage the list directly.

---

## 13. Frontend Gaps

The native Flutter implementation has not yet been built. The following layers must be implemented in Milestone 5 Step 7 Phase 2:
1. **Domain Layer:**
   - `WarehouseItem` entity with computed getters for Quintals (`usedQtl`, `totalQtl`, `availableQtl`, `occupancyPercent`, `isOverCapacity`, `isNearCapacity`).
   - `WarehouseInventoryItem` entity (`id`, `warehouseId`, `grainType`, `quantityKg`, `quantityQtl`).
   - `WarehouseSlotItem` entity (`id`, `warehouseId`, `slotDate`, `startTime`, `endTime`, `capacityKg`, `bookedKg`, `status`, `occupancyPercent`, `isCancelled`).
   - `WarehouseException` hierarchy mapping HTTP 401, 403, 404, 409, 422, 500.
   - `WarehouseRepository` interface.
2. **Data Layer:**
   - `FastApiWarehouseRemoteDataSource` using `http` package with Bearer authentication and standard JSON envelope unwrapping.
   - `WarehouseRepositoryImpl` bridging remote data source to domain entities.
3. **Presentation Layer:**
   - `WarehouseController` (`ChangeNotifier`) managing warehouse lists, selected warehouse detail, inventory breakdown, booking slots, search queries, and mutation states.
   - `WarehouseScreen` with search, summary cards, and responsive warehouse cards.
   - `WarehouseCard` matching approved HTML design (36x36px purple icon, capacity meter, used/capacity in Quintals, role-gated edit button).
   - `WarehouseDetailSheet` showing capacity metrics, grain inventory breakdown, and booking slots list.
   - `AddEditWarehouseSheet` (Admin only) supporting create and update.
   - `AddInventorySheet` for grain stock intake.
   - `CreateSlotSheet` for slot scheduling.
4. **Shell Integration:**
   - Replace `ModulePlaceholderScreen` in `AdminShell` and `ManagerShell` with `WarehouseScreen`.

---

## 14. Data / Business Rule Gaps

1. **Unit of Measure Reconciliation:**
   - Backend persists capacities strictly in **Kilograms (`kg`)**.
   - UI displays values in **Quintals (`Qtl`)** and **Kilograms (`kg`)**, where:
     $$\text{1 Quintal (Qtl)} = 100\text{ Kilograms (kg)}$$
   - Form inputs for capacity must accept Quintals and multiply by 100 before transmitting to backend.
2. **Color Thresholds for Capacity:**
   - $< 60\%$ occupancy: Green (`#16A34A` / `AppColors.forest`)
   - $60\% - 80\%$ occupancy: Amber/Yellow (`#D97706` / `AppColors.amber`)
   - $> 80\%$ occupancy: Red/Alert (`#DC2626` / `AppColors.alert`)
   - $\ge 100\%$ occupancy: Over-capacity alert indicator.
3. **Slot Status Semantics:**
   - Allowed values: `"active"` or `"cancelled"`.
   - Cancellation is performed via `PATCH /api/v1/warehouse-slots/{slot_id}` with `{"status": "cancelled"}`.
   - Unbooked slots can also be hard-deleted via `DELETE /api/v1/warehouse-slots/{slot_id}`.

---

## 15. Proposed Contracts

*(No contracts are proposed. All required contracts are verified and deployed on the live backend.)*

---

## 16. Recommended Implementation Scope

### Phase 2 Implementation Architecture:
```
lib/features/warehouse/
├── data/
│   ├── datasources/
│   │   └── fast_api_warehouse_remote_data_source.dart
│   └── repositories/
│       └── warehouse_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── warehouse_item.dart
│   │   ├── warehouse_inventory_item.dart
│   │   └── warehouse_slot_item.dart
│   ├── exceptions/
│   │   └── warehouse_exception.dart
│   └── repositories/
│       └── warehouse_repository.dart
└── presentation/
    ├── controllers/
    │   └── warehouse_controller.dart
    ├── screens/
    │   └── warehouse_screen.dart
    └── widgets/
        ├── add_edit_warehouse_sheet.dart
        ├── add_inventory_sheet.dart
        ├── create_slot_sheet.dart
        ├── warehouse_card.dart
        └── warehouse_detail_sheet.dart
```

---

## 17. Test Plan

A minimum of 32 comprehensive tests will be implemented across:
1. **Domain Tests:**
   - `WarehouseItem` JSON serialization/deserialization.
   - Decimal string parsing for `total_capacity_kg` and `current_load_kg`.
   - Kg to Quintal mathematical conversion accuracy.
   - Occupancy percentage computation and zero-capacity guard.
   - Over-capacity and near-capacity flags.
   - `WarehouseInventoryItem` JSON parsing and quintal getters.
   - `WarehouseSlotItem` JSON parsing, time range formatting, and status getters.
   - `WarehouseException` status code mapping.
2. **Data Source & Repository Tests:**
   - `listWarehouses` GET request & 200 OK parsing.
   - `createWarehouse` POST request with `WarehouseCreate`.
   - `getWarehouse` GET request with UUID.
   - `updateWarehouse` PATCH request with `WarehouseUpdate`.
   - `deleteWarehouse` DELETE request & 204 No Content.
   - `getInventory` GET request & inventory list parsing.
   - `addInventory` POST request with `WarehouseInventoryAdd`.
   - `listSlots` GET request with warehouse ID.
   - `createSlot` POST request with `WarehouseSlotCreate`.
   - `updateSlot` PATCH request with `WarehouseSlotUpdate`.
   - `deleteSlot` DELETE request & 204 No Content.
   - Error mapping for 401, 403, 404, 422, 500.
3. **Controller Tests:**
   - Initial loading state and successful data population.
   - Reactive search filtering across warehouse name and address.
   - Selected warehouse and slot loading.
   - Warehouse create, update, and delete mutations.
   - Inventory intake mutation and load recalculation.
   - Slot creation and cancellation mutations.
   - 403 Forbidden handling for Manager role.
4. **Widget & Screen UI Tests:**
   - `WarehouseCard` renders name, address, active pill, and capacity progress bar.
   - Progress bar colors adapt to occupancy thresholds (<60%, 60-80%, >80%).
   - Admin view displays "+ Add Warehouse" and edit buttons.
   - Manager view hides "+ Add Warehouse" and edit buttons.
   - Tapping warehouse card opens `WarehouseDetailSheet`.
   - Form validation for warehouse creation, inventory intake, and slot scheduling.
5. **Responsive Layout Tests:**
   - 320x568 (iPhone SE / Ultra-compact)
   - 360x640 (Standard Android)
   - 412x860 (Modern Android)
   - 412x960 (Large Flagship)
   - Ensure 0 `RenderFlex` overflows.
6. **Full Regression Suite:**
   - Verify all 244 existing tests continue to pass.
   - Verify static analysis produces 0 issues (`flutter analyze`).
   - Verify Android APK builds cleanly (`flutter build apk --debug`).

---

## 18. Final Gate

```
=====================================================
M5 STEP 7 — CONTRACT AUDIT COMPLETE
GATE STATUS:
READY FOR IMPLEMENTATION
=====================================================
```
