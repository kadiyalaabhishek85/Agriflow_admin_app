# React Web Portal — UI Layer, Routes, Screens and Workflows (leaf-1.3.1)

## Scope

This review covers every file under `agriflow/agriflow-web/src` (72 files: pages, layouts, router, components, context, hooks, services wiring, i18n, styles and static assets). It was performed read-only against the source, not against filenames: route guards, role layouts, page actions and service calls were reconstructed from the code with `file:line` evidence.

Ground truth for every backend claim is the local OpenAPI cache `openapi_dump.json` (94 paths on `https://agriflow-backend-t8o4.onrender.com`). Endpoints named in this document are cited as `API: <METHOD> <path>` and exist in that schema. Capabilities the UI needs that the FastAPI contract does not expose are marked with the exact marker `Backend API required - to be supplied by Syed.` No endpoint, payload or business rule is invented here.

The single most important architectural fact of this codebase: the React app never calls the FastAPI backend. Every data path goes to Supabase — direct table/RPC queries (`src/lib/supabase.js:6`), Supabase edge functions (`auth-api`, `admin-api`, `manager-api`, `farmer-api`, `admin-create-user`), and Supabase storage. The only `fetch()` in the whole `src` tree is a third-party OpenStreetMap nominatim geocode call at `agriflow/agriflow-web/src/pages/admin/FarmVisits.jsx:150`. Stack: Vite + React 18 + React Router v6 + TanStack Query (defaults set in `src/main.jsx:14-25`) + Tailwind (`src/index.css:1-3`) + i18next (`src/index/index.js:1-3`).

## Files reviewed

FILE: agriflow/agriflow-web/src/App.css
Vite scaffold stylesheet; never imported anywhere, dead.

FILE: agriflow/agriflow-web/src/App.jsx
Root component: index.css + i18n import (`App.jsx:1-2`), BrowserRouter, AuthProvider, ScrollToTop, Toaster, AppRouter.

FILE: agriflow/agriflow-web/src/app/router/AppRouter.jsx
All routes, lazy imports and role guards (`AppRouter.jsx:62-134`).

FILE: agriflow/agriflow-web/src/app/router/ProtectedRoute.jsx
Client-side guard: no user → /login, wrong role → / (`ProtectedRoute.jsx:4-9`).

FILE: agriflow/agriflow-web/src/assets/react.svg
Vite scaffold logo, never referenced, dead.

FILE: agriflow/agriflow-web/src/components/RateLimitStatus.jsx
Rate-limit status widget, never imported by any page, dead.

FILE: agriflow/agriflow-web/src/components/shared/FieldError.jsx
Inline aria-associated field error used by auth, farmers, warehouse, manage-admins forms.

FILE: agriflow/agriflow-web/src/components/shared/LiveMarketRatesWidget.jsx
Floating rates widget polling every 30s (`LiveMarketRatesWidget.jsx:9-13`), mounted in AdminLayout only.

FILE: agriflow/agriflow-web/src/components/shared/LoadingSpinner.jsx
Leaf spinner used as Suspense fallback (`AppRouter.jsx:61`).

FILE: agriflow/agriflow-web/src/components/shared/NotificationCenter.jsx
Notification bell: 30s poll, optimistic read-marking, inline approve/reject actions (`NotificationCenter.jsx:17-52,65-70`).

FILE: agriflow/agriflow-web/src/components/shared/ScrollToTop.jsx
Resets window and inner-main scroll on route change (`ScrollToTop.jsx:11-14`).

FILE: agriflow/agriflow-web/src/context/AuthContext.jsx
Session restore from Supabase, sessionStorage user cache, login/logout, farmer profile load (`AuthContext.jsx:8-16,78-131`).

FILE: agriflow/agriflow-web/src/hooks/useRateLimit.js
Rate-limit hook; only used by the dead RateLimitStatus component.

FILE: agriflow/agriflow-web/src/index.css
Tailwind entry, design tokens, glass-card/btn/input component classes (221 lines).

FILE: agriflow/agriflow-web/src/index/index.js
i18next setup with en/te/hi dictionaries (890 lines), imported for side effects at `App.jsx:2`.

FILE: agriflow/agriflow-web/src/layouts/AdminLayout.jsx
Manager/super-admin portal shell; role-filtered sidebar, header, mobile bottom nav, rates widget.

FILE: agriflow/agriflow-web/src/layouts/FarmerLayout.jsx
Farmer portal shell with role-gated nav and bottom bar.

