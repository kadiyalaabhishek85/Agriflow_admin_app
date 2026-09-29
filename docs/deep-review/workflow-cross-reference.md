# Workflow cross-reference — React portal, Flutter app and the cached FastAPI contract (leaf-1.5.1)

## Scope

This document reconciles three authorities into one mapping:

1. The React website `agriflow/agriflow-web`, as reviewed in `docs/deep-review/react-01-ui-workflows.md` and `docs/deep-review/react-02-services-and-backend.md` — used here as the **workflow reference**, because it is the only place in the repository where the full breadth of product journeys (marketing, farmer portal, manager portal, super-admin portal) is expressed as screens.
2. The Flutter application `lib/`, as reviewed in `docs/deep-review/flutter-01-core-entry-config.md`, `docs/deep-review/flutter-02-auth-admin-manager-dashboard.md`, `docs/deep-review/flutter-03-farmers-visits-grain-booking.md`, `docs/deep-review/flutter-04-seeds-and-placeholders.md`, `docs/deep-review/flutter-05-test-suite.md` and `docs/deep-review/flutter-06-platform-targets.md` — the **product** being shipped.
3. The cached backend contract `openapi_dump.json` (94 paths, 112 operations) — the **only** source of backend truth for this document.

Nothing else is treated as backend authority. In particular the Supabase tables, RPCs and edge functions described in `docs/deep-review/react-02-services-and-backend.md` are reported as *what the React site actually does*, never as contract. Every backend route named as a citation in this document was verified by parsing `openapi_dump.json` directly and is written on its own line in the form `API: <METHOD> <path>` using the exact path string (including the real parameter names such as `{farmer_id}`, `{visit_id}`, `{purchase_id}`), never the `{id}` shorthand used by `AGENTS.md` prose.

Where any of the three sides needs a capability the contract does not expose, the capability is recorded with the exact literal sentence `Backend API required - to be supplied by Syed.` and is deliberately **not** given an `API:` citation, because the route does not exist. No endpoint, payload, response property, table or business rule is invented here.

The headline structural fact that shapes every row of the mapping below: the React site never calls the FastAPI backend at all (it talks to Supabase edge functions and PostgREST, `agriflow/agriflow-web/src/lib/supabase.js`), while the Flutter app talks to the FastAPI contract on every data path (`lib/features/auth/data/datasources/auth_remote_data_source.dart`). The two clients therefore share screens but not a backend, and "parity" in the tables below means *the screen journey exists on both sides with a real contract endpoint behind it*, not that the two clients reach the same server today.

Verdict vocabulary used throughout: **parity** = React screen, Flutter screen and a contract route all exist and align; **partial** = the journey exists on both sides but is missing a step, a field, a filter or a route; **gap** = one of the three sides has no equivalent at all.

## Files reviewed

Authority inputs:

FILE: openapi_dump.json
FILE: AGENTS.md
FILE: docs/deep-review/react-01-ui-workflows.md
FILE: docs/deep-review/react-02-services-and-backend.md
FILE: docs/deep-review/flutter-01-core-entry-config.md
FILE: docs/deep-review/flutter-02-auth-admin-manager-dashboard.md
FILE: docs/deep-review/flutter-03-farmers-visits-grain-booking.md
FILE: docs/deep-review/flutter-04-seeds-and-placeholders.md
FILE: docs/deep-review/flutter-05-test-suite.md
FILE: docs/deep-review/flutter-06-platform-targets.md

React reference screens and services (workflow side):

FILE: agriflow/agriflow-web/src/app/router/AppRouter.jsx
FILE: agriflow/agriflow-web/src/pages/auth/Login.jsx
FILE: agriflow/agriflow-web/src/pages/auth/ForgotPassword.jsx
FILE: agriflow/agriflow-web/src/pages/admin/Dashboard.jsx
FILE: agriflow/agriflow-web/src/pages/admin/Farmers.jsx
FILE: agriflow/agriflow-web/src/pages/admin/FarmVisits.jsx
FILE: agriflow/agriflow-web/src/pages/admin/GrainSalesAdmin.jsx
FILE: agriflow/agriflow-web/src/pages/admin/GrainProcurement.jsx
FILE: agriflow/agriflow-web/src/pages/admin/BookingSlots.jsx
FILE: agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx
FILE: agriflow/agriflow-web/src/pages/admin/SeedPurchases.jsx
FILE: agriflow/agriflow-web/src/pages/admin/Warehouse.jsx
FILE: agriflow/agriflow-web/src/pages/admin/MarketRates.jsx
FILE: agriflow/agriflow-web/src/pages/admin/Billing.jsx
FILE: agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx
FILE: agriflow/agriflow-web/src/pages/admin/Reports.jsx
FILE: agriflow/agriflow-web/src/pages/admin/EventLogs.jsx
FILE: agriflow/agriflow-web/src/pages/admin/ManagerProfile.jsx
FILE: agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx
FILE: agriflow/agriflow-web/src/pages/farmer/TransactionHistory.jsx
FILE: agriflow/agriflow-web/src/components/shared/NotificationCenter.jsx
FILE: agriflow/agriflow-web/src/services/authService.js
FILE: agriflow/agriflow-web/src/services/adminService.js
FILE: agriflow/agriflow-web/package.json

Flutter product screens, data sources and navigation:

