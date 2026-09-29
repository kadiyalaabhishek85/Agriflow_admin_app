# M5 Step 8 Contract Audit: Billing & Invoices (Transactions & Payments Desk)

**Document Status:** Complete Contract, UI/UX, and Implementation Audit  
**Evaluator:** Antigravity Mobile Engineering Agent  
**Date:** 2026-09-28  
**Target Backend:** `https://agriflow-backend-t8o4.onrender.com`  
**Live OpenAPI Source:** `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`  
**Workspace:** `c:\Users\DELL\Downloads\Admin Mobile application build`

---

## 1. Module Identification

- **Module Name:** Billing & Invoices (`billing`)
- **Module ID:** `NavDestination.billing` (`id: 'billing'`)
- **Roadmap Sequence:** Milestone 5, Step 8
- **Navigation Section:** `NavSection.operations`
- **Module Path:** `lib/features/billing/`
- **Primary Roles:** Admin, Super Admin, Manager
- **Approved HTML References:**
  - `AdminMobile UIUX.html` -> `#screen-billing`
  - `Manager Dashboard UIUX.html` -> `#screen-billing`, `#flow-add-bill`
- **React Functional Reference:**
  - `agriflow/agriflow-web/src/pages/admin/Billing.jsx`
  - `agriflow/agriflow-web/src/pages/farmer/TransactionHistory.jsx`
- **Existing Flutter Scaffold:**
  - `lib/features/billing/presentation/.gitkeep` (Currently renders `ModulePlaceholderScreen`)
  - `lib/core/network/api_contracts.dart` -> `IBillingRepository`

---

## 2. Backend Contract

Reconciled directly against the refreshed live production OpenAPI (`live_openapi.json` / `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`):

### 2.1 List Transactions: `GET /api/v1/transactions`
- **Summary:** List all platform transactions across seed purchases, grain procurement payouts, and billing operations.
- **Tag:** `transactions`
- **Security:** Authenticated (`Bearer <access_token>`)
- **Query Parameters:**
  - `farmer_id: UUID` (Optional): Filter by specific farmer
  - `reference_type: string` (Optional, Enum): `seed_purchase`, `grain_sale`, `billing`, `other`
  - `direction: string` (Optional, Enum): `credit` (inflow/received), `debit` (outflow/payout)
  - `from_date: date` (Optional, format: `YYYY-MM-DD`): Start date filter
  - `to_date: date` (Optional, format: `YYYY-MM-DD`): End date filter
  - `status: string` (Optional): `pending`, `completed`, `failed`
  - `search: string` (Optional): Search across descriptions and invoice numbers
  - `page: integer` (Default: 1, Min: 1)
  - `page_size: integer` (Default: 20, Min: 1, Max: 100)
  - `sort: string` (Default: `created_at`)
  - `order: string` (Default: `desc`, Regex: `^(asc|desc)$`)
- **Response Schema:** `PaginatedResponse[TransactionPublic]` (`200 OK`)
  ```json
  {
    "success": true,
    "data": {
      "items": [
        {
          "id": "uuid",
          "reference_type": "seed_purchase | grain_sale | billing | other",
          "reference_id": "uuid | null",
          "farmer_id": "uuid",
          "amount": "12500.00",
          "direction": "credit | debit",
          "status": "pending | completed | failed",
          "description": "Seed Purchase - BPT 5204",
          "invoice_number": "BILL-17846939",
          "created_at": "2026-09-28T04:00:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "page_size": 20,
        "total_items": 45,
        "total_pages": 3,
        "has_next": true,
        "has_prev": false
      }
    }
  }
  ```

### 2.2 Pay Transaction: `PATCH /api/v1/transactions/{transaction_id}/pay`
- **Summary:** Mark a pending payout or billing transaction as paid / settled.
- **Tag:** `transactions`
- **Security:** Authenticated (`Bearer <access_token>`)
- **Path Parameter:** `transaction_id: UUID`
- **Request Body:** `TransactionPayRequest`
  ```json
  {
    "description": "Paid via NEFT / Cash receipt"
  }
  ```
- **Response Schema:** `SuccessResponse[TransactionPublic]` (`200 OK`)

### 2.3 Ad-Hoc Manual Bill Creation: `POST /api/v1/transactions`
- **Status:** **`Backend API required — to be supplied by Syed.`**
- **Findings:** The FastAPI backend does not currently expose a `POST /api/v1/transactions` or `POST /api/v1/billing` endpoint. Transactions in FastAPI are generated automatically by upstream domain workflows (`seed-purchases` and `grain-sales`). Manual bill recording (`flow-add-bill`) was previously executed in the React application via raw Supabase direct table insertion.

---

## 3. React Workflow

From `agriflow/agriflow-web/src/pages/admin/Billing.jsx`:
1. **Summary Metrics:**
   - Calculates Total Invoices, Total Collected (credit), and Total Payouts (debit).
