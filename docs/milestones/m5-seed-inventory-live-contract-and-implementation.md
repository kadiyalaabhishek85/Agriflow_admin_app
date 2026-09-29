# M5 — Seed Inventory: Live Backend Contract Verification & Gated Implementation Report

**Document ID:** `docs/milestones/m5-seed-inventory-live-contract-and-implementation.md`  
**Date:** September 25, 2026  
**Target Backend:** `https://agriflow-backend-t8o4.onrender.com`  
**Authoritative Schema Source:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json` (Live Deployed)  
**Evaluator:** Antigravity Mobile Engineering Agent  
**Final Gate Verdict:** `BLOCKED — WAREHOUSE CONTRACT MISMATCH`

---

## 1. Executive Summary & Gate Verdict

In accordance with strict project invariants:
1. The **LIVE deployed FastAPI OpenAPI specification** was retrieved directly from production (`https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`, size: 181,050 bytes) and inspected.
2. The deployed schemas were verified against the approved Admin/Manager visual requirements and the Farmer Seed Purchase flow.
3. **Significant progress was confirmed:** The backend developer (Syed) has successfully deployed `price_grade_a`, `price_grade_b`, `price_grade_c`, and `max_order_quantity_kg` across `SeedCreate`, `SeedUpdate`, `SeedPublic`, and `SeedOut`. Direct and presigned image uploads (`POST /api/v1/uploads`, `POST /api/v1/uploads/presign`) are also live with `bucket="seeds"`.
4. **Critical Gate Blocker Encountered:** The live backend deployed schema enforces a **strict 1:1 relationship between a Seed and a single Warehouse** (`warehouse_id: Optional[UUID]`).  
   The approved Admin visual and functional specification mandates **multi-warehouse distribution assignment** (e.g., assigning a single seed variety simultaneously to *Kurnool Storage Facility*, *Nandyal Cold Storage*, *Yemmiganur Warehouse* via multi-select checkboxes).
5. **Non-Negotiable Constraint Enforced:** The instructions strictly dictate:  
   > *"If only one warehouse is supported, DO NOT silently convert the approved Flutter multi-select UI into single-select. DO NOT silently redesign the approved requirement... Use EXACTLY ONE: BLOCKED — WAREHOUSE CONTRACT MISMATCH... STOP BEFORE FLUTTER IMPLEMENTATION."*

### Final Gate Classification:
```
============================================================
FINAL GATE: BLOCKED — WAREHOUSE CONTRACT MISMATCH
============================================================
```
Flutter production code has **NOT** been modified. The existing working implementation and 240/240 passing test suite remain completely intact.

---

## 2. Phase 0 — Repository Safety & Starting Baseline

- **Repository State:** Clean workspace. No uncommitted breaking changes.
- **Flutter Analyze Baseline:** `0 issues found!` (ran in 3.5s).
- **Existing Seed Inventory Test Suite:** `29/29 tests passed!` (`test/features/seeds_inventory/seeds_inventory_test.dart`).
- **Full Project Regression Test Suite:** `240/240 tests passed!` across all modules.
- **Android Debug APK Build:** Successfully assembled `build/app/outputs/flutter-apk/app-debug.apk` in 41.1s.

---

## 3. Phase 1 — Live Deployed Backend Contract Verification

### A. SeedCreate Schema (`#/components/schemas/SeedCreate`)
Verified live schema properties from production `openapi.json`:

```json
{
  "properties": {
    "name": { "type": "string", "maxLength": 120, "minLength": 2, "title": "Name" },
    "crop_type": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Crop Type" },
    "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Variety" },
    "price_per_kg": { "anyOf": [{ "type": "number", "exclusiveMinimum": 0 }, { "type": "string" }], "title": "Price Per Kg" },
    "price_grade_a": { "anyOf": [{ "type": "number", "exclusiveMinimum": 0 }, { "type": "string" }, { "type": "null" }], "title": "Price Grade A" },
    "price_grade_b": { "anyOf": [{ "type": "number", "exclusiveMinimum": 0 }, { "type": "string" }, { "type": "null" }], "title": "Price Grade B" },
    "price_grade_c": { "anyOf": [{ "type": "number", "exclusiveMinimum": 0 }, { "type": "string" }, { "type": "null" }], "title": "Price Grade C" },
    "max_order_quantity_kg": { "anyOf": [{ "type": "number", "exclusiveMinimum": 0 }, { "type": "string" }, { "type": "null" }], "title": "Max Order Quantity Kg" },
    "stock_kg": { "anyOf": [{ "type": "number", "minimum": 0 }, { "type": "string" }], "title": "Stock Kg" },
    "warehouse_id": { "anyOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }], "title": "Warehouse Id" },
    "description": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Description" },
    "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Image Url" }
  },
  "type": "object",
  "required": ["name", "price_per_kg", "stock_kg"],
  "title": "SeedCreate"
}
```

