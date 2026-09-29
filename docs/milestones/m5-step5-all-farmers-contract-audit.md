# Milestone 5 — Step 5: All Farmers Module Contract Audit

**Document Status:** Complete Audit & Contract Discovery  
**Author:** Antigravity Agent  
**Date:** 2026-09-24  
**Workspace:** `c:\Users\DELL\Downloads\Admin Mobile application build`  

---

## 1. Executive Summary

Milestone 5 Step 5 encompasses the **All Farmers** directory for the AgriFlow Admin & Manager mobile applications. This audit reconciles the four operational authorities:
1. **FastAPI Backend / OpenAPI Specification (`openapi_dump.json`)**: Sole authority for contracts, schema validation, permissions, and available endpoints.
2. **React / Next.js Web Application (`agriflow/agriflow-web`)**: Functional reference for user flows, status approval triggers, registration modal, and profile inspections.
3. **Approved Mobile UI/UX HTML Specifications (`AdminMobile UIUX.html` & `Manager Dashboard UIUX.html`)**: Visual and interaction design authority for screens, cards, badges, detail bottom sheets, and full flows.
4. **Flutter Production Codebase (`lib/` and `test/`)**: Native production implementation target.

### Key Audit Findings
- **Verified Core Backend APIs:** The FastAPI backend fully exposes endpoints for listing/searching farmers (`GET /api/v1/farmers`), retrieving farmer profiles (`GET /api/v1/farmers/{farmer_id}`), creating new farmers (`POST /api/v1/farmers`), updating approval status (`PATCH /api/v1/farmers/{farmer_id}/approval`), and managing bank change requests (`GET /api/v1/farmers/bank-change-requests`, `PATCH /api/v1/farmers/bank-change-requests/{request_id}`).
- **Backend Gaps / Pending Contracts:**
  - **Edit Farmer Profile:** There is **NO** endpoint (`PATCH /api/v1/farmers/{farmer_id}` or `PUT /api/v1/farmers/{farmer_id}`) for admins or managers to modify existing farmer profile fields (acres, address, name, etc.). Only `/api/v1/farmers/me` exists for a farmer's self-service profile.
  - **Delete Farmer:** The React web app contains a `deleteFarmer` call to a Supabase edge function, but the FastAPI backend provides **NO** `DELETE /api/v1/farmers/{farmer_id}` endpoint. Permanent deletion is not supported. Deactivation is achieved via `PATCH /api/v1/farmers/{farmer_id}/approval` with `status: "suspended"`.
  - **Farmer Crop & Transaction Sub-Lists in Detail View:** In Manager HTML and React, the farmer detail sheet shows counts of crops, transactions, and grain sales, along with a list of past transactions. However, `FarmerAdminView` in FastAPI only returns `farmer_profile`. It does not embed sub-lists of transactions or crops.
- **Role Differentiation:** Both Admin and Manager have access to the farmer directory and registration. Admin additionally manages bank change requests and has oversight over account suspension.
- **Gate Recommendation:** **READY FOR IMPLEMENTATION** for all verified capabilities; missing mutations (Edit Profile, Hard Delete, nested billing history) are classified as **PENDING BACKEND CONTRACT** and will not block core mobile directory delivery.

---

## 2. Backend Endpoint Inventory

| HTTP Method | Route | Summary | Operation ID | Security | Status |
|:---|:---|:---|:---|:---|:---|
| `GET` | `/api/v1/farmers` | List Farmers with pagination, search, status filter, and sorting | `list_farmers_api_v1_farmers_get` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `POST` | `/api/v1/farmers` | Create/Register Farmer | `create_farmer_api_v1_farmers_post` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `GET` | `/api/v1/farmers/{farmer_id}` | Get Farmer Details by UUID | `get_farmer_api_v1_farmers__farmer_id__get` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `PATCH` | `/api/v1/farmers/{farmer_id}/approval` | Update Farmer Status (`pending`, `active`, `rejected`, `suspended`) | `set_farmer_approval_api_v1_farmers__farmer_id__approval_patch` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `GET` | `/api/v1/farmers/bank-change-requests` | List Bank Change Requests (Admin) | `list_bank_change_requests_api_v1_farmers_bank_change_requests_get` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `PATCH` | `/api/v1/farmers/bank-change-requests/{request_id}` | Review Bank Change Request (Admin) | `review_bank_change_api_v1_farmers_bank_change_requests__request_id__patch` | OAuth2 Bearer | **VERIFIED BACKEND** |
| `PATCH` / `PUT` | `/api/v1/farmers/{farmer_id}` | Edit Farmer Profile | *None* | *None* | **BACKEND GAP / PENDING CONTRACT** |
| `DELETE` | `/api/v1/farmers/{farmer_id}` | Delete Farmer Record | *None* | *None* | **BACKEND GAP / PENDING CONTRACT** |

