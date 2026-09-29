# AgriFlow — Backend Endpoints & Contract Requirements for Admin Mobile Application

**Author:** Antigravity Engineering / Admin Mobile Team  
**Recipient:** Syed (Backend Developer / Database Owner)  
**Date:** 2026-09-25  
**Version:** 1.0.0  
**Context:** Live OpenAPI 3.1 (`https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`) vs. Admin Mobile Flutter Implementation

---

## 1. Executive Summary & Context

The AgriFlow Admin/Manager Mobile Flutter application has successfully reached **Milestone 5 (Step 6 verified with 226/226 regression tests passing)**. 

During our recent feature audits—specifically the **Seed Inventory Feature-Parity Audit** (comparing Admin seed management to Farmer seed checkout) and the **Warehouse Management Audit (Step 7)**—we identified critical capabilities present in the UI/UX flows and mobile operational workflows that currently **lack corresponding backend endpoints or schema properties** in the live FastAPI service.

### Primary Goals for the Backend Developer (Syed):
1. **Bridge the Seed Feature-Parity Gap:** Enable Admins to configure Crop Grade A/B/C pricing and warehouse dispatch assignments so that the Farmer checkout flow has genuine backend backing.
2. **Complete Warehouse CRUD & Inventory Inspection:** Enable Admins to edit/delete warehouses and inspect the specific grain breakdown stored in each warehouse.
3. **Enhance Farmer & Staff Administration:** Allow editing farmer profiles, managing manager assignments, and downloading report exports.

This document outlines **exactly what is already supported**, **what is missing**, and the **exact proposed HTTP methods, URL paths, request/response schemas, and database changes** needed to unblock the Admin Mobile application.

---

## 2. Present Backend Snapshot (What Currently Exists)

Based on the live OpenAPI specification (`/api/v1/openapi.json` at Render), the backend currently exposes:

| Tag / Domain | Current Working Endpoints |
|---|---|
| **`auth` / `users`** | `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /users/me`, `PATCH /users/me`, `POST /auth/send-otp`, `POST /auth/verify-otp`, `POST /auth/forgot-password/send-otp`, `POST /auth/forgot-password/reset` |
| **`admin`** | `GET /admin/dashboard`, `GET /admin/reports/monthly`, `GET /admin/audit-logs` |
| **`managers`** | `GET /managers`, `POST /managers`, `PATCH /managers/{manager_id}/status`, `POST /managers/{manager_id}/reset-password` |
| **`farmers`** | `GET /farmers`, `POST /farmers`, `PATCH /farmers/{farmer_id}/approval`, `GET /farmers/{farmer_id}`, `GET /farmers/bank-change-requests`, `PATCH /farmers/bank-change-requests/{request_id}` |
| **`seeds`** | `GET /seeds`, `POST /seeds`, `PATCH /seeds/{seed_id}`, `DELETE /seeds/{seed_id}` |
| **`seed-purchases`**| `POST /seed-purchases`, `GET /seed-purchases`, `PATCH /seed-purchases/{purchase_id}/status` |
| **`warehouses`** | `GET /warehouses`, `POST /warehouses`, `POST /warehouses/{warehouse_id}/inventory`, `GET /warehouses/{warehouse_id}/slots`, `GET /warehouse-slots`, `POST /warehouse-slots`, `PATCH /warehouse-slots/{slot_id}` |
| **`crops` / `farm-visits`** | `GET /crops`, `POST /crops`, `GET /crops/active`, `GET /farm-visits`, `POST /farm-visits`, `PATCH /farm-visits/{id}/schedule`, `PATCH /farm-visits/{id}/complete`, `POST /farm-visits/reminders` |
| **`bookings` / `grain-sales`** | `GET /bookings`, `POST /bookings`, `PATCH /bookings/{id}/status`, `POST /bookings/{id}/inspect`, `GET /grain-sales`, `POST /grain-sales`, `PATCH /grain-sales/{id}/review`, `PATCH /grain-sales/{id}/pay`, `POST /grain-sales/procure`, `PATCH /grain-sales/{id}/yield` |
| **`market-rates` / `txns`** | `GET /market-rates`, `POST /market-rates`, `GET /transactions`, `PATCH /transactions/{id}/pay` |
| **`farmer · *`** | Farmer-specific endpoints for profile, dashboard, seed catalog/purchase, crops, warehouses, bookings, offers, notifications. |