FILE: lib/main.dart
FILE: lib/app.dart
FILE: lib/core/navigation/nav_destination.dart
FILE: lib/core/widgets/module_placeholder_screen.dart
FILE: lib/features/auth/data/datasources/auth_remote_data_source.dart
FILE: lib/features/auth/domain/entities/auth_user.dart
FILE: lib/features/auth/presentation/screens/login_screen.dart
FILE: lib/features/auth/presentation/screens/forgot_password_screen.dart
FILE: lib/features/admin/presentation/admin_shell.dart
FILE: lib/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart
FILE: lib/features/manager/presentation/manager_shell.dart
FILE: lib/features/manager/dashboard/data/datasources/manager_dashboard_remote_data_source.dart
FILE: lib/features/farmers/data/datasources/farmer_remote_data_source.dart
FILE: lib/features/farmers/presentation/screens/farmer_screen.dart
FILE: lib/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart
FILE: lib/features/farm_visits/presentation/screens/farm_visit_screen.dart
FILE: lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart
FILE: lib/features/grain_sales/presentation/screens/grain_sale_screen.dart
FILE: lib/features/booking_slot/data/datasources/booking_remote_data_source.dart
FILE: lib/features/booking_slot/presentation/screens/booking_slot_screen.dart
FILE: lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart
FILE: lib/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart
FILE: lib/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart
FILE: lib/features/seed_purchase/presentation/screens/seed_purchase_screen.dart

Flutter placeholder reservations (navigation destination exists, no screen):

FILE: lib/features/warehouse/data/.gitkeep
FILE: lib/features/billing/presentation/.gitkeep
FILE: lib/features/market_rates/presentation/.gitkeep
FILE: lib/features/reports/presentation/.gitkeep
FILE: lib/features/event_logs/presentation/.gitkeep
FILE: lib/features/managers/presentation/.gitkeep
FILE: lib/features/notifications/presentation/.gitkeep
FILE: lib/features/profile/presentation/.gitkeep
FILE: lib/features/credits/presentation/.gitkeep
FILE: lib/features/cache/presentation/.gitkeep

Automated tests that pin the Flutter behaviour:

FILE: test/features/auth/auth_controller_test.dart
FILE: test/features/farmers/farmer_test.dart

## Workflow mapping

Each row pairs a React journey with the Flutter equivalent and the contract routes behind them. Endpoints named inside a table cell are restated as formal `API:` citations in the index that follows the tables, so every route mentioned anywhere in this document is checkable.

### A. Authentication, OTP and account

| React workflow / route | Flutter screen or placeholder | Backend endpoint(s) in `openapi_dump.json` | Verdict |
| --- | --- | --- | --- |
| `/login` phone+password, role redirect — `agriflow/agriflow-web/src/pages/auth/Login.jsx`, executed through Supabase `auth-api`, not FastAPI | `LoginScreen` drives `AuthController.login` — `lib/features/auth/presentation/screens/login_screen.dart`, `lib/features/auth/data/datasources/auth_remote_data_source.dart` | `POST /api/v1/auth/login`, `GET /api/v1/users/me`, `POST /api/v1/auth/refresh`, `POST /api/v1/auth/logout` | **partial** — Flutter is contract-true; React bypasses the contract entirely |
| Session restore, refresh on 401, logout | `AuthRepositoryImpl.restoreSession` is the only refresh site in `lib/` | `GET /api/v1/users/me`, `POST /api/v1/auth/refresh`, `POST /api/v1/auth/logout` | **partial** — Flutter refreshes only during restore, never inside a shell |
| `/forgot-password` OTP reset — `agriflow/agriflow-web/src/pages/auth/ForgotPassword.jsx` (Supabase `resetPasswordForEmail`) | `ForgotPasswordScreen` two-step send then reset — `lib/features/auth/presentation/screens/forgot_password_screen.dart` | `POST /api/v1/auth/forgot-password/send-otp`, `POST /api/v1/auth/forgot-password/reset` | **partial** — Flutter matches the contract; React does not use it |
| Login OTP / one-time-code sign-in | no screen anywhere in `lib/` | `POST /api/v1/auth/send-otp`, `POST /api/v1/auth/verify-otp` | **gap** — routes exist, neither client implements them (`authService.verifyOtp` throws) |
| Forced password change on `first_login`, profile password change — `agriflow/agriflow-web/src/pages/admin/ManagerProfile.jsx` | no screen; `first_login` is parsed at `lib/features/auth/domain/entities/auth_user.dart` but never acted on | `POST /api/v1/auth/change-password` | **gap** — route exists, neither client calls it |
| Profile and settings self-service | `account` and `settings` destinations fall through to `ModulePlaceholderScreen` (`lib/core/widgets/module_placeholder_screen.dart`) | `GET /api/v1/users/me`, `PATCH /api/v1/users/me` | **gap on Flutter**, React uses Supabase instead of the contract |

### B. Dashboard, farmers, visits, grain and bookings

