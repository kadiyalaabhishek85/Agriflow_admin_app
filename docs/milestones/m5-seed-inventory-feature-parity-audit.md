# Milestone 5: Seed Inventory & Seed Purchase Feature-Parity Contract Audit

**Document Status:** Complete Feature-Parity & Contract Gap Audit  
**Author:** Antigravity Agent  
**Date:** 2026-09-25  
**Workspace:** `c:\Users\DELL\Downloads\Admin Mobile application build`  

---

## 1. Executive Summary

A critical feature-parity evaluation was conducted between the **Admin / Manager Seed Inventory** module (`lib/features/seeds_inventory/`) and the **Farmer Seed Purchase** flow (`Farmers UIUX.html`, `SeedPurchase.jsx`, and backend contracts `/api/v1/farmer/seeds/purchase`).

### Key Findings:
1. **The Discrepancy:**
   - The Admin currently configures: `Seed Name`, `Variety / Crop Type`, `Base Price / kg`, `Stock (kg/Qtl)`, `Description`, and `Catalog Availability (Active/Inactive)`.
   - The Farmer purchase experience (observed in the Farmer screenshot, `Farmers UIUX.html`, and the OpenAPI schema `SeedPurchaseIn`) additionally requires:
     - **Crop Grade Selection:** Options `A` (Premium), `B` (Standard), and `C` (Economy).
     - **Grade-Dependent Pricing Behavior:** Farmer expectation that grade selection influences pricing or that grade pricing is managed by the business.
     - **Preferred Pickup Date:** Date picker for collecting purchased seeds.
     - **Warehouse Selection:** Dropdown selecting the physical warehouse storage point for pickup/dispatch.
     - **Quantity Constraints:** Order quantities with min/max validation (e.g. 50 kg max note in UI; 100,000 kg max backend schema validation).
     - **Purchase Total:** Real-time computation of `quantity * unit_price`.
2. **Authoritative Backend State (`openapi_dump.json`):**
   - The backend **DOES** accept `grade` (`GrainGrade: "A" | "B" | "C"`), `warehouse_id`, and `pickup_date` on the farmer purchase submission endpoint (`POST /api/v1/farmer/seeds/purchase`).
   - The backend **DOES NOT** support grade-specific pricing on the seed catalog (`SeedPublic`, `SeedCreate`, `SeedUpdate`). The backend schema has only one single pricing field: `price_per_kg`.
   - The backend **DOES NOT** allow Admin to associate or assign warehouses on seed creation/update (`SeedCreate` and `SeedUpdate` schemas completely lack `warehouse_id` or `warehouse_ids`).
3. **Core Conclusion & Classification:**
   - **Grade-Specific Pricing:** **BACKEND GAP** — Backend API required — to be supplied by Syed.
   - **Seed-to-Warehouse Admin Assignment:** **BACKEND GAP** — Backend API required — to be supplied by Syed.
   - **Farmer Purchase Attributes (`grade`, `warehouse_id`, `pickup_date`):** Currently supported as **transaction-time inputs** chosen by the farmer at checkout, rather than Admin-configured seed catalog properties.

---

## 2. Screenshot Findings

Based on the three reference screenshots provided:

| Screenshot | Context | Visible Fields & Controls | Parity Analysis |
|---|---|---|---|
| **1. Admin — Edit Seed Product** | Modal bottom sheet editing an existing seed | • Seed Name (Disabled / Read-only)<br>• Variety / Crop Type (Disabled / Read-only)<br>• Price per kg (Editable, ₹)<br>• Stock in Quintals (Editable, Qtl)<br>• Description (Editable textarea)<br>• Catalog Availability (Active toggle)<br>• Save & Cancel buttons | Exactly matches `SeedUpdate` backend contract. Completely lacks Grade A/B/C pricing fields, warehouse location assignment, and max order limit. |
| **2. Admin — Add New Seed Variety** | Modal bottom sheet creating a new seed catalog entry | • Seed Name (Text input)<br>• Variety / Crop Type (Text input)<br>• Price per kg (Text input, ₹)<br>• Stock in Quintals (Text input, Qtl)<br>• Description (Text input)<br>• Catalog Availability (Active toggle)<br>• Create Seed button | Exactly matches `SeedCreate` backend contract. Does not allow setting grade-specific price tiers, assigning a warehouse, or setting quantity caps. |
| **3. Farmer — Purchase Seed** | Purchase checkout sheet for farmer ordering seeds | • Seed title & Base Price per Kg readout<br>• Quantity Selector with `−` / `+` steppers (default 1, max 50 kg helper note)<br>• **Crop Grade *:** Segmented radio selector for `A` (Premium), `B` (Standard), `C` (Economy)<br>• **Preferred Pickup Date *:** Native date picker field<br>• **Warehouse *:** Dropdown menu with storage locations (e.g. `ABC — Kurnool`, `Central Warehouse A — Hyderabad`)<br>• **Estimated Total:** Real-time price breakdown<br>• Confirm Order CTA button | Exposes 4 dimensions (`Grade`, `Pickup Date`, `Warehouse`, `Max Qty Note`) that Admin currently has zero controls to configure or oversee on the seed model. |

---

## 3. Farmer Flutter Implementation Trace (Source 1)

A rigorous search across the filesystem confirms that **no separate standalone "Farmer Flutter" repository or Dart files exist on the host system**.  
The farmer-facing seed purchase logic is embodied in:
1. **The approved Farmer UI/UX prototype:** `agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html`.
2. **The React web farmer implementation:** `agriflow/agriflow-web/src/pages/farmer/SeedPurchase.jsx`.
3. **The FastAPI backend farmer endpoint definitions:** `/api/v1/farmer/seeds` and `/api/v1/farmer/seeds/purchase`.

### Detailed Attribute Trace from Farmer Sources:

| Field | Source File | Class / Element | Data Type | Origin / Source | Endpoint / Storage | Request / Response Role |
|---|---|---|---|---|---|---|
| `seed_id` | `Farmers UIUX.html` / `SeedPurchaseIn` | `SeedPurchaseIn.seed_id` | UUID string | Selected from catalog | `/api/v1/farmer/seeds/purchase` | Request body (Required) |
| `quantity_kg` | `Farmers UIUX.html` / `SeedPurchaseIn` | `#purchase-qty` / `SeedPurchaseIn` | Number (Float) | Stepper input | `/api/v1/farmer/seeds/purchase` | Request body (`exclusiveMinimum: 0`, `maximum: 100000`) |
| `grade` | `Farmers UIUX.html` / `SeedPurchaseIn` | `input[name="crop-grade"]` | Enum (`"A"`, `"B"`, `"C"`) | Radio button group (A: Premium, B: Standard, C: Economy) | `/api/v1/farmer/seeds/purchase` | Request body (`GrainGrade`, default: `"A"`) |
| `warehouse_id` | `Farmers UIUX.html` / `SeedPurchaseIn` | `#purchase-warehouse` / `SeedPurchaseIn` | UUID string | Dropdown loaded from warehouses | `GET /api/v1/warehouses` → `POST /api/v1/farmer/seeds/purchase` | Request body (Optional in schema, required in HTML UI) |
| `pickup_date` | `Farmers UIUX.html` / `SeedPurchaseIn` | `#purchase-date` / `SeedPurchaseIn` | Date string (`YYYY-MM-DD`) | Native HTML5 date input | `/api/v1/farmer/seeds/purchase` | Request body (Optional in schema, required in HTML UI) |
| `payment_method` | `Farmers UIUX.html` / `SeedPurchaseIn` | Fixed constant | String | Hardcoded to `"warehouse"` | `/api/v1/farmer/seeds/purchase` | Request body (Default: `"warehouse"`) |
| `price_per_kg` | `Farmers UIUX.html` / `SeedOut` | `SeedOut.price_per_kg` | Decimal / Float | Derived from selected seed | `GET /api/v1/farmer/seeds/{id}` | Response field; used in client total calculation |
| `total_amount` | `Farmers UIUX.html` / `SeedPurchaseReceipt` | `#purchase-total` | Decimal / Float | Computed on client: `quantity_kg * price_per_kg` | Returned in `SeedPurchaseReceipt` | Response field verified by backend |