FILE: agriflow/agriflow-web/src/layouts/SuperAdminLayout.jsx
Super-admin control-panel shell; three nav sections plus op portal (`SuperAdminLayout.jsx:30-58`).

FILE: agriflow/agriflow-web/src/lib/queryConfig.js
CACHE_TIMES presets (REALTIME/SHORT/MEDIUM/LONG) used to respect Supabase free-tier quota.

FILE: agriflow/agriflow-web/src/lib/supabase.js
Supabase client from VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY.

FILE: agriflow/agriflow-web/src/main.jsx
React root, QueryClient defaults (staleTime 60s, no blanket polling, retry 1).

FILE: agriflow/agriflow-web/src/pages/admin/Billing.jsx
Billing/invoice creation; direct `transactions` table inserts (`Billing.jsx:74-88`).

FILE: agriflow/agriflow-web/src/pages/admin/BookingSlots.jsx
Booking approval queue with search/filter tabs and approve/reject actions.

FILE: agriflow/agriflow-web/src/pages/admin/CacheManagement.jsx
Client-side React Query cache inspector/clearer, super-admin only.

FILE: agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx
Credit/debit ledger with add/edit entry modal (`CreditsAdmin.jsx:65-90`).

FILE: agriflow/agriflow-web/src/pages/admin/Dashboard.jsx
Manager operational dashboard: stat cards, recent activity, quick actions.

FILE: agriflow/agriflow-web/src/pages/admin/EventLogs.jsx
Audit log viewer with HTML report export (`EventLogs.jsx:13-34,36-54`).

FILE: agriflow/agriflow-web/src/pages/admin/Farmers.jsx
Farmer directory: search, status tabs, detail panel, approve/reject/delete, register modal.

FILE: agriflow/agriflow-web/src/pages/admin/FarmVisits.jsx
Visit scheduler: list, date reschedule, complete with photo, add-visit modal, geocode (737 lines).

FILE: agriflow/agriflow-web/src/pages/admin/GrainProcurement.jsx
Approved-booking intake: received qty, moisture, quality, procurement submit (`GrainProcurement.jsx:60-85`).

FILE: agriflow/agriflow-web/src/pages/admin/GrainSalesAdmin.jsx
Crop procurement log modal and sales list with received/paid filters.

FILE: agriflow/agriflow-web/src/pages/admin/ManagerProfile.jsx
Self-service profile edit and password change for manager/super admin.

FILE: agriflow/agriflow-web/src/pages/admin/MarketRates.jsx
Grade rate cards with bulk A/B/C create modal, edit/delete for super admin.

FILE: agriflow/agriflow-web/src/pages/admin/Reports.jsx
Eight report types filtered client-side by date range, jsPDF export (`Reports.jsx:26-35,93-120`).

FILE: agriflow/agriflow-web/src/pages/admin/SeedPurchases.jsx
Purchase approval queue plus generated HTML invoice download (`SeedPurchases.jsx:35-81`).

FILE: agriflow/agriflow-web/src/pages/admin/SeedsInventory.jsx
Seed CRUD with image upload, warehouse multi-select, stock in quintals (`SeedsInventory.jsx:61-95`).

FILE: agriflow/agriflow-web/src/pages/admin/Warehouse.jsx
Warehouse cards with utilisation bars, inventory panel, slot creation modals (`Warehouse.jsx:66-120`).

FILE: agriflow/agriflow-web/src/pages/auth/ForgotPassword.jsx
OTP-based password reset flow (send-otp / reset).

FILE: agriflow/agriflow-web/src/pages/auth/GetStarted.jsx
Entry screen routing users to farmer registration or manager login.

FILE: agriflow/agriflow-web/src/pages/auth/Login.jsx
Phone+password login, force-change-password branch, role redirect (`Login.jsx:89-100`).

FILE: agriflow/agriflow-web/src/pages/auth/Register.jsx
Farmer self-registration form; unreachable because /register redirects.

FILE: agriflow/agriflow-web/src/pages/farmer/BookingSlot.jsx
Farmer warehouse/time-slot booking with quantity and slot picker.

FILE: agriflow/agriflow-web/src/pages/farmer/CropManagement.jsx
Farmer crop add/edit list backed by farmerService crops RPC.

FILE: agriflow/agriflow-web/src/pages/farmer/Dashboard.jsx
Farmer dashboard screen; never imported by any route, dead.