---

## 3. Required Endpoints & Schema Modifications

Below is the categorized breakdown of what the backend needs to add or update.

---

### Priority 0: Seed Inventory & Farmer Parity Gap (CRITICAL)

#### The Problem:
- **Farmer App Checkout:** Farmer selects a seed, chooses **Crop Grade** (`A`, `B`, `C`), selects a **Warehouse** for pickup, selects a **Pickup Date**, and has an order limit ("Max: 50 Kg").
- **Backend Seed Catalog:** `SeedCreate`, `SeedUpdate`, and `SeedPublic` only have `price_per_kg` (single global price). There are **no grade pricing fields**, **no warehouse assignment fields**, and **no max order limit fields**.
- **Backend Calculation:** PostgreSQL function `purchase_seeds` currently computes `v_total := v_seed.price_per_kg * p_quantity_kg;`, ignoring the selected grade entirely.

#### Required Changes:

#### 1. Update Existing Endpoints: `POST /api/v1/seeds` & `PATCH /api/v1/seeds/{seed_id}`
Extend the request bodies (`SeedCreate` and `SeedUpdate`) and response schema (`SeedPublic`):

```json
// PROPOSED EXTENSION FOR SeedCreate & SeedUpdate
{
  "name": "Hybrid Wheat 404",
  "variety": "Wheat",
  "price_per_kg": 75.0,
  
  // --- NEW FIELDS REQUIRED ---
  "price_grade_a": 85.0,        // float | null -> Price for Grade A (Premium)
  "price_grade_b": 75.0,        // float | null -> Price for Grade B (Standard)
  "price_grade_c": 65.0,        // float | null -> Price for Grade C (Economy)
  "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6", // UUID | null -> Primary dispatch warehouse
  "max_order_quantity_kg": 50.0 // float | null -> Maximum order quantity per farmer order
}
```

#### 2. Update Response Schema: `SeedPublic` (`GET /api/v1/seeds` & `GET /api/v1/seeds/{seed_id}`)
Ensure `SeedPublic` and `SeedOut` return these fields:
```json
// PROPOSED SeedPublic Response
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "Hybrid Wheat 404",
  "variety": "Wheat",
  "price_per_kg": 75.0,
  "price_grade_a": 85.0,
  "price_grade_b": 75.0,
  "price_grade_c": 65.0,
  "stock_kg": 15000.0,
  "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "warehouse_name": "Central Warehouse A — Hyderabad",
  "max_order_quantity_kg": 50.0,
  "description": "High yield hybrid wheat seeds",
  "image_url": null,
  "is_active": true,
  "created_at": "2026-09-25T10:00:00Z",
  "updated_at": "2026-09-25T10:00:00Z"
}
```

#### 3. Update Farmer Purchase Pricing Logic (`POST /api/v1/farmer/seeds/purchase` / `purchase_seeds` SQL)
- When a farmer purchases with `grade = "A"`, compute:
  $$\text{unit\_price} = \text{seed.price\_grade\_a} \parallel \text{seed.price\_per\_kg}$$
- Validate that `quantity_kg <= seed.max_order_quantity_kg` (if `max_order_quantity_kg` is set).

---

### Priority 0: Warehouse Management CRUD & Inventory Breakdown (Step 7)