---

## 3. Request/Response Schema Audit

### 3.1 `GET /api/v1/farmers`
- **Query Parameters:**
  - `page`: integer, minimum 1, default `1`
  - `page_size`: integer, minimum 1, maximum 100, default `20`
  - `search`: string or null (searches name, phone)
  - `status`: string or null (`pending`, `active`, `rejected`, `suspended`)
  - `sort`: string, default `"created_at"`
  - `order`: string regex `^(asc|desc)$`, default `"desc"`
- **Response `200 OK`:** `PaginatedResponse[FarmerAdminView]`
  ```json
  {
    "data": [
      {
        "id": "uuid",
        "name": "string",
        "phone": "string",
        "email": "string | null",
        "status": "pending | active | rejected | suspended",
        "created_at": "ISO-8601 string",
        "farmer_profile": {
          "id": "uuid",
          "user_id": "uuid",
          "address": "string | null",
          "acres_of_land": "string (decimal pattern)",
          "bank_name": "string | null",
          "account_number": "string | null",
          "ifsc_code": "string | null",
          "upi_id": "string | null",
          "bank_status": "pending | approved | rejected",
          "soil_type": "string | null",
          "irrigation_type": "string | null",
          "primary_crop": "string | null",
          "secondary_crop": "string | null"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total_records": 100,
      "total_pages": 5,
      "has_next": true,
      "has_previous": false
    }
  }
  ```

### 3.2 `POST /api/v1/farmers` (Create Farmer)
- **Request Body:** `FarmerCreateRequest`
  ```json
  {
    "name": "Ramulu Naik",             // required, string (2..255 chars)
    "phone": "9876543210",              // required, string (8..20 chars)
    "password": "Password123",          // required, string (8..128 chars)
    "email": "farmer@example.com",      // optional, string format email or null
    "address": "Village XYZ",           // optional, string or null
    "acres_of_land": 5.5,               // optional, number >= 0, string, or null
    "crop_address": "Farm Plot 4"       // optional, string or null
  }
  ```
- **Response `201 Created`:** `SuccessResponse[FarmerAdminView]`
  ```json
  {
    "success": true,
    "message": "Success",
    "data": { ...FarmerAdminView... }
  }
  ```

### 3.3 `GET /api/v1/farmers/{farmer_id}` (Get Farmer Details)
- **Path Parameter:** `farmer_id`: UUID string (required)
- **Response `200 OK`:** `SuccessResponse[FarmerAdminView]`
  ```json
  {
    "success": true,
    "message": "Success",
    "data": { ...FarmerAdminView... }
  }
  ```

### 3.4 `PATCH /api/v1/farmers/{farmer_id}/approval` (Update Approval Status)
- **Path Parameter:** `farmer_id`: UUID string (required)
- **Request Body:** `FarmerApprovalRequest`
  ```json
  {
    "status": "active" // required, Enum: "pending" | "active" | "rejected" | "suspended"
  }
  ```
- **Response `200 OK`:** `SuccessResponse[FarmerAdminView]`
  ```json
  {
    "success": true,
    "message": "Success",
    "data": { ...FarmerAdminView... }
  }
  ```