| React workflow / route | Flutter screen or placeholder | Backend endpoint(s) in `openapi_dump.json` | Verdict |
| --- | --- | --- | --- |
| Manager dashboard — `agriflow/agriflow-web/src/pages/admin/Dashboard.jsx` (Supabase RPC) | `AdminDashboardView` / `ManagerDashboardView` fed by `lib/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart` and `lib/features/manager/dashboard/data/datasources/manager_dashboard_remote_data_source.dart` | `GET /api/v1/admin/dashboard`, `GET /api/v1/admin/reports/monthly`, `GET /api/v1/admin/audit-logs`, `GET /api/v1/public/market-rates`, `GET /api/v1/farm-visits`, `GET /api/v1/warehouses`, `GET /api/v1/notifications` | **partial** — Flutter consumes the contract but labels month-to-date revenue as "today"; React bypasses it |
| Farmer directory, detail, approve/reject/suspend — `agriflow/agriflow-web/src/pages/admin/Farmers.jsx` | `lib/features/farmers/presentation/screens/farmer_screen.dart` with detail, add and bank-request sheets | `GET /api/v1/farmers`, `POST /api/v1/farmers`, `GET /api/v1/farmers/{farmer_id}`, `PATCH /api/v1/farmers/{farmer_id}/approval` | **partial** — Flutter parity except the detail route is never invoked from the UI, and React additionally offers a delete the contract has no route for |
| Bank change request review | `bank_change_requests_sheet.dart`, page 1 only, no load-more | `GET /api/v1/farmers/bank-change-requests`, `PATCH /api/v1/farmers/bank-change-requests/{request_id}` | **partial** — contract parity, client-side pagination missing |
| Farm visit schedule / reschedule / complete — `agriflow/agriflow-web/src/pages/admin/FarmVisits.jsx` (plus nominatim geocoding) | `lib/features/farm_visits/presentation/screens/farm_visit_screen.dart` | `GET /api/v1/farm-visits`, `POST /api/v1/farm-visits`, `PATCH /api/v1/farm-visits/{visit_id}/schedule`, `PATCH /api/v1/farm-visits/{visit_id}/complete`, `GET /api/v1/crops/active`, `GET /api/v1/managers` | **partial** — Flutter `createVisit` has no screen caller; neither client sends visit reminders |
| Visit reminders | none | `POST /api/v1/farm-visits/reminders` | **gap** — route exists, no client call site in either app |
| Crop procurement / log received crop — `agriflow/agriflow-web/src/pages/admin/GrainProcurement.jsx` and `GrainSalesAdmin.jsx` | `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart` + `log_received_crop_sheet.dart` | `GET /api/v1/grain-sales`, `POST /api/v1/grain-sales/procure`, `PATCH /api/v1/grain-sales/{sale_id}/pay` | **partial** — list, procure and pay reach the contract on the Flutter side |
| Grain sale review and yield update | none — no data source method exists | `PATCH /api/v1/grain-sales/{sale_id}/review`, `PATCH /api/v1/grain-sales/{sale_id}/yield` | **gap** — routes exist, neither client calls them |
| Manual grain sale creation | none | `POST /api/v1/grain-sales` | **gap** — route exists, no client call site |
| Booking approval queue — `agriflow/agriflow-web/src/pages/admin/BookingSlots.jsx` (sends `confirmed`, which the Supabase RPC rejects) | `lib/features/booking_slot/presentation/screens/booking_slot_screen.dart` | `GET /api/v1/bookings`, `PATCH /api/v1/bookings/{booking_id}/status` | **partial** — Flutter sends `confirmed`/`cancelled`; date filtering is client-side only because the list route documents no date parameter |
| Booking creation and inspection | creation exists only on the farmer portal side of the contract; no inspection UI | `POST /api/v1/bookings`, `POST /api/v1/bookings/{booking_id}/inspect` | **gap** — inspection route exists, no client call site in either app |

### C. Catalogues, logistics, money and secondary modules