*Status:* Grade pricing (`price_grade_a/b/c`), `max_order_quantity_kg`, and `image_url` are deployed. However, warehouse assignment is limited to a single `warehouse_id: Optional[UUID]`. No `warehouse_ids` array exists.

---

### B. SeedUpdate Schema (`#/components/schemas/SeedUpdate`)
Verified live schema properties from production `openapi.json`:

```json
{
  "properties": {
    "name": { "anyOf": [{ "type": "string", "maxLength": 120, "minLength": 2 }, { "type": "null" }] },
    "crop_type": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "price_per_kg": { "anyOf": [{ "type": "number" }, { "type": "string" }, { "type": "null" }] },
    "price_grade_a": { "anyOf": [{ "type": "number" }, { "type": "string" }, { "type": "null" }] },
    "price_grade_b": { "anyOf": [{ "type": "number" }, { "type": "string" }, { "type": "null" }] },
    "price_grade_c": { "anyOf": [{ "type": "number" }, { "type": "string" }, { "type": "null" }] },
    "max_order_quantity_kg": { "anyOf": [{ "type": "number" }, { "type": "string" }, { "type": "null" }] },
    "stock_kg": { "anyOf": [{ "type": "number" }, { "type": "string" }, { "type": "null" }] },
    "warehouse_id": { "anyOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] },
    "description": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "is_active": { "anyOf": [{ "type": "boolean" }, { "type": "null" }] }
  },
  "type": "object",
  "title": "SeedUpdate"
}
```

*Status:* All fields are optional/nullable. Updates are supported for `price_grade_a/b/c`, `max_order_quantity_kg`, `image_url`, `warehouse_id`, and `is_active`.

---

### C. SeedPublic Schema (`#/components/schemas/SeedPublic`)
Verified live schema properties returned by `GET /api/v1/seeds` and `GET /api/v1/seeds/{id}`:

```json
{
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "crop_type": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "price_per_kg": { "type": "string" },
    "price_grade_a": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "price_grade_b": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "price_grade_c": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "max_order_quantity_kg": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "stock_kg": { "type": "string" },
    "warehouse_id": { "anyOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] },
    "description": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "is_active": { "type": "boolean" }
  },
  "required": ["id", "name", "price_per_kg", "stock_kg", "is_active"],
  "title": "SeedPublic"
}
```

---

### D. Farmer SeedOut Schema (`#/components/schemas/SeedOut`)
Verified live schema returned by `GET /api/v1/farmer/seeds`:

```json
{
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "crop_type": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "description": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "price_per_kg": { "type": "number" },
    "price_grade_a": { "anyOf": [{ "type": "number" }, { "type": "null" }] },
    "price_grade_b": { "anyOf": [{ "type": "number" }, { "type": "null" }] },
    "price_grade_c": { "anyOf": [{ "type": "number" }, { "type": "null" }] },
    "max_order_quantity_kg": { "anyOf": [{ "type": "number" }, { "type": "null" }] },
    "old_price": { "anyOf": [{ "type": "number" }, { "type": "null" }] },
    "stock_kg": { "type": "number" },
    "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
    "warehouse_id": { "anyOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] }
  },
  "required": [
    "id", "name", "crop_type", "variety", "description",
    "price_per_kg", "old_price", "stock_kg", "image_url", "warehouse_id"
  ],
  "title": "SeedOut"
}
```

*Finding:* Farmer seed catalog strictly receives a single `warehouse_id`.

---

### E. Seed Purchase Contract (`POST /api/v1/farmer/seeds/purchase`)
Verified payload schema `SeedPurchaseIn`:
- `seed_id`: UUID (required)
- `quantity_kg`: number / string (required, max 100,000)
- `grade`: optional (`GrainGrade` / string)
- `warehouse_id`: optional UUID
- `pickup_date`: optional date string
- `payment_method`: string, default "warehouse"

Verified response schema `SeedPurchaseReceipt`:
- Returns `order_id`, `invoice_number`, `seed_name`, `quantity_kg`, `grade`, `warehouse_id`, `warehouse_name`, `pickup_date`, `price_per_kg`, `total_amount`, `payment_status`, `payment_status_label`.

---

### F. Seed Image Upload Contracts
1. `POST /api/v1/uploads`:
   - Accepts multipart form: `file` (binary), `bucket` (string, supports `"seeds"`).
   - Returns `DirectUploadResponse`: `public_url`, `object_path`, `size_bytes`, `content_type`.