### 3.5 Bank Change Requests Endpoints (Admin Oversight)
- `GET /api/v1/farmers/bank-change-requests`: Returns `PaginatedResponse[BankChangeRequestPublic]`
- `PATCH /api/v1/farmers/bank-change-requests/{request_id}`:
  Request Body: `BankChangeReviewRequest`:
  ```json
  {
    "approve": true,
    "admin_notes": "string | null"
  }
  ```

---

## 4. Role & Permission Matrix

| Capability / Action | Super Admin / Admin | Manager | Source / Authority |
|:---|:---:|:---:|:---|
| **View Farmer Directory** (`GET /api/v1/farmers`) | ✅ Full Access | ✅ Full Access | Backend API & Tech Spec §3 |
| **Search & Filter by Status** | ✅ Yes | ✅ Yes | Backend API & Approved HTML |
| **Inspect Farmer Details Sheet** (`GET .../{id}`) | ✅ Yes | ✅ Yes | Backend API & Approved HTML |
| **Approve Farmer** (`PATCH .../approval` -> `active`) | ✅ Yes | ✅ Yes | Backend API, React, Tech Spec §3 |
| **Reject Farmer** (`PATCH .../approval` -> `rejected`) | ✅ Yes | ✅ Yes | Backend API, React, Tech Spec §3 |
| **Suspend Farmer** (`PATCH .../approval` -> `suspended`) | ✅ Yes | ❌ Blocked | Backend Enum / Admin Only |
| **Register / Add Farmer** (`POST /api/v1/farmers`) | ✅ Yes | ✅ Yes (`flow-add-farmer`) | Backend API & Manager HTML |
| **Call Farmer via Phone Dialer** (`tel:...`) | ✅ Yes | ✅ Yes | Approved HTML (`AdminMobile UIUX.html`) |
| **Bank Change Request Approval** | ✅ Yes | ❌ Forbidden | Tech Spec §3 & §4.2 (Admin only) |
| **Delete Farmer** | ⚠️ Not in FastAPI | ❌ Blocked | Backend Gap / Pending Contract |
| **Edit Farmer Profile Info** | ⚠️ Not in FastAPI | ⚠️ Not in FastAPI | Backend Gap / Pending Contract |

---

## 5. React Functional Mapping

### 5.1 `agriflow-web/src/pages/admin/Farmers.jsx`
- **Directory Table & Mobile Cards:** Fetches list via `adminService.getFarmers()`, filters by search string (name, phone) and status tab (`all`, `pending`, `active`, `rejected`).
- **Registration Modal:** Super Admin button triggers registration modal with fields:
  - `name`: Full Name (required, min 2 chars)
  - `phone`: 10-digit mobile (sanitized, live numeric regex validation)
  - `email`: Optional email address
  - `password`: Password (min 8 chars)
  - `address`: Village / Town
  - `acres_of_land`: Number of acres
  - `crop_address`: Farm location
- **Status Approvals:** Quick inline buttons (`Check` -> `active`, `X` -> `rejected`) invoke `managerService.approveFarmer(id, status, notes, adminId)`.
- **Detail Side-Panel:** Displays avatar, name, phone, email, status pill, registration date, acres, bank status, crop address, and aggregated stats (crops count, transactions count, sales count).
- **Delete Farmer:** Invokes `adminService.deleteFarmer(id)`. *Note: This exists only as a Supabase edge function; there is no endpoint for this in FastAPI.*

### 5.2 `agriflow-web/src/pages/superadmin/AllFarmers.jsx`
- **Summary Header:** Stat counters for `ACTIVE` count and `PENDING` count.
- **Search Bar:** Real-time filter by name or phone.
- **Detail Modal:** Displays Phone, Email, Village/Address, Land Acres, Aadhaar Number, Joined Date, and crop tag pills.

---

## 6. Approved HTML UI Mapping

### 6.1 `AdminMobile UIUX.html` (`#screen-all-farmers`)
- **Header:**
  - Eyebrow: `Global farmer directory`
  - Title: `All Farmers`
- **Top Stats Bar:** Two counter cards:
  - `ACTIVE` (`#af-count-active`)
  - `PENDING` (`#af-count-pending`)