| React workflow / route | Flutter screen or placeholder | Backend endpoint(s) in `openapi_dump.json` | Verdict |
| --- | --- | --- | --- |
| Seed CRUD with image upload and warehouse multi-select — `agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx` | `lib/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart` — full CRUD | `GET /api/v1/seeds`, `POST /api/v1/seeds`, `PATCH /api/v1/seeds/{seed_id}`, `DELETE /api/v1/seeds/{seed_id}`, `POST /api/v1/uploads` | **parity** on CRUD; **partial** overall — no warehouse assignment, no grade pricing, no on-hold stock in the contract |
| Seed purchase approval queue and invoice — `agriflow/agriflow-web/src/pages/admin/SeedPurchases.jsx` | `lib/features/seed_purchase/presentation/screens/seed_purchase_screen.dart` | `GET /api/v1/seed-purchases`, `PATCH /api/v1/seed-purchases/{purchase_id}/status` | **partial** — React downloads an invoice HTML file, Flutter only shows the invoice number; grade, warehouse and pickup fields are absent from `SeedPurchasePublic` |
| Seed purchase checkout (farmer buys seed) | not in scope for the admin app | `POST /api/v1/seed-purchases` | **gap** for the Flutter app (farmer portal scope); route exists and is unused by both reviewed clients |
| Warehouse utilisation, inventory add, slot creation — `agriflow/agriflow-web/src/pages/admin/Warehouse.jsx` | `lib/features/warehouse/data/.gitkeep` → `ModulePlaceholderScreen` | `GET /api/v1/warehouses`, `POST /api/v1/warehouses`, `POST /api/v1/warehouses/{warehouse_id}/inventory`, `GET /api/v1/warehouses/{warehouse_id}/slots`, `GET /api/v1/warehouse-slots`, `POST /api/v1/warehouse-slots`, `PATCH /api/v1/warehouse-slots/{slot_id}` | **gap on Flutter** — seven routes exist and only `GET /warehouses` is used (as a name lookup) |
| Market rate publishing, edit, delete — `agriflow/agriflow-web/src/pages/admin/MarketRates.jsx` | `lib/features/market_rates/presentation/.gitkeep`; only the mandi strip reads public rates | `GET /api/v1/market-rates`, `POST /api/v1/market-rates`, `GET /api/v1/public/market-rates` | **gap on Flutter screen**, **partial on contract** — rate edit and delete have no route |
| Billing and invoice creation — `agriflow/agriflow-web/src/pages/admin/Billing.jsx` | `lib/features/billing/presentation/.gitkeep` | `GET /api/v1/transactions`, `PATCH /api/v1/transactions/{transaction_id}/pay` | **gap** — Flutter has no screen, and React *creates* ledger rows the contract cannot accept |
| Credit/debit ledger — `agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx` | `lib/features/credits/presentation/.gitkeep` | none | **gap on all three sides** |
| Farmer transaction statement — `agriflow/agriflow-web/src/pages/farmer/TransactionHistory.jsx` | no transactions feature in `lib/` | `GET /api/v1/transactions`, `PATCH /api/v1/transactions/{transaction_id}/pay` | **gap on Flutter** (and the page itself sits in the farmer portal, out of Flutter scope) |
| Notification centre with inline approve/reject — `agriflow/agriflow-web/src/components/shared/NotificationCenter.jsx` | `lib/features/notifications/presentation/.gitkeep`; the manager dashboard fetches the list but renders no centre | `GET /api/v1/notifications`, `PATCH /api/v1/notifications/{notification_id}/read`, `PATCH /api/v1/notifications/read-all` | **partial** — routes exist, Flutter has no screen and hardcodes unread badges to zero |
| Reports with date range and PDF export — `agriflow/agriflow-web/src/pages/admin/Reports.jsx` | `lib/features/reports/presentation/.gitkeep`; the admin dashboard issues six sequential monthly calls instead | `GET /api/v1/admin/reports/monthly` | **partial** — server aggregation exists, React aggregates client-side, Flutter has no report screen and no export |
| Audit / event log viewer — `agriflow/agriflow-web/src/pages/admin/EventLogs.jsx` | `lib/features/event_logs/presentation/.gitkeep`; admin dashboard shows five recent rows only | `GET /api/v1/admin/audit-logs`, `GET /api/v1/events/stream`, `POST /api/v1/events/ticket` | **gap on Flutter screen** |
| Manager create / activate / reset password — `agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx` | `lib/features/managers/presentation/.gitkeep` | `GET /api/v1/managers`, `POST /api/v1/managers`, `PATCH /api/v1/managers/{manager_id}/status`, `POST /api/v1/managers/{manager_id}/reset-password` | **gap on Flutter screen**, **partial on contract** — manager profile editing has no route |
| React Query cache inspector — `agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx` and the cache destination | `lib/features/cache/presentation/.gitkeep` | none | **gap on all three sides** |
| Public landing, market rates and seed catalogue pages | no public surface (the Flutter app is auth-only) | `GET /api/v1/public/market-rates`, `GET /api/v1/public/seeds`, `GET /api/v1/public/stats` | **out of Flutter scope** — React exists but reads Supabase `publicService`, not these routes |
| Farmer portal (crops, profile, seed purchase, booking, notifications) | `UnsupportedRoleScreen` for `farmer` — `lib/features/auth/presentation/screens/login_screen.dart` role gate | `POST /api/v1/farmer/auth/login`, `GET /api/v1/farmer/dashboard` | **out of Flutter scope** by design; noted so the omission is not mistaken for a defect |

### Endpoint citation index

Formal citations for every route named above (each verified against `openapi_dump.json`):