2. `POST /api/v1/uploads/presign`:
   - Accepts JSON `PresignUploadRequest`: `bucket` (`"seeds"`), `file_name`, `content_type`, `size_bytes`.
   - Returns `PresignUploadResponse`: `upload_url`, `object_path`, `expires_in`, `method: "PUT"`.
3. `PATCH /api/v1/seeds/{seed_id}`:
   - Accepts `{"image_url": "https://..."}` in `SeedUpdate`.

---

### G. Max Order Quantity Enforcement
- `max_order_quantity_kg` is present in `SeedCreate`, `SeedUpdate`, `SeedPublic`, and `SeedOut`.
- Default behavior: optional numeric/string value. When null, unlimited or fallback threshold applies.

---

### H. Warehouse Relationship Analysis (The Blocker)

| Dimension | Approved Admin UI Requirement | Deployed Production Backend (`live_openapi.json`) | Status |
|---|---|---|---|
| **Cardinality** | **1 Seed : Many Warehouses** | **1 Seed : 1 Warehouse** | **MISMATCH** |
| **Creation Field** | `warehouse_ids: List[UUID]` | `warehouse_id: Optional[UUID]` | **MISMATCH** |
| **Update Field** | `warehouse_ids: List[UUID]` | `warehouse_id: Optional[UUID]` | **MISMATCH** |
| **Public Representation** | `warehouses: List[WarehouseBrief]` | `warehouse_id: Optional[UUID]` | **MISMATCH** |
| **Farmer Catalog View** | List of available pickup hubs | Single `warehouse_id` | **MISMATCH** |
| **Stock Semantics** | Global catalog stock across hubs | Global catalog stock linked to at most 1 warehouse | Incomplete distribution model |

---

### I. Live RBAC Verification

| Endpoint | Method | Admin / Super Admin | Manager |
|---|---|---|---|
| `/api/v1/seeds` | `GET` | Authorized (Full Catalog) | Authorized (Full Catalog) |
| `/api/v1/seeds` | `POST` | Authorized (Create Seed) | **403 Forbidden (Read-Only)** |
| `/api/v1/seeds/{id}` | `PATCH` | Authorized (Update Seed) | **403 Forbidden (Read-Only)** |
| `/api/v1/seeds/{id}` | `DELETE` | Authorized (Delete Seed) | **403 Forbidden (Read-Only)** |

---

## 4. Phase 1 Gate Result

```
============================================================
PHASE 1 GATE CLASSIFICATION:
BLOCKED — WAREHOUSE CONTRACT MISMATCH
============================================================
```

### Exact Missing Contracts & Discrepancies:
1. **Endpoint/Schema:** `POST /api/v1/seeds` (`SeedCreate`), `PATCH /api/v1/seeds/{id}` (`SeedUpdate`), `GET /api/v1/seeds` (`SeedPublic`), `GET /api/v1/farmer/seeds` (`SeedOut`).
2. **Expected Contract:** Support for multiple warehouse assignments per seed product (`warehouse_ids: List[UUID]` or junction sub-resource `POST /api/v1/seeds/{seed_id}/warehouses`).
3. **Actual Deployed Contract:** Single foreign key `warehouse_id: Optional[UUID]`.
4. **Impact on Frontend:** The approved Admin Mobile design explicitly features a multi-select warehouse checklist (Kurnool Storage Facility, Nandyal Cold Storage, Dhone Regional Depot, Yemmiganur Warehouse). Implementing this against a single `warehouse_id` column would require either silently dropping multi-select down to a single-select dropdown (violating approved UX) or faking client-side relations (violating backend authority).
5. **Required Backend Resolution by Syed:**
   - Either add a junction table `seed_warehouses (seed_id, warehouse_id)` and expose `warehouse_ids: List[UUID]` in `SeedCreate`, `SeedUpdate`, and `warehouses: List[WarehouseBrief]` in `SeedPublic`/`SeedOut`.
   - OR provide written confirmation that Seed distribution is officially restricted to 1 Warehouse per Seed product, authorizing a formal UX redesign.

---

## 5. Current Implementation State

- **Flutter Code Modified in This Task:** None.
- **Existing Seeds Inventory Working State:** Completely functional on verified base schema (`name`, `variety`, `price_per_kg`, `stock_kg`, `description`, `is_active`).
- **Regression Test Suite:** 240/240 tests passing (100%).
- **Analyzer Status:** 0 issues found.
- **Android APK Build:** Clean debug APK build succeeded.

**STOPPED.** In strict compliance with instructions, execution halts at Phase 1 Gate until the warehouse relationship contract mismatch is resolved by the backend team.