FILE: agriflow/agriflow-web/src/pages/farmer/GrainSales.jsx
Farmer grain-sale request form; lazy-imported at `AppRouter.jsx:28` but never mounted in a route.

FILE: agriflow/agriflow-web/src/pages/farmer/Profile.jsx
Profile edit (personal/bank/agri/docs) plus unused dashboard query (`Profile.jsx:45-50`).

FILE: agriflow/agriflow-web/src/pages/farmer/SeedPurchase.jsx
Seed catalogue purchase, UPI QR (demo), invoice modal, purchase history (742 lines).

FILE: agriflow/agriflow-web/src/pages/farmer/TransactionHistory.jsx
Farmer ledger statement with direction badges and running totals.

FILE: agriflow/agriflow-web/src/pages/public/FeaturesPage.jsx
Static feature marketing page with shared navbar.

FILE: agriflow/agriflow-web/src/pages/public/HowItWorksPage.jsx
Static three-step explainer with shared navbar.

FILE: agriflow/agriflow-web/src/pages/public/LandingPage.jsx
Hero, live rate index, seed showcase, stats, testimonials, footer (640+ lines).

FILE: agriflow/agriflow-web/src/pages/public/MarketRatesPage.jsx
Public grade rate listing from publicService.

FILE: agriflow/agriflow-web/src/pages/public/SeedsCatalogPage.jsx
Public seed catalogue grid with search.

FILE: agriflow/agriflow-web/src/pages/shared/NotFound.jsx
404 page with home link (`AppRouter.jsx:133`).

FILE: agriflow/agriflow-web/src/pages/superadmin/AllFarmers.jsx
Global farmer directory with counts and detail drawer.

FILE: agriflow/agriflow-web/src/pages/superadmin/Dashboard.jsx
System overview stats plus a hardcoded weekly-activity chart (`Dashboard.jsx:36-41`).

FILE: agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx
Manager create/edit/activate modal with validators (`ManageAdmins.jsx:65-89`).

FILE: agriflow/agriflow-web/src/services/adminService.js
admin-api edge function wrapper passing client `callerRole` (`adminService.js:3-16`).

FILE: agriflow/agriflow-web/src/services/authService.js
Login/logout/OTP/change-password wrappers over auth-api.

FILE: agriflow/agriflow-web/src/services/cropService.js
Crop CRUD helper; never imported, dead.

FILE: agriflow/agriflow-web/src/services/farmerService.js
Farmer data access: profile, crops, seeds, bookings, transactions, dashboard.

FILE: agriflow/agriflow-web/src/services/ledgerService.js
Transaction list/create/update over the ledger.

FILE: agriflow/agriflow-web/src/services/managerService.js
manager-api wrapper; identity fields (adminId, role) come from the payload (`managerService.js:3-15`).

FILE: agriflow/agriflow-web/src/services/marketService.js
Market-rate reads plus create/update/delete.

FILE: agriflow/agriflow-web/src/services/notificationService.js
Notification fetch and read-marking.

FILE: agriflow/agriflow-web/src/services/publicService.js
Anonymous catalogue reads for public pages.

FILE: agriflow/agriflow-web/src/services/storageService.js
Supabase storage upload helpers (seed images, visit photos).

FILE: agriflow/agriflow-web/src/services/warehouseService.js
Warehouse, inventory and slot reads/writes.

FILE: agriflow/agriflow-web/src/utils/brandLogo.js
Brand name plus embedded base64 logo for offline invoices/PDFs.

FILE: agriflow/agriflow-web/src/utils/pdfExport.js
jsPDF report builder with branded header, summary and table.

FILE: agriflow/agriflow-web/src/utils/rateLimiter.js
Client rate-limit store; only consumed by the dead hook/component.

FILE: agriflow/agriflow-web/src/utils/validators.js
Field validators (name/phone/email/password/address/acres/warehouse/time) used by auth, farmers, warehouse, manage-admins.

## Findings

**P0 — Role `admin` can log in but has no portal.** `redirectUser` only branches on `super_admin` and `manager`, everything else falls through to `navigate('/farmer')` (`agriflow/agriflow-web/src/pages/auth/Login.jsx:89-100`). The farmer portal accepts only `farmer` (`agriflow/agriflow-web/src/app/router/AppRouter.jsx:75`), so `ProtectedRoute` immediately bounces the user to `/` (`agriflow/agriflow-web/src/app/router/ProtectedRoute.jsx:7`). `/manager/dashboard` allows only `manager, super_admin` (`AppRouter.jsx:86`) and `/admin/dashboard` only `super_admin` (`AppRouter.jsx:107`). Meanwhile `AdminLayout` shows that same `admin` role seventeen nav entries (`agriflow/agriflow-web/src/layouts/AdminLayout.jsx:37-53`). Net effect: an `admin` account authenticates and lands back on the marketing page.