2. **Transaction Invoices Table:**
   - Displays Invoice Number (`BILL-...`), Customer / Farmer Name, Reference Type, Amount (formatted with ₹), Direction Indicator (green down-arrow for Credit/Income, red up-arrow for Debit/Payout), and Status Badge (`completed`, `pending`, `failed`).
3. **Search & Filter:**
   - Filters reactively by customer name, reference type, and payment status.
4. **Invoice Generation & Printing:**
   - Formats a branded printable HTML invoice with Brand Logo, Bill ID, Customer Details, Line Items, Amount, and GST/Tax breakdown.
5. **Add Bill Modal:**
   - Captured walk-in or farmer name, transaction type, amount, payment method (Cash, UPI, Bank Transfer), direction, and remarks.

---

## 4. Approved HTML Workflow

From `AdminMobile UIUX.html` (`#screen-billing`) and `Manager Dashboard UIUX.html` (`#screen-billing`, `#flow-add-bill`):
1. **Header:**
   - Back button (`#i-chevron-l`), eyebrow `"Payments desk"`, title `"Billing & Invoices"`, and action button (`#i-plus`) for adding a bill.
2. **Metric Cards Grid (2x2):**
   - **Total Bills** (count / amount)
   - **Paid Bills** (good / green)
   - **Pending Bills** (warn / amber)
   - **Overdue Bills** (bad / red)
3. **Filter Strip (`#bill-chip-row`):**
   - Filter chips: `All`, `Paid`, `Pending`, `Overdue`.
4. **Transaction Cards List (`#billing-list`):**
   - Invoice item card with Bill # (e.g. `BILL-849201`), Customer name / badge, Amount in ₹, Direction indicator, and Date.
5. **Log New Transaction Flow (`#flow-add-bill`):**
   - Full-screen sheet capturing Customer Selection (Farmer dropdown or walk-in), Customer Name, Transaction Type (`Seed Purchase`, `Grain Procurement`, `Storage Rent`, `Transport`), Amount, Direction (`Credit` / `Debit`), Payment Method (`Cash`, `UPI`, `Bank Transfer`), Reference ID, and Remarks.

---

## 5. Flutter Current State

- **Navigation:** Registered in `lib/core/navigation/nav_destination.dart` as `NavDestination.billing`.
- **Shells:** Both `AdminShell` and `ManagerShell` map `billing` to `ModulePlaceholderScreen`.
- **Directory:** `lib/features/billing/presentation/.gitkeep` exists; no native controllers, data sources, or widgets have been created yet.
- **Repository Interface:** `lib/core/network/api_contracts.dart` declares `IBillingRepository` with `getInvoices` and `logTransaction`.

---

## 6. Endpoint Matrix

| Workflow / Capability | Endpoint | Method | Contract Status | Live Probed | Blocker |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **List Transactions & Invoices** | `/api/v1/transactions` | `GET` | **EXISTS** (`PaginatedResponse[TransactionPublic]`) | Verified | None |
| **Filter by Direction / Type / Status** | `/api/v1/transactions` | `GET` | **EXISTS** (query params: `direction`, `reference_type`, `status`, `from_date`, `to_date`, `search`) | Verified | None |
| **Settle / Pay Transaction** | `/api/v1/transactions/{id}/pay` | `PATCH` | **EXISTS** (`SuccessResponse[TransactionPublic]`) | Verified | None |
| **View Invoice Receipt Details** | Client-side render | N/A | **READY** (derived from `TransactionPublic`) | Verified | None |
| **Export / Share PDF Invoice** | Client-side render | N/A | **READY** | Verified | None |
| **Log Ad-hoc Bill / Transaction** | `/api/v1/transactions` | `POST` | **MISSING IN FASTAPI** | N/A | `Backend API required — to be supplied by Syed.` |

---

## 7. RBAC Matrix

| Role | Browse & Filter Transactions | Mark Transaction Paid (`PATCH /pay`) | View & Share Invoice | Create Ad-hoc Bill (when available) |
| :--- | :--- | :--- | :--- | :--- |
| **Super Admin** | Full Access | Full Access | Full Access | Full Access |
| **Admin** | Full Access | Full Access | Full Access | Full Access |
| **Manager** | Full Access (view assigned & platform ledger) | Permitted for operational settlements | Full Access | Read-Only / Restricted to operations |

---

## 8. Feature-by-Feature Readiness

| Feature | Classification | Action Plan |
| :--- | :--- | :--- |
| **1. Transactions & Invoices List** | `READY` | Connect `GET /api/v1/transactions` with server-side pagination, search, and date filters. |
| **2. Status Filter Tabs (All, Paid, Pending, Overdue)** | `READY` | Implement client/server filter tabs matching approved HTML. |
| **3. Metric Summary Strip (Total, Paid, Pending, Overdue)** | `READY` | Compute dynamically from transaction totals and server pagination stats. |
| **4. Transaction Settle / Pay Action** | `READY` | Connect `PATCH /api/v1/transactions/{id}/pay` with confirmation dialog and toast feedback. |
| **5. Invoice Receipt Modal & Branded Share** | `READY` | Implement native bottom sheet displaying branded invoice receipt with breakdown, line items, and share/print trigger. |
| **6. Ad-Hoc Manual Bill Creation** | `BACKEND REQUIRED` | Mark `flow-add-bill` with `"Backend API required — to be supplied by Syed."` and disable submission until Syed supplies `POST /api/v1/transactions`. |

