# Milestone 5: Seed Inventory Backend Contract Blockers Report

**Task:** Seed Inventory Feature-Parity Implementation (M5 Correction Task)  
**Execution Phase:** Phase 0 (Precondition Verification) & Phase 1 (Stop Condition)  
**Date:** 2026-09-25  
**Authoritative Backend:** `https://agriflow-backend-t8o4.onrender.com`  
**OpenAPI Specification Inspected:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`  
**Final Status:** **BLOCKED — BACKEND CONTRACT NOT DEPLOYED**

---

## 1. Executive Summary

In accordance with **Phase 0 (Hard Precondition)**, the live deployed FastAPI backend specification at `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json` was fetched and rigorously audited before modifying any Dart production code.

### Result of Phase 0 Live Inspection:
The live backend **has NOT yet deployed the proposed Seed Inventory schema extensions, grade pricing models, or warehouse-assignment relationships**. 

Because the live backend does not yet support these capabilities, proceeding with Phase 2–8 would require fabricating API fields, mocking local data, or inventing endpoints—which is strictly forbidden by the project's golden rules and the Phase 1 Stop Condition.

Therefore, execution has **STOPPED** at Phase 1.  
No Dart production code was modified.  
The 226/226 passing test suite and clean static analysis remain completely intact and unregressed.

---

## 2. Live OpenAPI 3.1 Verification Evidence

The live OpenAPI specification was inspected programmatically directly from Render. The verbatim schemas for all relevant endpoints are documented below:

### 2.1 `SeedCreate` Schema (POST `/api/v1/seeds`)
```json
{
  "name": { "type": "string", "maxLength": 120, "minLength": 2, "title": "Name" },
  "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Variety" },
  "price_per_kg": {
    "anyOf": [
      { "type": "number", "exclusiveMinimum": 0 },
      { "type": "string", "pattern": "^(?!^[-+.]*$)[+-]?0*\\d*\\.?\\d*$" }
    ],
    "title": "Price Per Kg"
  },
  "stock_kg": {
    "anyOf": [
      { "type": "number", "minimum": 0 },
      { "type": "string", "pattern": "^(?!^[-+.]*$)[+-]?0*\\d*\\.?\\d*$" }
    ],
    "title": "Stock Kg"
  },
  "description": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Description" },
  "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Image Url" }
}
```
**Findings on `SeedCreate`:**
- ❌ **NO Grade Pricing Fields:** Does NOT accept `price_grade_a`, `price_grade_b`, `price_grade_c`, or `grade_prices`.
- ❌ **NO Warehouse Fields:** Does NOT accept `warehouse_id` or `warehouse_ids`.
- ❌ **NO Max Order Limit:** Does NOT accept `max_order_quantity_kg`.

---

### 2.2 `SeedUpdate` Schema (PATCH `/api/v1/seeds/{seed_id}`)
```json
{
  "price_per_kg": {
    "anyOf": [
      { "type": "number", "exclusiveMinimum": 0 },
      { "type": "string", "pattern": "^(?!^[-+.]*$)[+-]?0*\\d*\\.?\\d*$" },
      { "type": "null" }
    ],
    "title": "Price Per Kg"
  },
  "stock_kg": {
    "anyOf": [
      { "type": "number", "minimum": 0 },
      { "type": "string", "pattern": "^(?!^[-+.]*$)[+-]?0*\\d*\\.?\\d*$" },
      { "type": "null" }
    ],
    "title": "Stock Kg"
  },
  "description": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Description" },
  "is_active": { "anyOf": [{ "type": "boolean" }, { "type": "null" }], "title": "Is Active" }
}
```
**Findings on `SeedUpdate`:**
- ❌ **NO Grade Pricing Fields:** Cannot update grade-specific prices.
- ❌ **NO Warehouse Fields:** Cannot assign or modify warehouse associations.
- ❌ **NO Max Order Limit:** Cannot set or update order limits.
- ❌ **NO `image_url`:** `image_url` is present on `SeedCreate`, but **completely absent** from `SeedUpdate`! An Admin cannot change or replace an image on an existing seed.

---

### 2.3 `SeedPublic` Schema (GET `/api/v1/seeds` & GET `/api/v1/seeds/{seed_id}`)
```json
{
  "id": { "type": "string", "format": "uuid", "title": "Id" },
  "name": { "type": "string", "title": "Name" },
  "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Variety" },
  "price_per_kg": { "type": "string", "title": "Price Per Kg" },
  "stock_kg": { "type": "string", "title": "Stock Kg" },
  "description": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Description" },
  "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }], "title": "Image Url" },
  "is_active": { "type": "boolean", "title": "Is Active" }
}
```
**Findings on `SeedPublic`:**
- ❌ Only returns single base `price_per_kg`.
- ❌ Returns no grade prices.
- ❌ Returns no associated warehouse list or ID.
- ❌ Returns no order quantity caps.

---

### 2.4 `SeedOut` Schema (Farmer GET `/api/v1/farmer/seeds`)
```json
{
  "id": { "type": "string", "format": "uuid" },
  "name": { "type": "string" },
  "crop_type": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
  "variety": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
  "description": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
  "price_per_kg": { "type": "number" },
  "old_price": { "anyOf": [{ "type": "number" }, { "type": "null" }] },
  "stock_kg": { "type": "number" },
  "image_url": { "anyOf": [{ "type": "string" }, { "type": "null" }] },
  "warehouse_id": { "anyOf": [{ "type": "string", "format": "uuid" }, { "type": "null" }] }
}
```
**Findings on `SeedOut`:**
- Contains `warehouse_id` (single nullable UUID), but neither `SeedCreate` nor `SeedUpdate` allows Admin to assign it.
- Has single base `price_per_kg` only.

---

### 2.5 Seed Purchase Contracts (`SeedPurchaseIn` & `SeedPurchaseReceipt`)
- `POST /api/v1/farmer/seeds/purchase` accepts:
  - `seed_id`: UUID
  - `quantity_kg`: number
  - `grade`: `"A" | "B" | "C"` (default: `"A"`)
  - `warehouse_id`: UUID | null
  - `pickup_date`: date | null
- In PostgreSQL function `purchase_seeds`, calculation remains:
  ```sql
  v_total := v_seed.price_per_kg * p_quantity_kg;
  ```
  The backend database calculation ignores `p_grade` and computes the order total strictly using `price_per_kg`.

---

### 2.6 File Upload Endpoints (`/api/v1/uploads`)
- `POST /api/v1/uploads`:
  - `multipart/form-data` with `file: binary`, `bucket: string` (description: `documents | visits | seeds`).
  - Returns `DirectUploadResponse`: `{ object_path: string, public_url: string, size_bytes: integer, content_type: string }`.
- `POST /api/v1/uploads/presign`:
  - Request body `PresignUploadRequest`: `{ bucket: string, file_name: string, content_type: string, size_bytes: integer }`.
- **Finding:** While the generic upload endpoint exists, `SeedUpdate` does NOT accept `image_url`. Thus an Admin can upload an image during creation, but cannot update or replace it later via `PATCH /api/v1/seeds/{id}`.

---

## 3. Detailed Matrix of Backend Blockers

| Feature / Capability | Required Admin Action | Live Backend Status | Evidence | Action Under Phase 1 |
|---|---|---|---|:---:|
| **Grade A Price** | Input field in Add/Edit sheet | **NOT DEPLOYED** | Missing from `SeedCreate`, `SeedUpdate`, `SeedPublic` | **BLOCKED** |
| **Grade B Price** | Input field in Add/Edit sheet | **NOT DEPLOYED** | Missing from `SeedCreate`, `SeedUpdate`, `SeedPublic` | **BLOCKED** |
| **Grade C Price** | Input field in Add/Edit sheet | **NOT DEPLOYED** | Missing from `SeedCreate`, `SeedUpdate`, `SeedPublic` | **BLOCKED** |
| **Multi-Warehouse Assignment** | Checkbox list of storage locations | **NOT DEPLOYED** | No `warehouse_ids` array or relation endpoint | **BLOCKED** |
| **Single Warehouse Assignment** | Dropdown of primary warehouse | **NOT DEPLOYED** | `SeedCreate` & `SeedUpdate` lack `warehouse_id` | **BLOCKED** |
| **Max Order Quantity** | Input field for 50 kg / limit | **NOT DEPLOYED** | No `max_order_quantity_kg` in schemas | **BLOCKED** |
| **Update Existing Seed Image** | Change / remove image on edit | **NOT DEPLOYED** | `SeedUpdate` schema does not contain `image_url` | **BLOCKED** |
| **Grade-Aware Purchase Total** | Backend charges grade price | **NOT DEPLOYED** | PostgreSQL `purchase_seeds` uses base price only | **BLOCKED** |

---

## 4. Phase 1 Stop Condition Enforcement

As explicitly specified in the instruction:

> *If the LIVE backend does NOT yet support the required capability:*  
> *DO NOT invent an API.*  
> *DO NOT create fake local storage.*  
> *DO NOT create mock grade prices.*  
> *DO NOT hardcode warehouse IDs.*  
> *DO NOT pretend image upload works.*  
> *DO NOT modify production DTOs to fields that the backend does not accept.*  
> *Instead create docs/milestones/m5-seed-inventory-backend-contract-blockers.md and STOP.*

### Actions Taken:
1. **Zero Modifications to Production Code:** No Dart files in `lib/` or `test/` were touched.
2. **Zero Inventions:** No phantom fields (`price_grade_a`, `warehouse_ids`, etc.) were introduced into the Flutter models.
3. **Preserved Baseline:** The 226/226 passing unit and widget tests and `flutter analyze` 0 issues baseline remain 100% stable.
4. **Handoff Document Ready:** `docs/backend-requirements-admin-mobile.md` was created in the previous step and is awaiting implementation by Syed.

---

## 5. Final Gate Status

```
============================================================
SEED INVENTORY FEATURE-PARITY TASK
PHASE 0 & PHASE 1 EXECUTION COMPLETE
FINAL STATUS: BLOCKED — BACKEND CONTRACT NOT DEPLOYED
AWAITING DEPLOYMENT BY SYED BEFORE PROCEEDING
DO NOT PROCEED TO M5 STEP 7 IMPLEMENTATION AUTOMATICALLY
============================================================
```

### Recommendation:
Wait for Syed to implement and deploy the schema additions documented in [docs/backend-requirements-admin-mobile.md](file:///c:/Users/DELL/Downloads/Admin%20Mobile%20application%20build/docs/backend-requirements-admin-mobile.md) to Render. Once deployed and verified on `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`, proceed immediately with Phase 2 through Phase 18.
