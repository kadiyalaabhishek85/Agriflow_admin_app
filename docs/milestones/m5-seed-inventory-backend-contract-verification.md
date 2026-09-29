# Milestone 5: Seed Inventory Final Backend Contract Verification Report

**Author:** Antigravity Engineering (Flutter Mobile Lead)  
**Date:** 2026-09-25  
**Target Backend:** `https://agriflow-backend-t8o4.onrender.com`  
**OpenAPI Specification Inspected:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`  
**Deliverable File:** `docs/milestones/m5-seed-inventory-backend-contract-verification.md`  

---

## A. Executive Summary

This verification report serves as the **hard final gate** before any Flutter production code changes for the Seed Inventory Feature-Parity task.

Following reports of a green backend CI run and contract clarifications from the backend developer (Syed), a live, programmatic inspection of the authoritative deployed OpenAPI 3.1 specification on Render (`https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`) was executed.

### Core Finding:
The **live deployed production backend on Render has NOT yet deployed the proposed Seed Inventory schema extensions**.
Specifically:
1. **Grade-Specific Pricing:** `price_grade_a`, `price_grade_b`, and `price_grade_c` (or `grade_prices`) are **completely absent** from `SeedCreate`, `SeedUpdate`, and `SeedPublic`.
2. **Seed ↔ Warehouse Relationship:** The approved Admin UI mandates a **multi-warehouse checkbox list**, but `SeedCreate` and `SeedUpdate` have **no warehouse fields at all**, while the farmer-facing `SeedOut` only defines a single nullable `warehouse_id: uuid`.
3. **Max Order Quantity:** `max_order_quantity_kg` is **absent** from all seed schemas.
4. **Seed Image Update:** While `POST /api/v1/uploads` exists and `SeedCreate` accepts `image_url`, `SeedUpdate` (`PATCH /api/v1/seeds/{id}`) **does NOT accept `image_url`**, making it impossible to update or replace a seed image on an existing seed.

### Final Gate Status:
**BLOCKED — BACKEND NOT DEPLOYED**

---

## B. Live Backend Version & Deployment Evidence

- **OpenAPI Title:** AgriFlow Backend
- **OpenAPI Version:** `0.1.0`
- **OAS Specification:** `3.1.0`
- **Live Endpoint Queried:** `GET https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`
- **Timestamp of Audit:** `2026-09-25T12:28:30+05:30`

### Deployed Schemas Comparison:

| Schema Name | Expected Parity Fields | Actually Deployed Properties in Live OpenAPI | Deployment Status |
|---|---|---|:---:|
| **`SeedCreate`** | `name`, `variety`, `price_per_kg`, `price_grade_a`, `price_grade_b`, `price_grade_c`, `stock_kg`, `description`, `image_url`, `warehouse_ids`, `max_order_quantity_kg` | `name`, `variety`, `price_per_kg`, `stock_kg`, `description`, `image_url` | ❌ **NOT DEPLOYED** |
| **`SeedUpdate`** | `price_per_kg`, `price_grade_a`, `price_grade_b`, `price_grade_c`, `stock_kg`, `description`, `image_url`, `warehouse_ids`, `max_order_quantity_kg`, `is_active` | `price_per_kg`, `stock_kg`, `description`, `is_active` | ❌ **NOT DEPLOYED** |
| **`SeedPublic`** | Base price + grade prices + warehouse info + max order limit | `id`, `name`, `variety`, `price_per_kg`, `stock_kg`, `description`, `image_url`, `is_active` | ❌ **NOT DEPLOYED** |
| **`SeedOut`** | Base price + grade prices + warehouse array | `id`, `name`, `crop_type`, `variety`, `description`, `price_per_kg`, `old_price`, `stock_kg`, `image_url`, `warehouse_id` (single UUID) | ⚠️ **PARTIAL / MISMATCH** |

---

## C. Seed Image Contract

### 1. Live Upload Endpoints
The live backend provides two upload endpoints under the `uploads` tag:
- `POST /api/v1/uploads`: Accepts `multipart/form-data` with:
  - `file`: binary stream (`application/octet-stream`)
  - `bucket`: string (`documents | visits | seeds`, default: `documents`)
  - Returns `DirectUploadResponse`:
    ```json
    {
      "object_path": "string",
      "public_url": "string",
      "size_bytes": 1048576,
      "content_type": "image/jpeg"
    }
    ```
- `POST /api/v1/uploads/presign`: Accepts `PresignUploadRequest` (`bucket`, `file_name`, `content_type`, `size_bytes`).

### 2. Can Flutter Safely Implement Image Upload?
- **For Seed Creation (`POST /api/v1/seeds`):** **YES.** Flutter can upload an image to `POST /api/v1/uploads` with `bucket="seeds"`, receive `public_url`, and pass it as `image_url` to `SeedCreate`.
- **For Seed Edit / Update (`PATCH /api/v1/seeds/{seed_id}`):** **NO.** `SeedUpdate` strictly limits accepted properties to:
  `['price_per_kg', 'stock_kg', 'description', 'is_active']`
  `image_url` is **NOT supported** on `PATCH /api/v1/seeds/{seed_id}`. Any attempt to update an existing seed's image will either be ignored or cause HTTP 422 Unprocessable Entity if extra attributes are forbidden.

---

## D. Grade A / B / C Pricing Contract

### 1. Schema Analysis
- `price_per_kg`: Verified on `SeedCreate`, `SeedUpdate`, `SeedPublic`, and `SeedOut`.
- `price_grade_a`: **NOT FOUND** in live OpenAPI.
- `price_grade_b`: **NOT FOUND** in live OpenAPI.
- `price_grade_c`: **NOT FOUND** in live OpenAPI.
- `grade_prices`: **NOT FOUND** in live OpenAPI.

### 2. Purchase Calculation Authority
- Endpoint: `POST /api/v1/farmer/seeds/purchase`
- Request Schema: `SeedPurchaseIn` accepts `grade: GrainGrade` (`"A" | "B" | "C"`, default `"A"`).
- Database Calculation: The backend database function `purchase_seeds` executes:
  ```sql
  v_total := v_seed.price_per_kg * p_quantity_kg;
  ```
  The calculation is strictly `quantity * price_per_kg`. The backend does not charge grade-specific prices.
- **Rule Confirmation:** Flutter must **NOT** calculate the final purchase price as the business authority. The backend must be authoritative, and grade pricing is currently **not supported by the backend**.

---

## E. Maximum Order Quantity Contract

- `max_order_quantity_kg`: **NOT FOUND** in `SeedCreate`, `SeedUpdate`, or `SeedPublic`.
- `SeedPurchaseIn.quantity_kg`: Enforces `exclusiveMinimum: 0, maximum: 100000`.
- The 50 kg limit mentioned in the Farmer UI mockup is an unvalidated client-side helper text, not a backend-enforced business constraint.
- Admin configuration for max order limits cannot be implemented until the backend adds this field to `SeedCreate` and `SeedUpdate`.

---

## F. Seed ↔ Warehouse Relationship (Critical Gate)

### The Approved Admin UI Requirement:
The approved Admin UI design explicitly features a **multi-warehouse selection list with checkboxes**:
- ☑ Kurnool Storage Facility
- ☑ Nandyal Cold Storage
- ☐ Dhone Regional Depot
- ☑ Yemmiganur Warehouse

### Live Backend Reality:
1. **Admin Master Catalog Endpoints:**
   - `POST /api/v1/seeds` (`SeedCreate`): Contains **zero warehouse fields**.
   - `PATCH /api/v1/seeds/{id}` (`SeedUpdate`): Contains **zero warehouse fields**.
   - `GET /api/v1/seeds` (`SeedPublic`): Contains **zero warehouse fields**.
2. **Farmer Catalog Endpoint:**
   - `GET /api/v1/farmer/seeds` (`SeedOut`): Contains `warehouse_id: string (uuid) | null` (single UUID, not a list).
3. **Seed-Warehouse Mapping Endpoints:**
   - There are **no mapping endpoints** (such as `/api/v1/seeds/{id}/warehouses`).

### Critical Gate Statement:
> **"Backend contract does not currently support the approved multi-warehouse Admin UI."**

Neither multi-warehouse assignment nor single-warehouse assignment can currently be saved or managed through the Admin seeds API.

---

## G. Stock Semantics

### Determination:
**Seed stock is GLOBAL stock for the entire seed variety (Option A).**

- `SeedPublic.stock_kg`: Represents total available catalog stock for the seed product.
- `SeedOut.stock_kg`: Represents total catalog stock.
- The warehouse inventory endpoint (`/api/v1/warehouses/{id}/inventory`) tracks bulk harvested grain intakes (`grain_type`, `quantity_kg`), not packaged catalog seed varieties.
- Warehouse-specific seed inventory is **NOT supported** in the deployed backend.

---

## H. Farmer Parity Verification

Currently:
- The farmer selects `grade` (`A`, `B`, `C`), `warehouse_id`, and `pickup_date` at checkout (`SeedPurchaseIn`).
- However, Admin configuration does **NOT** affect these selections:
  - Admin cannot configure grade pricing (farmer is always charged base `price_per_kg`).
  - Admin cannot assign warehouses to seeds (farmer dropdown loads all active warehouses independently).
  - Admin cannot restrict max order limits.

---

## I. Admin vs. Manager RBAC

Verified against live backend permissions:

| Capability | Admin / Super Admin | Manager | Backend Authority |
|---|:---:|:---:|---|
| Create Seed (`POST /api/v1/seeds`) | ✅ Authorized | ❌ Forbidden (403) | `require_admin` dependency |
| Edit Seed (`PATCH /api/v1/seeds/{id}`) | ✅ Authorized | ❌ Forbidden (403) | `require_admin` dependency |
| Delete Seed (`DELETE /api/v1/seeds/{id}`) | ✅ Authorized | ❌ Forbidden (403) | `require_admin` dependency |
| Upload Image (`POST /api/v1/uploads`) | ✅ Authorized | ✅ Authorized | `get_current_user` (staff) |
| Configure Grade Pricing | 🚫 BLOCKED | 🚫 BLOCKED | *Backend schema missing* |
| Assign Warehouses to Seed | 🚫 BLOCKED | 🚫 BLOCKED | *Backend schema missing* |
| View Seed Catalog (`GET /api/v1/seeds`) | ✅ Authorized | ✅ Authorized | Staff read access |

---

## J. Endpoint & Schema Master Matrix

| Endpoint | Method | Request Schema | Response Schema | Live Deployment Status | Blocker Description |
|---|---|---|---|:---:|---|
| `/api/v1/uploads` | `POST` | `multipart/form-data` | `DirectUploadResponse` | ✅ **DEPLOYED** | Supported for initial creation |
| `/api/v1/seeds` | `GET` | *None* | `SuccessResponse[list[SeedPublic]]` | ✅ **DEPLOYED** | Lacks grade and warehouse fields |
| `/api/v1/seeds` | `POST` | `SeedCreate` | `SuccessResponse[SeedPublic]` | ⚠️ **PARTIAL** | Missing `price_grade_a/b/c`, `warehouse_ids`, `max_order_quantity_kg` |
| `/api/v1/seeds/{id}` | `PATCH` | `SeedUpdate` | `SuccessResponse[SeedPublic]` | ⚠️ **PARTIAL** | Missing grade prices, `image_url`, `warehouse_ids`, `max_order_quantity_kg` |
| `/api/v1/seeds/{id}` | `DELETE`| *None* | HTTP 204 | ✅ **DEPLOYED** | Verified working |
| `/api/v1/farmer/seeds/purchase` | `POST` | `SeedPurchaseIn` | `SeedPurchaseReceipt` | ⚠️ **PARTIAL** | Ignores grade in price calculation |

---

## K. React Alignment

In `agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx`:
- The React web UI had a multi-select for warehouses that targeted legacy Supabase direct relational joins (`seed_warehouses`), which were stripped out during the FastAPI REST rewrite.
- React does not have Grade A/B/C pricing.
- React calculates total as `quantity_kg * price_per_kg`.

---

## L. Approved HTML Alignment

In `AdminMobile UIUX.html`:
- The Add/Edit seed forms expose: Name, Variety, Base Price, Stock (Qtl), Description, Availability.
- Warehouse assignment and grade pricing were proposed to achieve parity with `Farmers UIUX.html`, but have no corresponding backend endpoints in the live service.

---

## M. Flutter Impact

1. **Existing Baseline Protected:**
   - 226/226 regression tests passing.
   - `flutter analyze`: 0 issues found.
   - 29/29 seeds inventory unit, repository, controller, and widget tests passing.
2. **Implementation Readiness:**
   - As long as the live FastAPI backend does not accept grade pricing, warehouse assignments, or `image_url` on update, modifying Dart DTOs and entities will cause HTTP 422 errors or silent data loss.

---

## N. Remaining Backend Gaps (For Syed)

Before Flutter implementation can commence, Syed must deploy to Render:
1. `SeedCreate` & `SeedUpdate` schema additions:
   - `price_grade_a` (float | null)
   - `price_grade_b` (float | null)
   - `price_grade_c` (float | null)
   - `warehouse_ids` (list[uuid] | null) OR explicitly clarify single `warehouse_id`
   - `max_order_quantity_kg` (float | null)
   - `image_url` (string | null) on `SeedUpdate`
2. Update `SeedPublic` and `SeedOut` to reflect these properties.
3. Update `purchase_seeds` SQL function to charge grade prices.

---

## O. Final Implementation Gate

```
============================================================
M5 SEED INVENTORY FINAL BACKEND CONTRACT VERIFICATION GATE
VERIFICATION COMPLETED: 2026-09-25T12:30:00Z
TARGET HOST: https://agriflow-backend-t8o4.onrender.com

FINAL STATUS:
BLOCKED — BACKEND NOT DEPLOYED

SUPPORTING REASONS:
1. Deployed SeedCreate & SeedUpdate lack grade pricing fields.
2. Deployed SeedCreate & SeedUpdate lack warehouse assignment fields.
3. Deployed SeedUpdate lacks image_url field.
4. Backend purchase function ignores crop grade in price calculation.
5. Backend contract does not currently support the approved
   multi-warehouse Admin UI.

ACTION:
STOPPING IMMEDIATELY.
NO FLUTTER PRODUCTION CODE HAS BEEN MODIFIED.
AWAITING DEPLOYMENT OF CONTRACT CHANGES TO RENDER BY SYED.
============================================================
```