**P0 — Authorization is entirely client-side and identity is client-asserted.** The guard reads the role from React context backed by `sessionStorage` (`ProtectedRoute.jsx:4-9`, `AuthContext.jsx:8-10`). Edge-function calls carry no user JWT — the service comment states `supabase.functions.invoke()` sends the anon key, so the function "cannot decode the user" (`agriflow/agriflow-web/src/services/adminService.js:3-16`); role and actor are supplied in the body (`callerRole`, `adminId`, `adminRole`, e.g. `agriflow/agriflow-web/src/services/managerService.js:13-34`). Every approval, deletion and ledger write therefore trusts whatever the browser claims. The FastAPI contract has real authenticated counterparts — `API: PATCH /api/v1/farmers/{farmer_id}/approval`, `API: PATCH /api/v1/managers/{manager_id}/status`, `API: POST /api/v1/managers/{manager_id}/reset-password` — but this app does not use them.

**P1 — Sidebar links and route guards disagree.** `event-logs` is offered to `admin, super_admin` (`AdminLayout.jsx:50`) while its route allows only `super_admin` (`AppRouter.jsx:100`); same split for `cache` (`AdminLayout.jsx:51` vs `AppRouter.jsx:101`) and the "Super Admin Portal" link (`AdminLayout.jsx:53` vs `AppRouter.jsx:107`) — for role `admin` each renders a link that redirects to the landing page. `${basePath}/procurement` is shown to `admin, super_admin` (`AdminLayout.jsx:43`) but no `procurement` route exists under `/manager/dashboard` (`AppRouter.jsx:94` — "procurement removed for manager"), so it 404s into `NotFound`. Conversely `reports` is hidden from managers in the sidebar (`AdminLayout.jsx:46`) yet the route is reachable with no inner guard (`AppRouter.jsx:92`).

**P1 — Nav duplication in the super-admin shell.** Cache Management appears twice in the same sidebar, once in the super-admin section and again under Settings (`agriflow/agriflow-web/src/layouts/SuperAdminLayout.jsx:37` and `:41`).

**P1 — Mutations with no counterpart in the OpenAPI contract.** The UI writes a billing transaction straight into the `transactions` table with client-chosen `amount` and `direction` (`agriflow/agriflow-web/src/pages/admin/Billing.jsx:74-88`) — the contract only exposes `API: GET /api/v1/transactions` and `API: PATCH /api/v1/transactions/{transaction_id}/pay`. The credit ledger add/edit (`agriflow/agriflow-web/src/pages/admin/CreditsAdmin.jsx:65-90`) has the same problem. Market-rate edit and delete (`agriflow/agriflow-web/src/services/marketService.js` update/delete paths, driven from `agriflow/agriflow-web/src/pages/admin/MarketRates.jsx:29-62`) exceed the contract's `API: GET /api/v1/market-rates` and `API: POST /api/v1/market-rates`. Farmer deletion (`agriflow/agriflow-web/src/pages/admin/Farmers.jsx:94-103`) has no `DELETE /api/v1/farmers/{farmer_id}`. Manager profile updates (`agriflow/agriflow-web/src/pages/superadmin/ManageAdmins.jsx:78-80`) exceed `PATCH .../status` and `POST .../reset-password`. Warehouse edit/delete remain pending per the workspace contract notes. For each of these the correct statement is: `Backend API required - to be supplied by Syed.`

**P1 — Fake data presented as real.** The super-admin dashboard renders a hardcoded weekly activity series (`agriflow/agriflow-web/src/pages/superadmin/Dashboard.jsx:36-41`) and a static "All Systems Operational" pill (`:53`) while real stats come from `adminService.getDashboard()` (`:22-26`).

**P1 — Unit and status contradictions in the seed purchase flow.** The purchase table shows raw kilos — `{p.quantity_kg.toFixed(2)} Kg` (`agriflow/agriflow-web/src/pages/farmer/SeedPurchase.jsx:492`) — while the detail panel shows the same field divided by 100 as quintals (`:684`). The post-purchase modal header says "Payment Successful!" (`:634`) while the invoice it frames says "Pending Payment at Warehouse" / "Unpaid (Pay at Warehouse)" (`:124`, `:138`), and the UPI QR is labelled "Demo QR — for reference only" (`:619`).

