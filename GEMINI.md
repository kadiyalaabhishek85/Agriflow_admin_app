# GEMINI.md — AgriFlow Workspace Memory & Backend Invariants

This repository is the **AgriFlow Admin & Manager Mobile Flutter Application**.

---

## 1. Ground Truth Backend Authority

- **Live FastAPI Backend:** `https://agriflow-backend-t8o4.onrender.com`
- **Swagger Documentation:** `https://agriflow-backend-t8o4.onrender.com/api/v1/docs#/`
- **OpenAPI 3.1 Schema:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`
- **Local OpenAPI Cache:** `openapi_dump.json` (in workspace root)
- **Backend & Database Lead:** Syed

### Golden Rule:
**NEVER invent or fabricate endpoints, request payloads, response properties, database tables, or business rules.**  
The live FastAPI OpenAPI is authoritative. All missing features must be marked:  
`"Backend API required — to be supplied by Syed."`

---

## 2. Memorized Live Endpoints Summary

1. **Authentication (`/api/v1/auth`, `/api/v1/users`):**
   - `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`, `GET /users/me`, `PATCH /users/me`, `POST /auth/send-otp`, `POST /auth/verify-otp`, `POST /auth/change-password`, `POST /auth/forgot-password/send-otp`, `POST /auth/forgot-password/reset`
2. **Admin Dashboard & Reports (`/api/v1/admin`):**
   - `GET /admin/dashboard`, `GET /admin/reports/monthly`, `GET /admin/audit-logs`
3. **Managers Directory (`/api/v1/managers`):**
   - `GET /managers`, `POST /managers`, `PATCH /managers/{id}/status`, `POST /managers/{id}/reset-password`
4. **Farmers Management (`/api/v1/farmers`):**
   - `GET /farmers`, `POST /farmers`, `GET /farmers/{id}`, `PATCH /farmers/{id}/approval`, `GET /farmers/bank-change-requests`, `PATCH /farmers/bank-change-requests/{id}`
5. **Seeds Inventory (`/api/v1/seeds` & `/api/v1/seed-purchases`):**
   - `GET /seeds`, `POST /seeds`, `PATCH /seeds/{id}`, `DELETE /seeds/{id}`
   - `GET /seed-purchases`, `POST /seed-purchases`, `PATCH /seed-purchases/{id}/status`
   - *Schema Notice:* Base price only (`price_per_kg`). Grade A/B/C pricing and warehouse assignments are pending backend additions from Syed.
6. **Warehouses & Slots (`/api/v1/warehouses`, `/api/v1/warehouse-slots`):**
   - `GET /warehouses`, `POST /warehouses`, `POST /warehouses/{id}/inventory`, `GET /warehouses/{id}/slots`
   - `GET /warehouse-slots`, `POST /warehouse-slots`, `PATCH /warehouse-slots/{id}`
   - *Schema Notice:* Warehouse `PATCH` and `DELETE`, and `GET /warehouses/{id}/inventory` are pending backend additions from Syed.
7. **Crops & Farm Visits (`/api/v1/crops`, `/api/v1/farm-visits`):**
   - `GET /crops`, `POST /crops`, `GET /crops/active`
   - `GET /farm-visits`, `POST /farm-visits`, `PATCH /farm-visits/{id}/schedule`, `PATCH /farm-visits/{id}/complete`, `POST /farm-visits/reminders`
8. **Bookings & Grain Sales (`/api/v1/bookings`, `/api/v1/grain-sales`):**
   - `GET /bookings`, `POST /bookings`, `PATCH /bookings/{id}/status`, `POST /bookings/{id}/inspect`
   - `GET /grain-sales`, `POST /grain-sales`, `PATCH /grain-sales/{id}/review`, `PATCH /grain-sales/{id}/pay`, `POST /grain-sales/procure`, `PATCH /grain-sales/{id}/yield`
9. **Market Rates & Transactions (`/api/v1/market-rates`, `/api/v1/transactions`):**
   - `GET /market-rates`, `POST /market-rates`
   - `GET /transactions`, `PATCH /transactions/{id}/pay`
10. **Public Endpoints (`/api/v1/public`):**
    - `GET /public/market-rates`, `GET /public/seeds`, `GET /public/stats`

---

## 3. RBAC Rules & Permissions

- **Super Admin & Admin:** Full mutation access to Seeds, Warehouses, Managers, Market Rates, and Farmer KYC approvals.
- **Manager:** Strictly READ-ONLY for master catalogs (Seeds, Warehouses). Cannot create, edit, or delete seeds. Cannot create or edit warehouses. Managers can only inspect stock, record grain intake/procurement, complete assigned farm visits, and approve/reject farmer KYC.

---

## 4. Pending Backend Contracts Reference

All detailed proposals for backend expansions are documented in:  
`docs/backend-requirements-admin-mobile.md`