#### The Problem:
- Admins can create warehouses (`POST /api/v1/warehouses`) and view aggregate lists (`GET /api/v1/warehouses`), but:
  - Cannot edit an existing warehouse (e.g. fix typo in address, change total capacity).
  - Cannot delete/deactivate a warehouse.
  - Cannot fetch single warehouse details under `/api/v1/warehouses/{id}` (it only exists under the farmer route `/api/v1/farmer/warehouses/{id}`).
  - Cannot view what grains are stored in the warehouse! (Only `POST .../inventory` exists to add grain, but no `GET` exists to view it).
  - Cannot hard-delete an unused warehouse slot.

#### Required New Endpoints:

#### 1. `GET /api/v1/warehouses/{warehouse_id}`
- **Method:** `GET`
- **Path:** `/api/v1/warehouses/{warehouse_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`, `MANAGER`
- **Description:** Get complete details of a single warehouse for the Admin/Manager detail view.
- **Response Schema:** `SuccessResponse[WarehouseDetailPublic]`
```json
{
  "success": true,
  "data": {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "name": "Central Warehouse A",
    "address": "Plot 12, Industrial Area, Hyderabad",
    "total_capacity_kg": 500000.0,
    "current_load_kg": 320000.0,
    "is_active": true,
    "created_at": "2026-09-20T08:00:00Z",
    "updated_at": "2026-09-25T08:00:00Z"
  }
}
```

#### 2. `PATCH /api/v1/warehouses/{warehouse_id}`
- **Method:** `PATCH`
- **Path:** `/api/v1/warehouses/{warehouse_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN` (Managers blocked)
- **Description:** Update warehouse name, address, capacity, or active status.
- **Request Schema:** `WarehouseUpdate`
```json
{
  "name": "Central Warehouse A — Prime",
  "address": "Plot 12-14, Industrial Area, Hyderabad",
  "total_capacity_kg": 600000.0,
  "is_active": true
}
```
- **Response Schema:** `SuccessResponse[WarehousePublic]`

#### 3. `DELETE /api/v1/warehouses/{warehouse_id}`
- **Method:** `DELETE`
- **Path:** `/api/v1/warehouses/{warehouse_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`
- **Description:** Soft-delete (`is_active = false`) or hard-delete a warehouse if no stock or active bookings exist.
- **Response:** HTTP 204 No Content