**P2 — Dead and unreachable code.** `pages/farmer/GrainSales.jsx` is lazy-imported (`AppRouter.jsx:28`) but never used in any `<Route>`; `pages/farmer/Dashboard.jsx` is imported by nothing; `/register` redirects to `/get-started` (`AppRouter.jsx:71`) making `pages/auth/Register.jsx` unreachable; `services/cropService.js`, `components/RateLimitStatus.jsx`, `hooks/useRateLimit.js`, `utils/rateLimiter.js`, `App.css` and `assets/react.svg` are unreferenced. `DEMO_ACCOUNTS` with hardcoded credentials (`agriflow/agriflow-web/src/pages/auth/Login.jsx:18-22`) and its `fillDemo` helper (`:119`) are never rendered.

**P2 — Bugs inside the unrouted GrainSales page.** Form state only ever contains `grain_type`, `quantity_kg`, `warehouse_id` (`agriflow/agriflow-web/src/pages/farmer/GrainSales.jsx:20-22`), yet the submit button is disabled on `!form.crop_type` (`:159`), which is permanently true, and `estimated` reads `form.good_material_kg` / `form.grade` that never exist so it always renders `0.00` (`:51`).

**P2 — Landing price index shows no prices.** The public rate index iterates grades and prints grade label plus a static "Available" tick (`agriflow/agriflow-web/src/pages/public/LandingPage.jsx:394-402`) but never renders `price_per_kg`, so the "Live Market Prices" section displays no prices.

**P2 — Wasted work and stale fetches.** `pages/farmer/Profile.jsx` fetches a dashboard payload it never renders (`:45-50`) and defines an unused `getDaysUntil` (`:17-22`). `adminService.getFarmers(status, search)` accepts filters (`adminService.js:23-25`) but callers invoke it with none, filtering locally instead.

**P3 — Consistency and hygiene.** Navbar, language switcher and scroll-lock logic are copy-pasted across five public pages and three layouts (`AdminLayout.jsx:61-65,144-156`, `SuperAdminLayout.jsx:61-65,152-164`). The i18n dictionary declares `get_started` twice (`index/index.js:36` and `:59`), so the first silently loses. `SeedsCatalogPage` ignores `seed.image_url` while `LandingPage` uses it, so the same seed renders with and without its photo. Reports are aggregated client-side (`Reports.jsx:93-120`) although `API: GET /api/v1/admin/reports/monthly` exists, and audit logs are read but never contrasted with `API: GET /api/v1/admin/audit-logs` write-side expectations. The manager sidebar badge promises "Manager Portal" even for super admins (`AdminLayout.jsx:92,103`).

## Recommendations

1. **P0 — Decide the role model and enforce it server-side.** Either give `admin` a real portal (change `Login.jsx:89-100` and open `/manager/dashboard` to `admin`) or remove `admin` from every nav `roles` array. Move authorization out of the browser: send the user JWT to edge functions (or migrate these calls to `API: PATCH /api/v1/farmers/{farmer_id}/approval`, `API: POST /api/v1/managers`, `API: PATCH /api/v1/managers/{manager_id}/status`) and never trust `callerRole`/`adminId` from the body.
2. **P0 — Close the contract gaps.** Ledger entry create/edit, billing transaction creation, market-rate update/delete, farmer delete, manager profile update and warehouse edit/delete have no FastAPI counterpart: `Backend API required - to be supplied by Syed.`
3. **P1 — Reconcile nav and guards from one source of truth.** Derive both from a shared route table so `AdminLayout.jsx` and `AppRouter.jsx` cannot drift; delete the dead `procurement` link under `/manager/dashboard`, dedupe Cache Management in `SuperAdminLayout.jsx:37,41`, and gate the "Log Received Crop" button (`GrainSalesAdmin.jsx:91`) the same way its route is gated (`AppRouter.jsx:98,125`).
4. **P1 — Remove fabricated dashboard content.** Replace `activityData` and the static system-status pill with data derived from the dashboard payload or delete the chart.
5. **P1 — Normalise units and payment language.** Pick quintals everywhere (divide by 100 at the boundary once), and make the success header match the invoice status; replace or clearly hide the demo QR before production.
6. **P2 — Delete dead code in one pass:** `pages/farmer/Dashboard.jsx`, `pages/farmer/GrainSales.jsx` (or wire it to a route and fix its form keys), `pages/auth/Register.jsx` (or restore `/register`), `services/cropService.js`, the rate-limit trio, `App.css`, `assets/react.svg`, `DEMO_ACCOUNTS`.
7. **P2 — Fix the public rate index** to render `price_per_kg` per grade, and drop the unused dashboard query in `pages/farmer/Profile.jsx`.
8. **P3 — Deduplicate shell chrome** (navbar, language menu, scroll lock) into shared components and add a lint rule against duplicate object keys in the i18n dictionaries.