- **Search Field:** `#af-search` with search icon ("Search by name or phone").
- **Farmer Card Layout (`#all-farmers-list`):**
  - Left: Circular avatar with name initials (`req-avatar`).
  - Middle: Farmer Name (bold, 13.5px), Subtitle: `${f.phone} · ${f.land} acres` (muted, 11.5px).
  - Status Pill: `Active` (green) or `Pending` (amber/warn).
  - Action: Square eye icon button (`openFarmerView(idx)`).
- **Detail Overlay / Bottom Sheet (`#overlay-farmer-view`):**
  - Eyebrow: `Farmer profile` with close button.
  - Centered Avatar (64x64) with initials, large farmer name, status pill.
  - 2x2 Grid of cards:
    1. `Phone`: Phone number
    2. `Land size`: `${land} acres`
    3. `Email`: Email address (grid-column span 2)
    4. `Joined`: Formatted date (grid-column span 2)
  - Primary Action Button: "Call farmer" (`<a href="tel:..." class="btn primary block">`).

### 6.2 `Manager Dashboard UIUX.html` (`#screen-all-farmers`)
- **Header:**
  - Eyebrow: `Farmer directory`
  - Title: `All Farmers`
  - Top-Right Action: `+` button opening `#flow-add-farmer`.
- **Top Stats Bar:** `ACTIVE` and `PENDING` counter cards.
- **Search Field:** `#af-search`.
- **Farmer Card Layout:** Identical to Admin card layout.
- **Add Farmer Full Flow (`#flow-add-farmer`):**
  - Header: Back button, Title "Add Farmer", Subtitle "Farmer directory", Close button.
  - Illustration Card: Icon with "Register a new farmer - They'll show up in your directory right away".
  - Form Fields:
    - Full name *
    - Phone * (input type="tel")
    - Email (optional)
    - Land size (acres)
  - Footer: "Add farmer" button calling `saveEdit('farmer', null)`.
- **Farmer Profile Flow (`#flow-farmer-profile`):**
  - Large avatar, Name, Phone, Email, Status pill.
  - Detail rows: Email, Registered On.
  - 3 Stat counters in grid: Crops count, Txns count, Sales count.
  - Past Transactions list.

---

## 7. Flutter Current-State Audit

- **Routing & Shells:**
  - `NavDestination.allFarmers`: `id: 'all-farmers'`, `title: 'Farmers'`, `icon: Icons.people_outline_rounded`.
  - In `admin_shell.dart` and `manager_shell.dart`: Currently routed to `ModulePlaceholderScreen`.
  - In `admin_dashboard_view.dart`: "Total Farmers" metric card navigates to `NavDestination.allFarmers.id`.
  - In `custom_drawer.dart`: "Farmers" item is rendered under Operations section.
- **Existing Lookup Usage:**
  - `BookingRemoteDataSourceImpl`, `FarmVisitRemoteDataSourceImpl`, `SeedPurchaseRemoteDataSourceImpl`, and `GrainSaleRemoteDataSourceImpl` all make a lightweight call to `_uri('/farmers', {'page': '1', 'page_size': '100'})` to construct farmer lookup maps (`{farmerId: (name, phone, village)}`).
- **Feature Directory:**
  - `lib/features/farmers/` currently only contains empty `.gitkeep` files in `data/`, `domain/`, and `presentation/`.

---

## 8. Capability Reconciliation Matrix