#### 4. `GET /api/v1/warehouses/{warehouse_id}/inventory`
- **Method:** `GET`
- **Path:** `/api/v1/warehouses/{warehouse_id}/inventory`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`, `MANAGER`
- **Description:** List the grain inventory breakdown stored in this warehouse.
- **Response Schema:** `SuccessResponse[list[WarehouseGrainStockPublic]]`
```json
{
  "success": true,
  "data": [
    {
      "id": "1fa85f64-5717-4562-b3fc-2c963f66af01",
      "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "grain_type": "Wheat",
      "quantity_kg": 180000.0,
      "updated_at": "2026-09-24T14:30:00Z"
    },
    {
      "id": "2fa85f64-5717-4562-b3fc-2c963f66af02",
      "warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "grain_type": "Paddy",
      "quantity_kg": 140000.0,
      "updated_at": "2026-09-25T09:15:00Z"
    }
  ]
}
```

#### 5. `DELETE /api/v1/warehouse-slots/{slot_id}`
- **Method:** `DELETE`
- **Path:** `/api/v1/warehouse-slots/{slot_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`, `MANAGER`
- **Description:** Delete an unbooked/cancelled slot.
- **Response:** HTTP 204 No Content

---

### Priority 1: Farmer Profile Management & Historical Sub-resources

#### The Problem:
- Admins/Managers can register farmers (`POST /api/v1/farmers`) and set approval status (`PATCH /api/v1/farmers/{id}/approval`), but:
  - There is no endpoint to edit a farmer's profile (name, phone, acreage, address) when details were entered incorrectly.
  - There is no delete endpoint for spam/test accounts.
  - `FarmerAdminView` only returns static profile fields. The detail sheet in the mobile app cannot display the farmer's associated crops, grain sales, or purchases.

#### Required New Endpoints:

#### 1. `PATCH /api/v1/farmers/{farmer_id}`
- **Method:** `PATCH`
- **Path:** `/api/v1/farmers/{farmer_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`, `MANAGER`
- **Description:** Edit farmer basic profile information.
- **Request Schema:** `FarmerProfileUpdateRequest`
```json
{
  "name": "Ramesh Patel",
  "phone": "9876543210",
  "acres_of_land": 12.5,
  "village": "Rampur",
  "address": "Near Panchayat Office, Rampur",
  "district": "Kurnool",
  "state": "Andhra Pradesh",
  "pincode": "518001"
}
```
- **Response Schema:** `SuccessResponse[FarmerAdminView]`

#### 2. `DELETE /api/v1/farmers/{farmer_id}`
- **Method:** `DELETE`
- **Path:** `/api/v1/farmers/{farmer_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`
- **Description:** Delete or archive a farmer account.
- **Response:** HTTP 204 No Content

#### 3. `GET /api/v1/farmers/{farmer_id}/activity` (or sub-routes)
- **Method:** `GET`
- **Path:** `/api/v1/farmers/{farmer_id}/activity`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`, `MANAGER`
- **Description:** Summary of transactions and active resources for this farmer.
- **Response Schema:**
```json
{
  "success": true,
  "data": {
    "total_crops_registered": 3,
    "total_grain_sold_qtl": 45.0,
    "total_seeds_purchased_kg": 100.0,
    "total_earnings_inr": 125000.0,
    "recent_crops": [
      { "id": "uuid", "crop_name": "Wheat", "status": "verified", "season": "Rabi" }
    ],
    "recent_sales": [
      { "id": "uuid", "grain_type": "Wheat", "grade": "A", "total_amount": 75000.0, "status": "paid" }
    ]
  }
}
```

---

### Priority 1: Manager & Staff Administration

#### The Problem:
- Current endpoints: `GET /managers`, `POST /managers`, `PATCH /managers/{id}/status`, `POST /managers/{id}/reset-password`.
- Admin cannot update a manager's contact details, assigned region, or assigned warehouse.
- Admin cannot delete a manager.

#### Required New Endpoints:

#### 1. `PATCH /api/v1/managers/{manager_id}`
- **Method:** `PATCH`
- **Path:** `/api/v1/managers/{manager_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`
- **Request Schema:** `ManagerUpdateRequest`
```json
{
  "name": "Suresh Sharma",
  "phone": "9876501234",
  "region": "Rayalaseema",
  "department": "Procurement & Storage",
  "assigned_warehouse_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```
- **Response Schema:** `SuccessResponse[ManagerPublic]`

#### 2. `DELETE /api/v1/managers/{manager_id}`
- **Method:** `DELETE`
- **Path:** `/api/v1/managers/{manager_id}`
- **RBAC:** `ADMIN`, `SUPER_ADMIN`
- **Response:** HTTP 204 No Content

---

### Priority 2: Reports, Documents & System Maintenance

#### 1. Monthly Report Export Endpoint: `GET /api/v1/admin/reports/monthly/export`
- **Method:** `GET`
- **Path:** `/api/v1/admin/reports/monthly/export`
- **Query Params:** `month` (e.g. `2026-09`), `format` (`pdf` | `csv`, default `pdf`)
- **RBAC:** `ADMIN`, `SUPER_ADMIN`
- **Description:** Generates and streams a downloadable monthly performance report.
- **Response:** Binary stream with `Content-Type: application/pdf` or `text/csv`.

#### 2. System Cache Control Endpoints (For `ICacheRepository`):
- `GET /api/v1/admin/cache/stats`: Returns key counts, memory usage, hit rates.
- `POST /api/v1/admin/cache/clear`: Accepts `{ "keys": ["seeds_*"], "all": false }` to purge cached entries.

---

## 4. Master OpenAPI Delta Table (Required Backend Changes)

| # | HTTP Method | Endpoint Path | Tag | Request Body | Response Schema | Required RBAC | Priority |
|---|---|---|---|---|---|---|:---:|
| 1 | `PATCH` & `POST` | `/api/v1/seeds` & `.../{seed_id}` | `seeds` | Add `price_grade_a/b/c`, `warehouse_id`, `max_order_quantity_kg` | `SeedPublic` (extended) | `ADMIN`, `SUPER_ADMIN` | **P0** |
| 2 | `POST` | `/api/v1/farmer/seeds/purchase` | `farmer · seeds` | Same (`SeedPurchaseIn`) | Update SQL pricing calculation | `FARMER` | **P0** |
| 3 | `GET` | `/api/v1/warehouses/{warehouse_id}` | `warehouses` | *None* | `WarehouseDetailPublic` | `ADMIN`, `MANAGER` | **P0** |
| 4 | `PATCH` | `/api/v1/warehouses/{warehouse_id}` | `warehouses` | `WarehouseUpdate` | `WarehousePublic` | `ADMIN`, `SUPER_ADMIN` | **P0** |
| 5 | `DELETE` | `/api/v1/warehouses/{warehouse_id}` | `warehouses` | *None* | HTTP 204 | `ADMIN`, `SUPER_ADMIN` | **P0** |
| 6 | `GET` | `/api/v1/warehouses/{warehouse_id}/inventory` | `warehouses` | *None* | `list[WarehouseGrainStockPublic]` | `ADMIN`, `MANAGER` | **P0** |
| 7 | `DELETE` | `/api/v1/warehouse-slots/{slot_id}` | `warehouses` | *None* | HTTP 204 | `ADMIN`, `MANAGER` | **P0** |
| 8 | `PATCH` | `/api/v1/farmers/{farmer_id}` | `farmers` | `FarmerProfileUpdateRequest` | `FarmerAdminView` | `ADMIN`, `MANAGER` | **P1** |
| 9 | `DELETE` | `/api/v1/farmers/{farmer_id}` | `farmers` | *None* | HTTP 204 | `ADMIN`, `SUPER_ADMIN` | **P1** |
| 10 | `GET` | `/api/v1/farmers/{farmer_id}/activity` | `farmers` | *None* | `FarmerActivitySummary` | `ADMIN`, `MANAGER` | **P1** |
| 11 | `PATCH` | `/api/v1/managers/{manager_id}` | `managers` | `ManagerUpdateRequest` | `ManagerPublic` | `ADMIN`, `SUPER_ADMIN` | **P1** |
| 12 | `DELETE` | `/api/v1/managers/{manager_id}` | `managers` | *None* | HTTP 204 | `ADMIN`, `SUPER_ADMIN` | **P1** |
| 13 | `GET` | `/api/v1/admin/reports/monthly/export` | `admin` | Query: `month`, `format` | File Stream (`pdf`/`csv`) | `ADMIN`, `SUPER_ADMIN` | **P2** |
| 14 | `POST` | `/api/v1/admin/cache/clear` | `admin` | `{ "keys"?: list[str], "all"?: bool }` | `SuccessResponse[dict]` | `SUPER_ADMIN` | **P2** |

---

## 5. Database Schema & Migration Guidance

To implement the above endpoints in PostgreSQL / Supabase, the following database adjustments are proposed:

### 1. `seeds` Table Additions:
```sql
ALTER TABLE seeds
  ADD COLUMN IF NOT EXISTS price_grade_a NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS price_grade_b NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS price_grade_c NUMERIC(10, 2),
  ADD COLUMN IF NOT EXISTS warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS max_order_quantity_kg NUMERIC(10, 2) DEFAULT 50.0;
```

### 2. Update `purchase_seeds` SQL Function:
```sql
CREATE OR REPLACE FUNCTION purchase_seeds(
    p_farmer_id UUID,
    p_seed_id UUID,
    p_quantity_kg NUMERIC,
    p_grade TEXT DEFAULT 'A',
    p_warehouse_id UUID DEFAULT NULL,
    p_pickup_date DATE DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_seed RECORD;
    v_unit_price NUMERIC;
    v_total NUMERIC;
    v_order_id UUID;
BEGIN
    SELECT * INTO v_seed FROM seeds WHERE id = p_seed_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Seed not found';
    END IF;

    -- Validate stock
    IF v_seed.stock_kg < p_quantity_kg THEN
        RAISE EXCEPTION 'Insufficient stock';
    END IF;

    -- Validate max order quantity
    IF v_seed.max_order_quantity_kg IS NOT NULL AND p_quantity_kg > v_seed.max_order_quantity_kg THEN
        RAISE EXCEPTION 'Quantity exceeds max limit of % kg', v_seed.max_order_quantity_kg;
    END IF;

    -- Pick grade-specific price with fallback to base price
    IF p_grade = 'A' AND v_seed.price_grade_a IS NOT NULL THEN
        v_unit_price := v_seed.price_grade_a;
    ELSIF p_grade = 'B' AND v_seed.price_grade_b IS NOT NULL THEN
        v_unit_price := v_seed.price_grade_b;
    ELSIF p_grade = 'C' AND v_seed.price_grade_c IS NOT NULL THEN
        v_unit_price := v_seed.price_grade_c;
    ELSE
        v_unit_price := v_seed.price_per_kg;
    END IF;

    v_total := v_unit_price * p_quantity_kg;

    -- Deduct stock
    UPDATE seeds SET stock_kg = stock_kg - p_quantity_kg WHERE id = p_seed_id;

    -- Insert seed purchase record
    INSERT INTO seed_purchases (
        farmer_id, seed_id, quantity_kg, grade, warehouse_id, pickup_date,
        price_per_kg, total_amount, payment_status, status
    ) VALUES (
        p_farmer_id, p_seed_id, p_quantity_kg, p_grade, p_warehouse_id, p_pickup_date,
        v_unit_price, v_total, 'pending', 'pending'
    ) RETURNING id INTO v_order_id;

    RETURN jsonb_build_object(
        'order_id', v_order_id,
        'unit_price', v_unit_price,
        'total_amount', v_total
    );
END;
$$ LANGUAGE plpgsql;
```

### 3. `managers` Table Addition:
```sql
ALTER TABLE managers
  ADD COLUMN IF NOT EXISTS assigned_warehouse_id UUID REFERENCES warehouses(id) ON DELETE SET NULL;
```

---

## 6. Role-Based Access Control (RBAC) Invariants

The backend must enforce the following permission boundaries across roles:

| Domain / Operation | Super Admin | Admin | Manager | Farmer |
|---|:---:|:---:|:---:|:---:|
| **Create/Edit/Delete Seeds & Grade Prices** | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** |
| **Purchase Seeds** | Optional | Optional | Optional | Allowed |
| **Create/Edit/Delete Warehouses** | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** |
| **View Warehouse Slots & Load** | Allowed | Allowed | Allowed | Limited |
| **Create/Cancel Warehouse Slots** | Allowed | Allowed | Allowed | **FORBIDDEN (403)** |
| **Approve / Reject Farmers** | Allowed | Allowed | Allowed | **FORBIDDEN (403)** |
| **Edit Farmer Profile** | Allowed | Allowed | Allowed | Profile self-update only |
| **Delete Farmer Account** | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** |
| **Manage Managers & Passwords** | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** |
| **Export Monthly Reports** | Allowed | Allowed | **FORBIDDEN (403)** | **FORBIDDEN (403)** |

---

## 7. Next Steps & Coordination

1. **For Syed (Backend Team):**
   - Review the schemas and database adjustments above.
   - Deploy Priority 0 (Seed Grade Pricing and Warehouse CRUD) to the Render backend service (`agriflow-backend-t8o4.onrender.com`).
   - Notify the mobile team when `/api/v1/openapi.json` is updated.
2. **For Admin Mobile Team:**
   - Continue adhering to strict gate controls: zero code changes will be made to mobile entities until endpoints are deployed by Syed.
   - Upon deployment, update mobile DTOs, entities, and tests to bind to the newly available backend contracts.