## Routes and roles

Public, no guard (`agriflow/agriflow-web/src/app/router/AppRouter.jsx:64-72`): `/` LandingPage (`:64`), `/market-rates` MarketRatesPage (`:65`), `/seeds-catalog` SeedsCatalogPage (`:66`), `/how-it-works` HowItWorksPage (`:67`), `/features` FeaturesPage (`:68`), `/get-started` GetStarted (`:69`), `/login` Login (`:70`), `/register` → redirect to `/get-started` (`:71`), `/forgot-password` ForgotPassword (`:72`).

Farmer portal, guard `['farmer']` (`AppRouter.jsx:75`), shell `layouts/FarmerLayout.jsx`: index → FarmerProfile (`:76`), `/farmer/crops` CropManagement (`:77`), `/farmer/seeds` SeedPurchase (`:78`), `/farmer/booking-slots` BookingSlot (`:79`), `/farmer/transactions` TransactionHistory (`:80`), `/farmer/profile` FarmerProfile (`:81`).

Manager portal, guard `['manager','super_admin']` (`AppRouter.jsx:86`), shell `layouts/AdminLayout.jsx`: index AdminDashboard (`:87`), `farmers` (`:88`), `seeds` (`:89`), `seed-purchases` (`:90`), `warehouse` (`:91`), `reports` — no inner guard, managers can open it although the sidebar hides it (`:92`), `booking-slots` (`:93`), `billing` (`:95`), `visits` (`:96`), `market-rates` (`:97`), `grain-sales` inner guard `['manager','admin','super_admin']` (`:98`), `credits` inner guard `['admin','super_admin']` (`:99`), `event-logs` inner guard `['super_admin']` (`:100`), `cache` inner guard `['super_admin']` (`:101`), `profile` ManagerProfile (`:102`). There is intentionally no `procurement` route here (`:94`).

Super-admin portal, guard `['super_admin']` (`AppRouter.jsx:107`), shell `layouts/SuperAdminLayout.jsx`: index SuperAdminDashboard (`:108`), `managers` ManageAdmins (`:109`), `farmers` AllFarmers (`:110`), `credits` CreditsAdmin (`:111`), the operational mirror under `op/*` reusing the admin pages (`:114-130`, including `op/procurement` GrainProcurement at `:121`), plus a duplicate top-level `cache` (`:129`). Everything else resolves to NotFound (`:133`).

Role inventory observed in source: `farmer`, `manager`, `admin`, `super_admin`. Nav visibility is filtered per role in `AdminLayout.jsx:56` and by shell choice; the guard contract is the only thing the router enforces (`ProtectedRoute.jsx:7`).

## Screen inventory