| Capability | Backend (FastAPI) | React Reference | Approved HTML | Classification | Mobile Scope Action |
|:---|:---:|:---:|:---:|:---|:---|
| **Farmer List & Pagination** | `GET /api/v1/farmers` (page, page_size, sort, order) | `adminService.getFarmers()` | Card list in `#screen-all-farmers` | **VERIFIED BACKEND + VERIFIED REACT** | Implement with full pagination |
| **Search by Name or Phone** | `GET /api/v1/farmers?search=...` | Client-side filter | `#af-search` input | **VERIFIED BACKEND + VERIFIED REACT** | Implement with live query search |
| **Filter by Status** | `GET /api/v1/farmers?status=...` | Tab filter (`pending`, `active`, `rejected`) | Status pills (`Active`, `Pending`) | **VERIFIED BACKEND + VERIFIED REACT** | Implement status tabs/filters |
| **Active / Pending Counts** | Calculated from records / dashboard | Local filter length | `#af-count-active`, `#af-count-pending` | **VERIFIED REACT + APPROVED HTML** | Implement derived counters |
| **Farmer Detail Sheet** | `GET /api/v1/farmers/{farmer_id}` | `adminService.getFarmerDetails(id)` | `#overlay-farmer-view` & `#flow-farmer-profile` | **VERIFIED BACKEND + VERIFIED REACT** | Implement detail bottom sheet |
| **Approve Farmer** | `PATCH /api/v1/farmers/{id}/approval` (`active`) | `managerService.approveFarmer(id, 'active')` | Inline check button & detail sheet button | **VERIFIED BACKEND + VERIFIED REACT** | Implement approval mutation |
| **Reject Farmer** | `PATCH /api/v1/farmers/{id}/approval` (`rejected`) | `managerService.approveFarmer(id, 'rejected')` | Inline reject button & detail sheet button | **VERIFIED BACKEND + VERIFIED REACT** | Implement rejection mutation |
| **Suspend Farmer** | `PATCH /api/v1/farmers/{id}/approval` (`suspended`) | Not exposed in main UI | Not in mobile HTML | **VERIFIED BACKEND ONLY** | Admin-accessible status option |
| **Register / Add Farmer** | `POST /api/v1/farmers` (`FarmerCreateRequest`) | Modal form in Admin `Farmers.jsx` | `#flow-add-farmer` in Manager HTML | **VERIFIED BACKEND + VERIFIED REACT** | Implement add farmer bottom sheet / flow |
| **Call Farmer Phone Dialer** | Not applicable (OS level) | Displayed as link | `<a href="tel:...">` Call farmer button | **APPROVED HTML ONLY** | Implement `url_launcher` `tel:` intent |
| **Edit Farmer Profile Info** | ❌ No backend route | ❌ Not in React | ⚠️ Mocked in HTML | **BACKEND GAP / PENDING CONTRACT** | Keep blocked pending backend contract |
| **Delete Farmer** | ❌ No backend route | Supabase function only | ❌ Not in Mobile HTML | **BACKEND GAP / PENDING CONTRACT** | Keep blocked pending backend contract |
| **Farmer Nested Transactions** | ❌ Not in `FarmerAdminView` | Present via edge function | Present in Manager HTML | **BACKEND GAP / PENDING CONTRACT** | Gracefully omitted or pending sub-query |
| **Bank Change Review** | `GET`/`PATCH /bank-change-requests` | Exists in Bank Requests tab | Separate admin flow | **VERIFIED BACKEND ONLY** | Excluded from primary Farmers directory |

---

## 9. Backend Gaps

1. **Missing Farmer Profile Edit Route:**
   - There is no endpoint such as `PATCH /api/v1/farmers/{farmer_id}` to update farmer properties (`name`, `acres_of_land`, `address`, `phone`).
   - *Impact on Mobile:* Profile fields are read-only.
2. **Missing Farmer Delete Route:**
   - There is no `DELETE /api/v1/farmers/{farmer_id}` endpoint in OpenAPI.
   - *Impact on Mobile:* Deletion button will NOT be implemented. Account deactivation / rejection / suspension will be used instead.
3. **No Embedded Transaction History in Farmer View:**
   - `FarmerAdminView` only includes `farmer_profile`. It does not return crops, transactions, or grain sales history for that farmer.
   - *Impact on Mobile:* The detail bottom sheet will show all verified profile fields (Phone, Land size, Email, Address, Bank details, Registration date). Historical transaction sub-lists will be marked as pending backend expansion.

---

## 10. Risks & Ambiguities

1. **Password Generation for Manager-Created Farmers:**
   - `FarmerCreateRequest` strictly requires a `password` field (min 8 characters).
   - In Manager HTML `#flow-add-farmer`, only name, phone, email, and land size are collected.
   - *Resolution:* When adding a farmer from the mobile app, the form must either include a password field (like React `Farmers.jsx`) or generate a secure temporary initial password (e.g. `AgriFlow@<Last4Phone>`) adhering to backend validation.