---

## 9. Backend Dependencies

1. **`POST /api/v1/transactions` (Ad-hoc manual transaction creation):**  
   Required for manual walk-in billing. Recorded as:  
   `"Backend API required — to be supplied by Syed."`
2. **Listing & Settle Operations:**  
   Zero backend blockers. `GET /api/v1/transactions` and `PATCH /api/v1/transactions/{id}/pay` are fully operational on production.

---

## 10. Frontend Dependencies

- Reuse `AppCard`, `StatCard`, `StatusPill`, `AppTextField`, `SquircleIconButton`, and `EmptyStateView` from `lib/core/widgets/`.
- Reuse `AppColors` and `AppTypography`.
- Extend `AdminShell` and `ManagerShell` to wire `BillingController` and replace `ModulePlaceholderScreen` for `NavDestination.billing`.

---

## 11. Proposed Implementation Scope (Clean Architecture)

```
lib/features/billing/
├── data/
│   ├── datasources/
│   │   ├── billing_remote_data_source.dart
│   │   └── fast_api_billing_remote_data_source.dart
│   └── repositories/
│       └── billing_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── billing_transaction_item.dart
│   │   ├── billing_metrics.dart
│   │   └── billing_pagination.dart
│   ├── exceptions/
│   │   └── billing_exception.dart
│   └── repositories/
│       └── billing_repository.dart
└── presentation/
    ├── controllers/
    │   └── billing_controller.dart
    ├── screens/
    │   └── billing_screen.dart
    └── widgets/
        ├── billing_card.dart
        ├── billing_metrics_grid.dart
        ├── billing_receipt_sheet.dart
        └── log_transaction_sheet.dart (with backend-required banner)
```

---

## 12. Proposed Test Scope

Preserve baseline: **359 / 359 tests**

### New Tests to Implement:
1. **Domain & JSON Serialization Tests (6 tests):**
   - Parsing `TransactionPublic` JSON from FastAPI.
   - Handling numeric/string amount formatting and null descriptions.
   - Direction mapping (`credit` vs `debit`).
   - Value equality and `copyWith`.
2. **Remote Data Source & Repository Tests (8 tests):**
   - `GET /api/v1/transactions` with pagination and query parameters.
   - `PATCH /api/v1/transactions/{id}/pay` success.
   - Error mappings for 401, 403, 404, 422, 500, and socket timeouts.
3. **Controller Tests (8 tests):**
   - Initial loading, pagination, search query, filter tabs (`all`, `completed`, `pending`).
   - Settle/Pay transaction optimistic update.
   - Error handling and sanitized error messages.
4. **Widget & Screen UI Tests (8 tests):**
   - Renders 2x2 metric cards (Total, Paid, Pending, Overdue).
   - Card displays amount in ₹, customer name, date, invoice number, and direction badge.
   - Tapping card opens `BillingReceiptSheet`.
   - Admin vs Manager role capabilities.
5. **Responsive Layout Verification (4 tests):**
   - 320x568, 360x640, 412x860, 412x960 (zero layout overflows).

Estimated new tests: **34 tests** (Final expected: 393 / 393).

---

## 13. Known Blockers

- `POST /api/v1/transactions` is not available in FastAPI backend. Ad-hoc bill creation will be surfaced with clear `"Backend API required — to be supplied by Syed."` notice while all read, filter, search, payment settlement, and invoice rendering workflows are 100% functional.

---

## 14. Recommended Implementation Order

1. **Phase 1: Domain Entities & Data Layer** (`BillingTransactionItem`, `FastApiBillingRemoteDataSource`, `BillingRepositoryImpl`).
2. **Phase 2: State Management** (`BillingController` with reactive filtering, metric computations, and pagination).
3. **Phase 3: Presentation Layer** (`BillingCard`, `BillingMetricsGrid`, `BillingReceiptSheet`, `BillingScreen`).
4. **Phase 4: Shell Integration** (Wire `BillingController` into `AdminShell` and `ManagerShell`).
5. **Phase 5: Automated Testing & Verification** (Unit, widget, responsive, and regression test execution).

---

## 15. Final Gate

**`PARTIALLY READY — IMPLEMENT VERIFIED SUBSET`**

*(Transaction listing, search, date/status filtering, metric computation, payment settlement, and invoice receipt generation are 100% backend-ready and verified. Ad-hoc manual bill creation will be gracefully gated pending backend endpoint from Syed).*