- **LandingPage** (`pages/public/LandingPage.jsx`): hero, rate index built from grouped rates (`:394-407`, prices missing), seed showcase using `image_url` (`:470`), stats, CTA clicks route to `/market-rates` or `/get-started`.
- **MarketRatesPage / SeedsCatalogPage / HowItWorksPage / FeaturesPage** (`pages/public/*`): read-only catalogues via `publicService`; search only on the seed grid.
- **GetStarted / Login / ForgotPassword / Register(unreachable)** (`pages/auth/*`): phone+password login with validator-backed fields, force password-change branch (`Login.jsx:75-79`), role redirect (`:89-100`); OTP reset in ForgotPassword; Register navigates to `/login` on success (`Register.jsx:97`).
- **FarmerProfile** (`pages/farmer/Profile.jsx`): four edit cards (personal `:29`, bank `:30`, agriculture `:31`, documents `:36`) saved through `farmerService`, refresh via `refreshProfile` (`:26`).
- **CropManagement** (`pages/farmer/CropManagement.jsx`): add/edit/delete own crops, status chips.
- **SeedPurchase** (`pages/farmer/SeedPurchase.jsx`): catalogue purchase modal, UPI QR demo (`:602-622`), invoice modal with contradictory status (`:624-645`), history table (`:488-492`) and detail drawer (`:682-685`).
- **BookingSlot** (`pages/farmer/BookingSlot.jsx`): pick warehouse, date slot, quantity, submit booking.
- **TransactionHistory** (`pages/farmer/TransactionHistory.jsx`): ledger rows with credit/debit colouring.
- **AdminDashboard** (`pages/admin/Dashboard.jsx`): manager KPI cards and quick links; used by both manager index and `op`.
- **FarmersDirectory** (`pages/admin/Farmers.jsx`): search (`:162`), status tabs (`:165-167`), detail panel (`:247-320`), approve/reject (`:84-92`), super-admin delete (`:94-103`), super-admin register modal (`:105-138`, `:324-397`).
- **SeedsInventory** (`pages/admin/SeedsInventory.jsx`): list with low-stock flags (`:131-133`), add/edit modal (`:83-95`) converting quintals↔kg and uploading images (`:25-47`), delete (`:72-81`).
- **SeedPurchases** (`pages/admin/SeedPurchases.jsx`): approve/reject purchase (`:35-46`), invoice HTML download (`:48-81`).
- **WarehouseManagement** (`pages/admin/Warehouse.jsx`): capacity bars (`:138-155`), inventory add (`:80-101`), slot create (`:103-120`).
- **BookingSlots** (`pages/admin/BookingSlots.jsx`): status filter chips (`:85-94`), approve/reject/complete actions (`:45-56`).
- **GrainProcurement** (`pages/admin/GrainProcurement.jsx`): approved-only queue (`:36-45`), stats cards (`:97-123`), procurement submit (`:60-85`).
- **GrainSalesAdmin** (`pages/admin/GrainSalesAdmin.jsx`): log received crop modal with qty validation (`:41-74`), received/paid filters (`:101-105`).
- **FarmVisits** (`pages/admin/FarmVisits.jsx`): visit list with due chips (`:23-31`), reschedule (`:83-92`), complete with photo (`:65-81`), add-visit modal (`:94-110`), nominatim geocoding (`:149-157`).
- **MarketRates** (`pages/admin/MarketRates.jsx`): grouped grade cards, bulk A/B/C create (`:51-55`), single edit (`:47-49`), delete (`:29-36`), super-admin-only controls (`:71-73,98-103`).
- **AdminReports** (`pages/admin/Reports.jsx`): report type picker (`:26-35`), date ranges (`:18-24`), enabled-per-type queries (`:78-83`), jsPDF download through `utils/pdfExport.js`.
- **Billing** (`pages/admin/Billing.jsx`): create bill form (farmer or custom name, credit/debit, method) inserting into `transactions` (`:57-88`), invoice/printer actions.
- **CreditsAdmin** (`pages/admin/CreditsAdmin.jsx`): ledger list, add/edit entry modal (`:43-90`).
- **EventLogs** (`pages/admin/EventLogs.jsx`): audit rows mapped from `adminService.getAuditLogs()` (`:13-32`), HTML export (`:36-54`).
- **CacheManagement** (`pages/admin/CacheManagement.jsx`): React Query cache table, selective clear (`:69-76`), clear all (`:78-80`).
- **ManagerProfile** (`pages/admin/ManagerProfile.jsx`): profile edit (`:36-57`) and password change (`:60-67+`).
- **SuperAdminDashboard** (`pages/superadmin/Dashboard.jsx`): stat cards (`:56-60`), fabricated activity chart (`:36-41`).
- **ManageAdmins** (`pages/superadmin/ManageAdmins.jsx`): manager CRUD modal (`:65-89`) with optional password reset.
- **AllFarmers** (`pages/superadmin/AllFarmers.jsx`): counts, search, read-only detail drawer (`:17-21`).
- **NotFound** (`pages/shared/NotFound.jsx`): 404 with home link.
- **Shells**: `layouts/FarmerLayout.jsx`, `layouts/AdminLayout.jsx` (role-filtered nav `:56`, bottom bar `:171-185`, rates widget `:187`), `layouts/SuperAdminLayout.jsx` (three-section nav `:30-58`, bottom bar `:178-192`).

## Workflows