2. **Phone Number Format:**
   - FastAPI enforces `min_length: 8, max_length: 20` for `phone`.
   - React validates a 10-digit Indian mobile number (`sanitizeMobileInput`).
   - Mobile form should enforce 10-digit numeric input.
3. **Acres of Land Format:**
   - FastAPI accepts number or decimal string pattern. Mobile will serialize as numeric double/string.

---

## 11. Recommended Flutter Implementation Scope

### Architecture
- **Layer 1: Domain**
  - Entity: `FarmerItem` (with nested `FarmerProfileItem`)
  - Entity: `FarmerPagination`
  - Enums: `FarmerStatus` (`pending`, `active`, `rejected`, `suspended`)
  - Repository interface: `FarmerRepository`
- **Layer 2: Data**
  - Remote Data Source: `FarmerRemoteDataSource` calling `/api/v1/farmers`
  - Repository Implementation: `FarmerRepositoryImpl`
- **Layer 3: Presentation**
  - Controller: `FarmerController` (ChangeNotifier managing list, pagination, filter, search, detail loading, approval actions, creation)
  - Screen: `FarmerScreen`
  - Widgets:
    - `FarmerCard`: Avatar initials, name, phone, acres, status pill, view action button
    - `FarmerDetailSheet`: Bottom sheet matching `#overlay-farmer-view` with Phone, Land size, Email, Address, Bank details, Joined date, status change buttons (Approve/Reject), and Call Farmer button
    - `AddFarmerSheet`: Modal bottom sheet matching `#flow-add-farmer` with full validation
- **Layer 4: Shell Integration**
  - Connect `NavDestination.allFarmers` in `admin_shell.dart` and `manager_shell.dart`.

---

## 12. Explicitly Pending Backend Capabilities

The following features will **NOT** be invented, mocked, or locally simulated in Flutter:
1. **Edit Farmer Profile:** Flagged as `PENDING BACKEND CONTRACT`.
2. **Permanent Delete Farmer:** Flagged as `PENDING BACKEND CONTRACT`.
3. **Nested Farmer Billing / Transaction History:** Flagged as `PENDING BACKEND CONTRACT`.

---

## 13. Test Plan

1. **Unit & Model Tests:**
   - JSON parsing of `FarmerAdminView` with and without `farmer_profile`.
   - Handling of null optional fields (email, address, bank details).
   - Serialization of `FarmerCreateRequest` and `FarmerApprovalRequest`.
2. **Repository & Remote Data Source Tests:**
   - Query parameter construction (`page`, `page_size`, `search`, `status`).
   - HTTP 200, 201, 401, 403, 404, 422, and 500 error mapping.
3. **Controller Tests:**
   - Initial load and state transitions (`initial` -> `loading` -> `success` / `error`).
   - Real-time search query debounce / execution.
   - Status filtering (`all`, `pending`, `active`, `rejected`).
   - Approval and Rejection state updates.
   - Creation of new farmer and list invalidation.
4. **Widget & Screen Tests:**
   - Rendering of empty state, error state, and populated farmer list.
   - Top active/pending counter cards display.
   - Tapping eye button opens detail bottom sheet.
   - Tapping "Call farmer" triggers URL launcher.
   - Manager vs Admin permission handling.
5. **Static Analysis & Build:**
   - `flutter analyze` = 0 issues.
   - Full test suite passing with 0 regressions.

---

## 14. Gate Decision

### **STATUS: READY FOR IMPLEMENTATION**

- All core directory, search, filter, detail, approval/rejection, and creation contracts are **VERIFIED** in the FastAPI OpenAPI specification.
- React and HTML UI alignments are completely defined.
- Unverified mutations (profile editing and hard deletion) are cleanly marked as **PENDING BACKEND CONTRACT** and excluded from mobile implementation without blocking verified features.

*Awaiting user approval to proceed to Milestone 5 Step 5 implementation.*