API: POST /api/v1/auth/login
API: POST /api/v1/auth/refresh
API: POST /api/v1/auth/logout
API: POST /api/v1/auth/send-otp
API: POST /api/v1/auth/verify-otp
API: POST /api/v1/auth/change-password
API: POST /api/v1/auth/forgot-password/send-otp
API: POST /api/v1/auth/forgot-password/reset
API: GET /api/v1/users/me
API: PATCH /api/v1/users/me
API: GET /api/v1/admin/dashboard
API: GET /api/v1/admin/reports/monthly
API: GET /api/v1/admin/audit-logs
API: GET /api/v1/events/stream
API: POST /api/v1/events/ticket
API: GET /api/v1/farmers
API: POST /api/v1/farmers
API: GET /api/v1/farmers/{farmer_id}
API: PATCH /api/v1/farmers/{farmer_id}/approval
API: GET /api/v1/farmers/bank-change-requests
API: PATCH /api/v1/farmers/bank-change-requests/{request_id}
API: GET /api/v1/farm-visits
API: POST /api/v1/farm-visits
API: PATCH /api/v1/farm-visits/{visit_id}/schedule
API: PATCH /api/v1/farm-visits/{visit_id}/complete
API: POST /api/v1/farm-visits/reminders
API: GET /api/v1/crops
API: GET /api/v1/crops/active
API: GET /api/v1/grain-sales
API: POST /api/v1/grain-sales
API: POST /api/v1/grain-sales/procure
API: PATCH /api/v1/grain-sales/{sale_id}/review
API: PATCH /api/v1/grain-sales/{sale_id}/pay
API: PATCH /api/v1/grain-sales/{sale_id}/yield
API: GET /api/v1/bookings
API: POST /api/v1/bookings
API: PATCH /api/v1/bookings/{booking_id}/status
API: POST /api/v1/bookings/{booking_id}/inspect
API: GET /api/v1/seeds
API: POST /api/v1/seeds
API: PATCH /api/v1/seeds/{seed_id}
API: DELETE /api/v1/seeds/{seed_id}
API: GET /api/v1/seed-purchases
API: POST /api/v1/seed-purchases
API: PATCH /api/v1/seed-purchases/{purchase_id}/status
API: GET /api/v1/warehouses
API: POST /api/v1/warehouses
API: POST /api/v1/warehouses/{warehouse_id}/inventory
API: GET /api/v1/warehouses/{warehouse_id}/slots
API: GET /api/v1/warehouse-slots
API: POST /api/v1/warehouse-slots
API: PATCH /api/v1/warehouse-slots/{slot_id}
API: GET /api/v1/market-rates
API: POST /api/v1/market-rates
API: GET /api/v1/public/market-rates
API: GET /api/v1/public/seeds
API: GET /api/v1/public/stats
API: GET /api/v1/transactions
API: PATCH /api/v1/transactions/{transaction_id}/pay
API: GET /api/v1/notifications
API: PATCH /api/v1/notifications/{notification_id}/read
API: PATCH /api/v1/notifications/read-all
API: GET /api/v1/managers
API: POST /api/v1/managers
API: PATCH /api/v1/managers/{manager_id}/status
API: POST /api/v1/managers/{manager_id}/reset-password
API: POST /api/v1/uploads
API: POST /api/v1/farmer/auth/login
API: GET /api/v1/farmer/dashboard

## Parity gaps

### Where Flutter has no equivalent of a React workflow

1. **Warehouse management.** React has a full warehouse screen with capacity bars, inventory entry and slot creation (`agriflow/agriflow-web/src/pages/admin/Warehouse.jsx`); Flutter reserves the destination `warehouse` in `lib/core/navigation/nav_destination.dart` but renders `ModulePlaceholderScreen` (`lib/core/widgets/module_placeholder_screen.dart`) from a directory that contains only `lib/features/warehouse/data/.gitkeep`. The contract offers seven warehouse and slot routes and the Flutter app touches exactly one of them, as a name lookup from the booking feature (`lib/features/booking_slot/data/datasources/booking_remote_data_source.dart`).
2. **Market rate administration.** React has a grade-rate board with bulk create, edit and delete (`agriflow/agriflow-web/src/pages/admin/MarketRates.jsx`); Flutter only renders a read-only mandi strip fed by the public route, with `lib/features/market_rates/presentation/.gitkeep` holding the screen slot open.
3. **Billing, credits and transactions.** React has Billing and CreditsAdmin; Flutter has `lib/features/billing/presentation/.gitkeep` and `lib/features/credits/presentation/.gitkeep` and no transaction feature at all.
4. **Reports and audit logs as screens.** React has dedicated report and event-log pages; Flutter has `lib/features/reports/presentation/.gitkeep` and `lib/features/event_logs/presentation/.gitkeep`. The Flutter admin dashboard does read `GET /api/v1/admin/reports/monthly` and `GET /api/v1/admin/audit-logs`, but only for a chart and five recent rows — there is no place to pick a date range, switch report type or export.
5. **Manager administration.** React can create, edit and activate managers (`agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx`); Flutter has `lib/features/managers/presentation/.gitkeep` (and a separate, already-implemented `lib/features/manager/` shell and dashboard, so the placeholder name collides with a live feature).
6. **Notification centre.** React has a bell with 30-second polling and inline actions; Flutter has `lib/features/notifications/presentation/.gitkeep`, fetches notifications only inside the manager dashboard data source, and hardcodes unread badges to zero in both shells.
7. **Profile, account and settings.** React has `ManagerProfile`; Flutter routes the `account` and `settings` destinations to the placeholder from `lib/features/profile/presentation/.gitkeep` despite `GET /api/v1/users/me` and `PATCH /api/v1/users/me` being available.
8. **Invoice download.** React generates and downloads an invoice HTML file from the seed-purchase screen; Flutter displays only the invoice number on `lib/features/seed_purchase/presentation/screens/seed_purchase_screen.dart`. This one needs no backend — the invoice can be rendered client-side.

### Where React has no equivalent of a Flutter workflow

1. **A real HTTP client against the contract.** No file anywhere under `agriflow/agriflow-web` references `/api/v1` or the live host; `agriflow/agriflow-web/package.json` ships no HTTP client. Every contract endpoint cited in this document is consumed by Flutter and by nobody on the React side.
2. **Server-side pagination and filters.** The Flutter farmer, visit, grain-sale, booking, seed-purchase and seeds screens paginate through the documented `page` / `page_size` / `search` / `status` / `sort` / `order` parameters; the React farmer, seed-purchase and grain-sale pages fetch whole tables and filter in memory.
3. **RBAC honoured on seeds.** `AGENTS.md` §3 forbids manager writes to the seed catalogue; Flutter passes `isAdmin: false` for managers (`lib/features/manager/presentation/manager_shell.dart`) while React still renders "Add Seed" to managers (`agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx`).
4. **Confirmation before destructive seed deletion.** Flutter asks before deleting; React relies on `window.confirm`.
5. **A test suite.** `test/features/auth/auth_controller_test.dart`, `test/features/farmers/farmer_test.dart` and fourteen sibling files exist for Flutter; `agriflow/agriflow-web/package.json` defines only `dev`, `build`, `lint`, `preview` — there is no test runner and no test file in the React project.
6. **An unreachable register route and a broken OTP stub.** React's `/register` redirects to `/get-started` and `authService.verifyOtp` throws unconditionally, so two of its own auth journeys are dead in a way Flutter's are not.