1. **Manager sign-in → farmer approval.** Login validates fields (`pages/auth/Login.jsx:70-71`), `AuthContext.login` calls `authService.login` (edge `auth-api`; contract equivalent `API: POST /api/v1/auth/login`), `redirectUser` sends managers to `/manager/dashboard` (`:91`). Sidebar renders role-filtered links (`layouts/AdminLayout.jsx:56`). Farmers page loads via `adminService.getFarmers()` (`pages/admin/Farmers.jsx:73-76`); approve calls `managerService.approveFarmer(id, status, null, user.id)` (`:84-92`) which posts `{adminId}` into `manager-api`; contract equivalent `API: PATCH /api/v1/farmers/{farmer_id}/approval`. List invalidated and detail panel updated (`:88-90`).
2. **Super-admin seed cataloguing.** `/admin/dashboard/op/seeds` → `openAdd()` (`pages/admin/SeedsInventory.jsx:61`), image → `storageService.uploadBase64` (`:25-47`, contract `API: POST /api/v1/uploads`), submit converts stock quintals→kg and posts `warehouse_ids` (`:83-95`) through `adminService.createSeed/updateSeed` (`admin-api`); contract `API: POST /api/v1/seeds` / `API: PATCH /api/v1/seeds/{seed_id}`. Deletion (`:72-81`) matches `API: DELETE /api/v1/seeds/{seed_id}`. Warehouse-linked stock and `on_hold_kg` badges surface in the same table (`:130-133`).
3. **Slot booking → approval → procurement.** Farmer books on `/farmer/booking-slots` (`pages/farmer/BookingSlot.jsx`) through `farmerService` (contract `API: POST /api/v1/farmer/grain-sales/book-slot` or `API: POST /api/v1/bookings`). Manager reviews on `pages/admin/BookingSlots.jsx` (`:45-56`, contract `API: PATCH /api/v1/bookings/{booking_id}/status`). Approved bookings flow into `pages/admin/GrainProcurement.jsx` where the intake form submits received qty/moisture/quality (`:60-85`, contract `API: POST /api/v1/grain-sales/procure`).
4. **Seed purchase to invoice.** Farmer buys on `pages/farmer/SeedPurchase.jsx` → purchase row appears in `pages/admin/SeedPurchases.jsx` → approve/reject (`:35-46`, contract `API: PATCH /api/v1/seed-purchases/{purchase_id}/status`) → invoice HTML download (`:48-81`). The farmer-side invoice/QR flow (`SeedPurchase.jsx:602-645`) currently contradicts its own status text (P1 above).
5. **Farm visit lifecycle.** Super admin opens the add-visit modal, loads active crops (`pages/admin/FarmVisits.jsx:94-103`, contract `API: GET /api/v1/crops/active`) and schedules (`:105-110`, `API: POST /api/v1/farm-visits`). Reschedule (`:83-92`) maps to `API: PATCH /api/v1/farm-visits/{visit_id}/schedule`; completion with uploaded photo (`:65-81`) maps to `API: PATCH /api/v1/farm-visits/{visit_id}/complete`. Addresses are geocoded via nominatim (`:149-157`), an external dependency with no fallback.
6. **Market rate publishing.** Super admin bulk-creates grade rates (`pages/admin/MarketRates.jsx:51-55`, contract `API: POST /api/v1/market-rates`); the public page reads them through `publicService` (`API: GET /api/v1/public/market-rates`); the admin widget polls every 30s (`components/shared/LiveMarketRatesWidget.jsx:9-13`). Edit/delete go beyond the contract (gap marked above).
7. **Money movement.** Billing inserts `reference_type: 'billing'` rows directly (`pages/admin/Billing.jsx:74-88`) and CreditsAdmin creates/edits ledger entries (`pages/admin/CreditsAdmin.jsx:65-90`); reading works today only because `API: GET /api/v1/transactions` exists — creation has no endpoint: `Backend API required - to be supplied by Syed.`
8. **Notifications.** `NotificationCenter` polls `API: GET /api/v1/notifications` equivalents every 30s (`components/shared/NotificationCenter.jsx:17-24`), marks reads optimistically (`:36-52`), and can drive inline approve/reject for farmer requests (`:65-70`).
9. **Reporting.** `Reports.jsx` pulls per-type datasets with `enabled` queries (`:78-83`), filters by date bounds (`:85-91`) and exports branded PDFs (`utils/pdfExport.js:10-31`); the server-side counterpart `API: GET /api/v1/admin/reports/monthly` is unused.
10. **Session lifecycle.** `AuthContext` restores the Supabase session on mount, clears stale `sessionStorage` when there is none (`context/AuthContext.jsx:32-41`), listens to auth events (`:52-69`), and logout clears local state (`:150-157`; contract `API: POST /api/v1/auth/logout`).