---

## 4. Admin Flutter Implementation Trace (Source 2)

Existing Admin Seed Inventory implementation resides in `lib/features/seeds_inventory/`:

- **Domain Entity:** `SeedInventoryItem` ([seed_inventory_item.dart](file:///c:/Users/DELL/Downloads/Admin%20Mobile%20application%20build/lib/features/seeds_inventory/domain/entities/seed_inventory_item.dart)):
  - Fields: `id`, `name`, `variety`, `pricePerKg`, `stockKg`, `description`, `imageUrl`, `isActive`.
  - Computed: `stockQtl`, `isLowStock` (< 500 kg), `displayPrice`, `displayStockKg`, `displayStockQtl`.
- **Remote Data Source:** `FastApiSeedsInventoryRemoteDataSource` ([fast_api_seeds_inventory_remote_data_source.dart](file:///c:/Users/DELL/Downloads/Admin%20Mobile%20application%20build/lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart)):
  - Endpoints: `GET /api/v1/seeds`, `POST /api/v1/seeds`, `PATCH /api/v1/seeds/{id}`, `DELETE /api/v1/seeds/{id}`.
- **Presentation Intake:** `AddEditSeedSheet` ([add_edit_seed_sheet.dart](file:///c:/Users/DELL/Downloads/Admin%20Mobile%20application%20build/lib/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart)):
  - Renders: Seed Name, Variety, Price/Kg, Stock (Qtl), Description, Active switch.
  - Immutability: Name and Variety are locked to read-only during edit.

### Gap in Admin Flutter:
1. **Zero Grade Fields:** No grade selection, no Grade A / Grade B / Grade C price inputs.
2. **Zero Warehouse Association:** No warehouse picker or multi-warehouse inventory breakdown.
3. **Zero Quantity Constraints:** No maximum purchase order limit per farmer.

---

## 5. React Implementation Trace (Source 4)

### 5.1 Admin Web (`agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx`)
- State managed: `name`, `variety`, `price_per_kg`, `stock_kg`, `description`, `is_active`.
- Contains a UI select for warehouses (`warehouse_ids`), but it maps to Supabase relation tables that were discarded in the FastAPI REST migration.
- Does **NOT** contain any crop grade fields, grade pricing, or order limits.

### 5.2 Farmer Web (`agriflow/agriflow-web/src/pages/farmer/SeedPurchase.jsx`)
- Loads seeds via `farmerService.getSeeds()` (`GET /api/v1/farmer/seeds`).
- Loads warehouses via `farmerService.getWarehouses()` (`GET /api/v1/warehouses`).
- Purchase modal allows entering `quantity_kg`, choosing `warehouse_id`, and choosing `pickup_date`.
- **Crucial Finding:** The React Farmer web code does **NOT** contain Crop Grade selection (A/B/C). Crop Grade was introduced in `Farmers UIUX.html` and codified in the backend schema `SeedPurchaseIn`.
- **Price Calculation:** `total_amount = quantity_kg * selectedSeed.price_per_kg`. Price does **not** change based on grade.

---

## 6. Approved HTML Trace (Source 5)

### 6.1 `AdminMobile UIUX.html` (`#screen-seeds-inventory`)
- Displays: Seed name, variety, Price/Kg, Stock in Qtl, Active/Inactive status pill, Low-stock warning pill.
- Admin Actions: Quick Edit button (opens edit modal), Delete button.
- Add Seed Modal: Inputs for Name, Variety, Price, Stock, Description, Status.
- **Result:** No grade configuration or warehouse assignment exists in the Admin HTML.

### 6.2 `Farmers UIUX.html` (`#modal-purchase`)
- Displays:
  - Header: Seed Name and `₹<price>/Kg`.
  - Stepper: `−` and `+` buttons around quantity input, with label `Max: 50 Kg per order`.
  - **Crop Grade Selector:** 3 radio boxes:
    - Box A: `A` / `Premium`
    - Box B: `B` / `Standard`
    - Box C: `C` / `Economy`
  - **Preferred Pickup Date:** `<input type="date" id="purchase-date" />`.
  - **Warehouse:** `<select id="purchase-warehouse">` with options `ABC — Kurnool`, `Central Warehouse A — Hyderabad`, `DHANIYA — Nasha Colony`, `Help — Afsrt`.
  - **Total:** `<span id="purchase-total">₹X,XXX.00</span>`.
- **Script Analysis (`setupSeedPurchase`):**
  - `updateTotal()` calculates: `total = qty * window._currentPrice`.
  - `updateGradeUI()` **only toggles CSS borders and background colors** of the boxes. It **does NOT** change `window._currentPrice`.
  - `btnConfirm.onclick` checks that `crop-grade` is checked (`if (!grade) { alert(...); return; }`).

---

## 7. Backend / OpenAPI Contract Audit (Source 3)

Audited directly against `openapi_dump.json`:

### 7.1 Seed Master Catalog Endpoints (Admin / Central)

| Endpoint | Method | Request Schema | Response Schema | Grade Support | Warehouse Support |
|---|---|---|---|:---:|:---:|
| `/api/v1/seeds` | `GET` | None | `SuccessResponse[list[SeedPublic]]` | **NO** | **NO** |
| `/api/v1/seeds` | `POST` | `SeedCreate` | `SuccessResponse[SeedPublic]` | **NO** | **NO** |
| `/api/v1/seeds/{seed_id}` | `PATCH` | `SeedUpdate` | `SuccessResponse[SeedPublic]` | **NO** | **NO** |
| `/api/v1/seeds/{seed_id}` | `DELETE` | None | HTTP 204 | **NO** | **NO** |

#### `SeedCreate` Properties:
- `name` (string, 2-120 chars) — required
- `variety` (string | null) — optional
- `price_per_kg` (number | string > 0) — required
- `stock_kg` (number | string >= 0) — required
- `description` (string | null) — optional
- `image_url` (string | null) — optional

#### `SeedUpdate` Properties:
- `price_per_kg` (number | string | null)
- `stock_kg` (number | string | null)
- `description` (string | null)
- `is_active` (boolean | null)

### 7.2 Farmer Seed Catalog & Purchase Endpoints

| Endpoint | Method | Request Schema | Response Schema | Grade Support | Warehouse Support |
|---|---|---|---|:---:|:---:|
| `/api/v1/farmer/seeds` | `GET` | Query: `q`, `crop_type`, `min_price`, `max_price`, `warehouse_id`, `in_stock_only` | `SuccessResponse[list[SeedOut]]` | **NO** | **YES** (Query param & `SeedOut.warehouse_id`) |
| `/api/v1/farmer/seeds/{seed_id}` | `GET` | Path: `seed_id` | `SuccessResponse[SeedOut]` | **NO** | **YES** (`SeedOut.warehouse_id`) |
| `/api/v1/farmer/seeds/purchase` | `POST` | `SeedPurchaseIn` | `SuccessResponse[SeedPurchaseReceipt]` | **YES** (`GrainGrade: A, B, C`) | **YES** (`warehouse_id`) |
| `/api/v1/farmer/seeds/purchases` | `GET` | Pagination params | `PaginatedResponse[SeedPurchaseOut]` | **YES** (`grade` in output) | **YES** (`warehouse_id` in output) |

#### `SeedPurchaseIn` Properties:
- `seed_id` (UUID) — required
- `quantity_kg` (number > 0, max 100,000) — required
- **`grade`** (`GrainGrade`: `"A"`, `"B"`, `"C"`, default `"A"`) — optional/defaulted
- **`warehouse_id`** (UUID | null) — optional
- **`pickup_date`** (date string `YYYY-MM-DD` | null) — optional
- `payment_method` (string, default `"warehouse"`) — optional

#### `SeedPurchaseReceipt` Properties:
- `order_id` (UUID), `invoice_number` (string), `seed_name` (string), `quantity_kg` (number)
- **`grade`** (string | null)
- **`warehouse_id`** (UUID | null), **`warehouse_name`** (string | null)
- **`pickup_date`** (date string | null)
- `price_per_kg` (number), `total_amount` (number)
- `payment_status`, `payment_status_label`

---

## 8. Crop Grade Audit

1. **Is Crop Grade a supported backend concept?**
   - **Yes, for purchases:** `GrainGrade` is a formal OpenAPI enum (`"A"`, `"B"`, `"C"`). It is accepted in `SeedPurchaseIn` and returned in `SeedPurchaseReceipt` and `SeedPurchaseOut`.
   - **No, for seed catalog items:** The seed catalog entities (`SeedCreate`, `SeedUpdate`, `SeedPublic`, `SeedOut`) contain **NO** grade attribute, grade list, or grade toggle.
2. **Where does Grade come from?**
   - In the database and business logic, `GrainGrade` was originally designed for **Grain Procurement / Grain Sales** (`grain_sales.grade`), where harvested grain brought in by farmers is graded A, B, or C upon inspection.
   - For seed purchases, `Farmers UIUX.html` added a grade selector (`Premium`, `Standard`, `Economy`) as a customer-facing preference, which the backend `SeedPurchaseIn` accommodates via `grade: GrainGrade = "A"`.
3. **Can Admin configure grades per seed?**
   - **No.** The FastAPI backend has no endpoint or schema for defining which grades apply to a seed or configuring different grades for different seeds.

---

## 9. Grade Pricing Audit

### Authoritative Determination:
The current AgriFlow backend uses **ONE global base price per seed (`price_per_kg`)**.

### Evidence:
1. `SeedPublic.price_per_kg` is a single decimal string.
2. `SeedCreate` and `SeedUpdate` only have `price_per_kg`.
3. `SeedOut.price_per_kg` is a single number.
4. In `Farmers UIUX.html`, `updateTotal()` computes `qty * price_per_kg` regardless of whether Grade A, B, or C is selected.
5. In PostgreSQL migration `20260720152500_update_purchase_seeds_function.sql`:
   ```sql
   v_total := v_seed.price_per_kg * p_quantity_kg;
   INSERT INTO seed_purchases (..., price_per_kg, total_amount, ...)
   VALUES (..., v_seed.price_per_kg, v_total, ...);
   ```
   The backend function computes total purely from `v_seed.price_per_kg * p_quantity_kg`.

### Contract Gap:
If the intended product behavior is:
$$\text{Selected Seed} + \text{Selected Crop Grade} + \text{Configured Grade Price} + \text{Quantity} = \text{Correct Purchase Total}$$
Then:
- **FastAPI backend currently DOES NOT support grade-specific pricing.**
- **Database `seeds` table currently DOES NOT have grade pricing columns (`price_grade_a`, `price_grade_b`, `price_grade_c`).**
- **Status:** **Backend API required — to be supplied by Syed.**

---

## 10. Warehouse Audit

1. **How does Warehouse Selection work in the Farmer flow?**
   - At checkout time, the farmer chooses a pickup location from the list of active warehouses (`GET /api/v1/warehouses` or `GET /api/v1/farmer/warehouses`).
   - The selected `warehouse_id` is submitted in `SeedPurchaseIn.warehouse_id`.
   - The backend validates the warehouse and populates `warehouse_name` on the purchase receipt.
2. **Is Stock warehouse-specific on the Seed model?**
   - **No.** `SeedPublic.stock_kg` is a single aggregate number across the entire company catalog.
   - In `openapi_dump.json`, `SeedOut` contains `warehouse_id: uuid | null`, and `GET /api/v1/farmer/seeds` accepts a `warehouse_id` query filter.
   - However, `SeedCreate` and `SeedUpdate` **DO NOT** contain `warehouse_id`.
   - Therefore, the Admin **cannot** assign or configure warehouses for seeds through the current Admin seeds endpoints (`/api/v1/seeds`).
3. **Can Admin configure warehouse assignment on seeds?**
   - **No.** The Admin seed endpoints have no `warehouse_id` field.
   - Separate warehouse storage tracking exists under `/api/v1/warehouses/{id}/inventory`, but that tracks raw grains (`grain_type`, `quantity_kg`), not catalog seed products.

---

## 11. Quantity / Pickup-Date Audit

1. **Quantity Constraints:**
   - **Farmer UI:** Mentions "Max: 50 Kg per order" in the helper text.
   - **Backend Schema (`SeedPurchaseIn`):** Enforces `quantity_kg > 0` and `quantity_kg <= 100000`.
   - **Admin Configuration:** There is no field on the seed model (`max_order_quantity_kg`) allowing Admin to set per-seed order limits.
2. **Preferred Pickup Date:**
   - Handled exclusively as a checkout transaction attribute selected by the farmer.
   - Sent in `SeedPurchaseIn.pickup_date` (`YYYY-MM-DD`).
   - Recorded on `seed_purchases.pickup_date`.
   - Does not require seed-level catalog configuration by Admin.

---

## 12. Feature Parity Matrix

| Feature | Farmer App | Admin App | React Web | HTML Spec | Backend Support | Required Admin Action | Parity Status |
|---|---|---|---|---|---|---|---|
| **Seed Name** | Displayed | Configured (Create only) | Configured | Displayed | Verified (`SeedCreate`, `SeedPublic`) | None (working) | **SUPPORTED** |
| **Variety** | Displayed | Configured (Create only) | Configured | Displayed | Verified (`SeedCreate`, `SeedPublic`) | None (working) | **SUPPORTED** |
| **Description** | Displayed | Configured (Create & Edit) | Configured | Displayed | Verified (`SeedCreate`, `SeedUpdate`) | None (working) | **SUPPORTED** |
| **Base Price / kg** | Displayed | Configured (Create & Edit) | Configured | Displayed | Verified (`price_per_kg`) | None (working) | **SUPPORTED** |
| **Catalog Active Status** | Filters catalog | Toggled (Create & Edit) | Toggled | Displayed | Verified (`is_active`) | None (working) | **SUPPORTED** |
| **Stock (Kg / Qtl)** | Availability check | Configured (Create & Edit) | Configured | Displayed | Verified (`stock_kg`) | None (working) | **SUPPORTED** |
| **Crop Grade (A/B/C)** | Selected at purchase | None | Not in React | Radio group in HTML | Verified in `SeedPurchaseIn` | None on Seed model | **NOT ADMIN SEED CONFIGURATION** |
| **Grade-Specific Pricing** | Expected in UI | None | None | None (uses base price) | **NO** (`price_per_kg` only) | Backend API required — to be supplied by Syed | **BACKEND GAP** |
| **Warehouse Picker** | Selected at purchase | None | None in REST | Dropdown in HTML | Verified in `SeedPurchaseIn` | None on Seed model | **NOT ADMIN SEED CONFIGURATION** |
| **Seed Warehouse Assignment** | Filtered in query | None | UI only (dead) | None in Admin | Partial (`SeedOut` has it, `SeedCreate` lacks it) | Backend API required — to be supplied by Syed | **BACKEND GAP** |
| **Order Quantity Max Limit** | 50 kg UI note | None | None | Helper text | Schema cap: 100,000 kg | None unless backend adds `max_order_limit` | **BACKEND GAP** |
| **Preferred Pickup Date** | Selected at purchase | None | Selected | Date input in HTML | Verified in `SeedPurchaseIn` | None (Transaction attribute) | **NOT ADMIN SEED CONFIGURATION** |
| **Purchase Total Calculation** | `qty * price` | Reviewed on order | `qty * price` | `qty * price` | Verified (`total_amount`) | None (working) | **SUPPORTED** |
| **Out-of-Stock Handling** | Blocks purchase | Low-stock pill (<500kg)| Blocks | Low-stock pill | Verified (`stock_kg < qty`) | None (working) | **SUPPORTED** |

---

## 13. Admin vs. Manager Permission Matrix

| Operation | Admin / Super Admin | Manager | Backend Authority |
|---|:---:|:---:|---|
| **View Seed Catalog & Pricing** | YES | YES | `GET /api/v1/seeds` |
| **Search & Filter Seeds** | YES | YES | Client-side filter |
| **Create New Seed Variety** | YES | **NO** | `POST /api/v1/seeds` |
| **Edit Price per kg** | YES | **NO** | `PATCH /api/v1/seeds/{id}` |
| **Edit Stock Quantity** | YES | **NO** | `PATCH /api/v1/seeds/{id}` |
| **Edit Description & Active Status** | YES | **NO** | `PATCH /api/v1/seeds/{id}` |
| **Delete Seed** | YES | **NO** | `DELETE /api/v1/seeds/{id}` |
| **Configure Grade Pricing** | **BLOCKED** | **NO** | *Backend contract missing* |
| **Assign Seed Warehouse** | **BLOCKED** | **NO** | *Backend contract missing* |
| **View Farmer Seed Purchases** | YES | YES | `GET /api/v1/seed-purchases` |
| **Approve / Reject Seed Purchase** | YES | YES | `PATCH /api/v1/seed-purchases/{id}/status` |

---

## 14. Backend Gaps Summary

The following required capabilities are **NOT supported** by the current FastAPI backend:

1. **Grade-Specific Pricing:**
   - **Problem:** `SeedCreate`, `SeedUpdate`, and `SeedPublic` only contain a single `price_per_kg`. There is no mechanism to set differential pricing for Grade A, Grade B, and Grade C.
   - **Status:** **Backend API required — to be supplied by Syed.**
2. **Seed-to-Warehouse Association in Admin:**
   - **Problem:** `SeedCreate` and `SeedUpdate` do not accept `warehouse_id` or `warehouse_ids`. Even though `SeedOut` has a `warehouse_id` field and `GET /api/v1/farmer/seeds` accepts a `warehouse_id` query parameter, an Admin has no way to assign a warehouse when creating or updating a seed.
   - **Status:** **Backend API required — to be supplied by Syed.**
3. **Per-Seed Maximum Order Quantity:**
   - **Problem:** No `max_order_quantity_kg` field exists on the seed catalog schemas. The 50 kg limit in the Farmer UI is hardcoded.
   - **Status:** **Backend API required — to be supplied by Syed.**

---

## 15. Required API Contracts (ONLY Where Actually Missing)

> [!WARNING]
> **PROPOSED — NOT CURRENTLY VERIFIED IN BACKEND**  
> Do NOT implement these until formally confirmed and deployed to the FastAPI backend by Syed.

### 15.1 Proposed Grade Pricing Schema Additions

To support grade-specific pricing on the seed catalog:

```json
// PROPOSED — NOT CURRENTLY VERIFIED IN BACKEND
// PATCH /api/v1/seeds/{seed_id}
{
  "price_per_kg": 75.0,
  "grade_prices": {
    "A": 85.0,
    "B": 75.0,
    "C": 65.0
  }
}
```

Or flat fields on `SeedCreate` / `SeedUpdate` / `SeedPublic`:
```json
// PROPOSED — NOT CURRENTLY VERIFIED IN BACKEND
{
  "price_per_kg": 75.0,
  "price_grade_a": 85.0,
  "price_grade_b": 75.0,
  "price_grade_c": 65.0
}
```

### 15.2 Proposed Warehouse Assignment Schema Additions

To allow Admins to associate seeds with warehouses:

```json
// PROPOSED — NOT CURRENTLY VERIFIED IN BACKEND
// POST /api/v1/seeds & PATCH /api/v1/seeds/{seed_id}
{
  "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

---

## 16. Recommended Admin UI/UX

Once backend contracts are supplied by Syed:

1. **Crop Grade Pricing Section in `AddEditSeedSheet`:**
   - If grade pricing is enabled, render an optional accordion or sub-section:
     - `Grade A (Premium) Price / Kg` (defaults to base price if empty).
     - `Grade B (Standard) Price / Kg` (defaults to base price).
     - `Grade C (Economy) Price / Kg` (defaults to base price).
2. **Warehouse Assignment Dropdown in `AddEditSeedSheet`:**
   - Dropdown querying `GET /api/v1/warehouses` allowing Admin to assign the primary dispatch warehouse.
3. **Current State UI Preservation:**
   - Until Syed supplies the backend endpoints, **do NOT add non-functional input fields** to `AddEditSeedSheet`. Non-persisting fields lead to user confusion, silent data loss, and contract regression.

---

## 17. Exact Flutter Files / Modules Likely Requiring Changes (When Approved)

When backend contracts are supplied:
1. `lib/features/seeds_inventory/domain/entities/seed_inventory_item.dart`: Add `gradePrices` (or `priceGradeA`, `priceGradeB`, `priceGradeC`) and `warehouseId`.
2. `lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart`: Update `toCreateJson()` and `toUpdateJson()`.
3. `lib/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart`: Add inputs for grade pricing and warehouse dropdown.
4. `lib/features/seeds_inventory/presentation/widgets/seed_inventory_card.dart`: Display assigned warehouse and grade price range.
5. `test/features/seeds_inventory/seeds_inventory_test.dart`: Update entity, data source, and widget test suites.

---

## 18. Test Requirements for Feature Parity

Once backend contracts are updated:
- Test parsing of grade pricing from JSON.
- Test fallback to base `price_per_kg` when grade prices are null.
- Test conversion of grade prices (₹/kg).
- Test payload serialization in `toCreateJson()` and `toUpdateJson()`.
- Test warehouse dropdown integration in the intake modal.
- Test form validation ensuring grade prices are positive numbers.

---

## 19. Risks & Governance Invariants

1. **Risk of API Desynchronization:** If Flutter adds grade pricing fields before the FastAPI backend updates `SeedCreate` and `SeedUpdate`, requests will fail with HTTP 422 `Unprocessable Entity` (extra fields forbidden if Pydantic `extra = "forbid"` is set).
2. **Risk of Data Loss:** If Flutter accepts grade pricing in the UI but the backend silently discards it, Admins will believe they configured grade pricing when the database did not save it.
3. **Database Integrity:** In PostgreSQL, the `purchase_seeds` function calculates `v_total := v_seed.price_per_kg * p_quantity_kg`. Changing pricing to be grade-aware requires updating the backend SQL function and FastAPI router.
4. **Preservation of Milestone 5 Step 6:** The baseline of 226 passing tests and clean static analysis must remain inviolate.

---

## 20. Final Gate Recommendation

```
=====================================================
M5 SEED INVENTORY FEATURE-PARITY AUDIT
AUDIT COMPLETE
STATUS: BLOCKED — BACKEND CONTRACT REQUIRED
AWAITING HUMAN / BACKEND OWNER APPROVAL
=====================================================
```

### Recommendation Summary:
1. **Do NOT implement grade pricing or warehouse assignment in Admin Flutter yet.**
2. The current Admin Seed Inventory implementation is **100% faithful and compliant** with the live FastAPI backend contracts (`SeedPublic`, `SeedCreate`, `SeedUpdate`).
3. The farmer-facing fields (`Crop Grade`, `Warehouse`, `Pickup Date`) currently function as **checkout-time transaction attributes** rather than seed-catalog attributes.
4. If business requirements mandate that Admins must configure grade prices and warehouse assignments on seeds, the request must be routed to **Syed (Backend Owner)** to update:
   - `SeedCreate` schema
   - `SeedUpdate` schema
   - `SeedPublic` schema
   - `seeds` database table and migrations
   - `purchase_seeds` SQL calculation function