### Where the backend has no endpoint at all

These are capabilities that both client sides want and that the 94-path contract simply does not carry: billing and invoice issuance, the credit/debit ledger, market-rate edit and delete, farmer account deletion, manager profile editing, warehouse edit/delete and single-warehouse read, warehouse inventory read-back, warehouse slot deletion, seed grade A/B/C pricing and seed-to-warehouse assignment, on-hold seed stock, server-side "today" aggregates and date-filtered list queries, booking date filtering and slot time on the booking payload, report export in PDF or CSV, cache statistics and cache clearing, staff-side FCM token registration, and free-text search across farmer and seed names on the seed-purchase list. Each of these is itemised in the next section with the required marker.

## Backend API required

Every item below is a capability a reviewed screen needs that `openapi_dump.json` does not expose. Each carries the exact marker sentence, and none is given an `API:` citation, because no such route exists.

1. Billing and invoice creation from an admin screen (`lib/features/billing/presentation/.gitkeep`, `agriflow/agriflow-web/src/pages/admin/Billing.jsx` inserts ledger rows directly today). Backend API required - to be supplied by Syed.
2. Credit/debit ledger entry create and edit (`lib/features/credits/presentation/.gitkeep`, `agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx`). Backend API required - to be supplied by Syed.
3. Market-rate update and delete — the contract carries only list and create (`lib/features/market_rates/presentation/.gitkeep`, `agriflow/agriflow-web/src/pages/admin/MarketRates.jsx`). Backend API required - to be supplied by Syed.
4. Farmer account deletion and cascade (`agriflow/agriflow-web/src/pages/admin/Farmers.jsx` offers it, Flutter does not). Backend API required - to be supplied by Syed.
5. Manager profile editing — name, email and phone; the contract only carries status change and password reset (`agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx`, `lib/features/managers/presentation/.gitkeep`). Backend API required - to be supplied by Syed.
6. Warehouse update, delete and single-warehouse read (`agriflow/agriflow-web/src/pages/admin/Warehouse.jsx`, `lib/features/warehouse/data/.gitkeep`). Backend API required - to be supplied by Syed.
7. Warehouse inventory read-back, so a screen can show what is already stored instead of only appending (`agriflow/agriflow-web/src/pages/admin/Warehouse.jsx`). Backend API required - to be supplied by Syed.
8. Warehouse slot deletion. Backend API required - to be supplied by Syed.
9. Seed grade A/B/C pricing, seed-to-warehouse assignment and `max_order_quantity_kg` on the seed contract (`lib/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart`, `agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx`). Backend API required - to be supplied by Syed.
10. On-hold stock (`on_hold_kg`) on the seed payload, which React renders and Flutter cannot. Backend API required - to be supplied by Syed.
11. Date-scoped dashboard aggregates ("today" counters, delta versus yesterday) and date filters on the list routes — today `lib/features/manager/dashboard/data/datasources/manager_dashboard_remote_data_source.dart` substitutes all-time totals and literal constants. Backend API required - to be supplied by Syed.
12. Booking date filtering server-side, and slot time on the booking payload (`lib/features/booking_slot/presentation/screens/booking_slot_screen.dart`). Backend API required - to be supplied by Syed.
13. Report export as PDF or CSV, and a single range-based report endpoint to replace the six sequential monthly calls issued by `lib/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart`. Backend API required - to be supplied by Syed.
14. Cache statistics and cache clearing endpoints (`lib/features/cache/presentation/.gitkeep`, `agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx` cache destination). Backend API required - to be supplied by Syed.
15. Staff-side FCM token registration and push delivery for the admin/manager app — only farmer-scoped FCM routes exist in the contract (`lib/features/notifications/presentation/.gitkeep`). Backend API required - to be supplied by Syed.
16. Search across farmer name, seed name and invoice number on the seed-purchase list (`lib/features/seed_purchase/presentation/screens/seed_purchase_screen.dart` promises this in its search hint). Backend API required - to be supplied by Syed.

## Findings

1. **P0 — The two clients do not share a backend, so "workflow parity" is only skin-deep.** The React reference implements every journey through Supabase edge functions and PostgREST (`agriflow/agriflow-web/src/lib/supabase.js`, `agriflow/agriflow-web/src/services/adminService.js`, which passes a client-asserted `callerRole` in the body), while the Flutter product implements the same journeys against the FastAPI contract (`lib/features/auth/data/datasources/auth_remote_data_source.dart`, `lib/features/farmers/data/datasources/farmer_remote_data_source.dart`). `agriflow/agriflow-web/package.json` has no HTTP client. Consequence: the contract endpoints cited in this document are consumed by exactly one of the two reviewed applications, and no automated test in either project can detect drift between Supabase and FastAPI.

