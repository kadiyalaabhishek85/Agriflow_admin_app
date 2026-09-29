# Backend Requirements: Seed Delete Persistence & Catalog Inactive Filtering

## 1. Overview & Context

- **Backend Lead:** Syed
- **Modules Affected:** Seeds Catalog, Farmer Seeds Catalog, Admin Seed Inventory
- **Date:** 2026-09-28

---

## 2. Identified Contract & Data Invariant Issue

### Issue Summary:
1. `DELETE /api/v1/seeds/{seed_id}` performs a soft-delete (sets `is_active = false` or removes record where no FK exists).
2. `GET /api/v1/seeds` returns `list[SeedPublic]` containing all records (both `is_active: true` and `is_active: false`), which is appropriate for Admin auditing.
3. However, `GET /api/v1/public/seeds` and `GET /api/v1/farmer/seeds` must guarantee that **only active seeds (`is_active = true`)** are served to public/farmer clients.
4. When a seed is deleted/deactivated by an Admin, it must immediately be excluded from all Farmer-facing catalog lists and purchase eligibility checks.

---

## 3. Detailed Endpoint Breakdown

### Endpoint 1: `DELETE /api/v1/seeds/{seed_id}`
- **Method:** `DELETE`
- **Current Response:** `204 No Content`
- **Database Action Required:**
  - If the seed has associated historical records in `seed_purchases`, update `seeds.is_active = false` and remove warehouse mappings if appropriate.
  - If no historical records exist, hard delete from `seeds` and `seed_warehouses`.
- **Expected DB State Post-Call:** The seed record has `is_active = false` or is deleted.

### Endpoint 2: `GET /api/v1/public/seeds`
- **Method:** `GET`
- **Expected Behavior:** Query MUST include `WHERE is_active = true`.
- **Actual Concern:** If `is_active = false` records are returned, farmers see discontinued/deleted products.
- **Backend Correction Required:**
  ```sql
  SELECT * FROM seeds WHERE is_active = true ORDER BY name ASC;
  ```

### Endpoint 3: `GET /api/v1/farmer/seeds`
- **Method:** `GET`
- **Expected Behavior:** Query MUST include `WHERE is_active = true`.
- **Backend Correction Required:** Ensure query builder enforces `is_active = true` regardless of search query `q` or `crop_type`.

### Endpoint 4: `POST /api/v1/farmer/seeds/purchase`
- **Method:** `POST`
- **Expected Behavior:** Reject purchase attempts for inactive seeds with `400 Bad Request` (`"Seed variety is no longer active for purchase"`).

---

## 4. Impact Analysis

### Admin / Manager Flutter Application:
- Admin UI reflects active vs inactive catalog items via status tabs (`All`, `Active`, `Low Stock`).
- When a seed is soft-deleted, it displays with an `Inactive` badge under `All`, and is filtered out under `Active`.

### Farmer Application & Web Portals:
- Deactivated seeds are completely excluded from catalog browsing, product detail pages, and checkout workflows.
- Prevents farmer confusion and unfulfillable orders.