2. **P0 — Twelve of nineteen Flutter navigation destinations are placeholders.** `lib/core/navigation/nav_destination.dart` defines `warehouse`, `billing`, `market-rates`, `reports`, `event-logs`, `managers`, `credits`, `cache-management`, `notifications`, `account`, `settings` and `help`; `lib/features/admin/presentation/admin_shell.dart` and `lib/features/manager/presentation/manager_shell.dart` route all of them to `ModulePlaceholderScreen` (`lib/core/widgets/module_placeholder_screen.dart`), backed only by `.gitkeep` reservations such as `lib/features/warehouse/data/.gitkeep` and `lib/features/reports/presentation/.gitkeep`. For at least seven of those the contract already has usable routes (`API: GET /api/v1/warehouses`, `API: GET /api/v1/market-rates`, `API: GET /api/v1/managers`, `API: GET /api/v1/admin/audit-logs`, `API: GET /api/v1/admin/reports/monthly`, `API: GET /api/v1/notifications`, `API: GET /api/v1/users/me`), so these are client gaps, not backend gaps.

3. **P0 — Money movement cannot be expressed through the contract.** React writes billing rows and credit-ledger entries straight into Supabase tables (`agriflow/agriflow-web/src/pages/admin/Billing.jsx`, `agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx`), while the contract only offers read and mark-paid operations (`API: GET /api/v1/transactions`, `API: PATCH /api/v1/transactions/{transaction_id}/pay`). Neither Flutter nor the contract can create a transaction. Backend API required - to be supplied by Syed.

4. **P1 — Four contract operations have no call site in either client.** `API: POST /api/v1/farm-visits/reminders`, `API: PATCH /api/v1/grain-sales/{sale_id}/review`, `API: PATCH /api/v1/grain-sales/{sale_id}/yield` and `API: POST /api/v1/bookings/{booking_id}/inspect` are all documented in `openapi_dump.json` and referenced by no data source in `lib/` (`lib/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart`, `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart`, `lib/features/booking_slot/data/datasources/booking_remote_data_source.dart` stop short of them) and by no React page. This is wasted contract surface: review, yield, inspection and reminders are simply not part of the shipped product.

5. **P1 — Password change and OTP sign-in exist in the contract and are unused by both clients.** `API: POST /api/v1/auth/change-password` has no caller; Flutter parses `first_login` at `lib/features/auth/domain/entities/auth_user.dart` and never forces a change; React's `changePassword` in `agriflow/agriflow-web/src/services/authService.js` accepts an old password and never verifies it. `API: POST /api/v1/auth/send-otp` and `API: POST /api/v1/auth/verify-otp` have no caller either — React's `verifyOtp` throws unconditionally and Flutter only implements the forgot-password pair (`lib/features/auth/presentation/screens/forgot_password_screen.dart`).

6. **P1 — Warehouse is a three-sided hole.** React ships a warehouse screen (`agriflow/agriflow-web/src/pages/admin/Warehouse.jsx`), Flutter ships a placeholder (`lib/features/warehouse/data/.gitkeep`), and the contract can create warehouses, append inventory and create slots (`API: GET /api/v1/warehouses`, `API: POST /api/v1/warehouses`, `API: POST /api/v1/warehouses/{warehouse_id}/inventory`, `API: GET /api/v1/warehouses/{warehouse_id}/slots`, `API: GET /api/v1/warehouse-slots`, `API: POST /api/v1/warehouse-slots`, `API: PATCH /api/v1/warehouse-slots/{slot_id}`) but cannot edit, delete or read back inventory for a single warehouse. Backend API required - to be supplied by Syed.

7. **P1 — Manager administration is unreachable in the product.** The four manager routes exist (`API: GET /api/v1/managers`, `API: POST /api/v1/managers`, `API: PATCH /api/v1/managers/{manager_id}/status`, `API: POST /api/v1/managers/{manager_id}/reset-password`) and React drives an equivalent screen (`agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx`), but Flutter's `lib/features/managers/presentation/.gitkeep` leaves the admin-only `managers` destination on `ModulePlaceholderScreen`. The only Flutter code that touches `GET /api/v1/managers` is a staff-name lookup inside the farm-visit data source.

8. **P1 — Dashboard "today" numbers are not today.** Because the list routes expose no date parameter, `lib/features/manager/dashboard/data/datasources/manager_dashboard_remote_data_source.dart` labels all-time totals, first-page counts and two hardcoded constants as today's figures, and reads month-to-date revenue from `API: GET /api/v1/admin/dashboard` while labelling it "Today's Revenue". React's equivalent (`agriflow/agriflow-web/src/pages/admin/Dashboard.jsx`) avoids this only by reading a Supabase RPC instead. Backend API required - to be supplied by Syed.

9. **P2 — Notifications are half-integrated.** All three routes exist (`API: GET /api/v1/notifications`, `API: PATCH /api/v1/notifications/{notification_id}/read`, `API: PATCH /api/v1/notifications/read-all`), React has a working bell (`agriflow/agriflow-web/src/components/shared/NotificationCenter.jsx`), and Flutter consumes only the read side inside `lib/features/manager/dashboard/data/datasources/manager_dashboard_remote_data_source.dart` while `lib/features/notifications/presentation/.gitkeep` holds the screen slot and both shells hardcode `unreadNotifications: 0` (`lib/features/admin/presentation/admin_shell.dart`, `lib/features/manager/presentation/manager_shell.dart`).

10. **P2 — Reporting and audit viewing are split across all three sides.** React aggregates reports client-side and exports a PDF from `agriflow/agriflow-web/src/pages/admin/Reports.jsx` without ever using `API: GET /api/v1/admin/reports/monthly`; Flutter calls that same route six times sequentially for a chart but has no report screen (`lib/features/reports/presentation/.gitkeep`); audit logs are viewed in React at `agriflow/agriflow-web/src/pages/admin/EventLogs.jsx` and in Flutter only as five recent rows against `API: GET /api/v1/admin/audit-logs`, with `lib/features/event_logs/presentation/.gitkeep` empty.

11. **P2 — Self-service profile editing is a Flutter gap against an existing contract.** `API: GET /api/v1/users/me` and `API: PATCH /api/v1/users/me` are available and are already read during session restore, yet `account` and `settings` render `ModulePlaceholderScreen` from `lib/features/profile/presentation/.gitkeep`, and React's profile edits go to Supabase instead (`agriflow/agriflow-web/src/pages/admin/ManagerProfile.jsx`).

12. **P2 — Two client journeys the contract fully supports are still incomplete on the Flutter side.** The farmer detail route `API: GET /api/v1/farmers/{farmer_id}` is implemented in `lib/features/farmers/data/datasources/farmer_remote_data_source.dart` but never invoked from `lib/features/farmers/presentation/screens/farmer_screen.dart`, so the detail sheet renders the list snapshot; and `POST /api/v1/farmers` is reachable while farm-visit creation (`API: POST /api/v1/farm-visits`) has a controller action with no screen caller (`lib/features/farm_visits/presentation/screens/farm_visit_screen.dart`).

13. **P3 — Credits and cache are pure placeholders with no contract at all.** `lib/features/credits/presentation/.gitkeep` and `lib/features/cache/presentation/.gitkeep` mirror React screens (`agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx`) whose backing data lives only in Supabase. Backend API required - to be supplied by Syed.

14. **P3 — The farmer portal and public site exist in the contract but are deliberately out of Flutter scope.** `API: POST /api/v1/farmer/auth/login` and `API: GET /api/v1/farmer/dashboard` head a 25-route farmer surface, and `API: GET /api/v1/public/market-rates`, `API: GET /api/v1/public/seeds` and `API: GET /api/v1/public/stats` back React's marketing pages; the Flutter app rejects the `farmer` role at `lib/features/auth/presentation/screens/login_screen.dart`. This is a scope decision, not a defect, but it means the app cannot be validated as a single-client replacement for the website.

## Recommendations

**P0 — resolve the backend identity question first (finding 1).**

1. Decide which backend each client is allowed to use, and record it in `AGENTS.md`: either migrate the React site onto the FastAPI routes cited in this document, or declare the FastAPI contract Flutter-only and add a contract test that asserts Supabase and FastAPI expose the same fields. Until one of those happens, every parity verdict above is provisional.
2. Close the money gaps before any billing UI is built (finding 3): transaction create, ledger entry create/edit, and billing invoice issuance. Backend API required - to be supplied by Syed.

**P0 — replace placeholders that already have routes (finding 2).**

3. Implement `warehouse`, `market-rates`, `managers`, `notifications`, `reports`, `event-logs` and `account`/`settings` in Flutter against the routes already cited above; these seven need no backend work and would remove the largest parity gap in one pass.

**P1 — use the contract that already exists (findings 4, 5, 12).**

4. Add data source methods, controller actions and UI entry points for visit reminders, grain-sale review, grain-sale yield and booking inspection, then wire `loadFarmerDetail` when the farmer sheet opens and give farm-visit creation a screen.
5. Implement forced password change on `first_login` using the existing change-password route, and decide whether login OTP is a product requirement; if it is, implement send and verify against the existing routes rather than leaving React's throwing stub in place.

**P1 — chase the remaining contract deltas with Syed (findings 6, 7, 8).**

6. Warehouse edit/delete and inventory read-back, manager profile editing, and date-scoped dashboard aggregates are the four highest-value pending contracts; track them with the exact marker sentence used in `## Backend API required` until they land.

**P2 — finish the half-built journeys (findings 9, 10, 11).**

7. Build the notification centre and feed its unread count into the drawer badges that are currently hardcoded to zero.
8. Give reports a real screen with a date range and client-side export (no backend needed), and let event logs render the full audit list rather than five rows.
9. Build `account`/`settings` on `GET /api/v1/users/me` and `PATCH /api/v1/users/me` including password change.

**P3 — hygiene (findings 13, 14).**

10. Either populate or delete the `credits` and `cache` reservations so navigation stops advertising modules that cannot exist.
11. Keep the farmer-portal and public-surface omissions explicitly documented as out of scope so no future review reports them as regressions.

## Appendix — method notes

Structure, citation and API checks were run against this file with the repository's own scripts: `check-report.mjs` (required sections plus word floor), `check-coverage.mjs --citations-only` (`FILE:` path existence and count) and `check-api-refs.mjs` (`API:` lines resolved against `openapi_dump.json`, with a positive control that rejects an invented path). The three checks together are what make this document auditable rather than merely plausible: a citation that does not resolve, or a route that is not in the dump, fails the gate instead of being believed.
