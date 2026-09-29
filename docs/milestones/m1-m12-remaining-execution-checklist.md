# M1–M12 Remaining-Milestone Execution Checklist (Reconstructed)

> **Source of truth:** this file reconstructs the M1–M12 plan from workspace evidence —
> `docs/milestones/m5-*` (steps 5–9 with gate reports), `docs/audits/pre-m8-*`,
> `docs/deep-review/workflow-cross-reference.md`, `docs/deep-review/flutter-03`,
> `docs/backend-requirements-admin-mobile.md`, current `lib/features` + shell routing,
> and the human-provided status table. The literal M1–M12 definition file was never
> committed to this workspace (it lived in conversation only) — **M6/M7/M10/M11/M12
> titles below are RECONSTRUCTED and flagged for human confirmation (confidence < 0.70).**
>
> Status vocabulary: `DONE` · `IN PROGRESS` · `BLOCKED (backend)` · `BLOCKED (device)`
> · `NOT STARTED` · `GATED (human)`.
> Verification baseline at reconstruction: `flutter analyze` 0 issues ·
> `flutter test` 553/553 · debug APK builds · GATES.md G0–G7 all PASS.

---

## Milestone status board

### DONE (evidence-attached)

| # | Milestone | Evidence |
|---|---|---|
| M1 | Core Foundation | Boots, theme/nav/core widgets, GATES G0–G3 pass |
| M2 | Authentication / Session | Login/OTP/forgot/reset/logout; `ApiClient` 401→refresh→retry live-verified; Pre-M8 Phase 1 complete (`docs/audits/pre-m8-phase1-stabilization-implementation.md`) |
| M3 | Navigation & Role Architecture | 19 `NavDestination`s, admin 9 routes + manager 5 tabs, `adminOnly` RBAC, shells wired (G6) |
| Pre-M4 | Startup/Login Branding | Assets + branded auth screens shipped |
| M4 | Dashboard | `admin_dashboard_view.dart` + `manager_dashboard_view.dart` live; advisories → M11 (P1-02 visit-status query, P2-03 trend `Future.wait`) |
| M5·1 | Seed Purchase | Approval queue + invoice; screen live |
| M5·2 | Booking Slots | Approve/reject wired to `PATCH /bookings/{id}/status` (inspect workflow → M6 gap) |
| M5·5 | All Farmers | `m5-step5-all-farmers-verification-report.md` |
| M5·6 | Seeds Inventory | `m5-step6-seed-inventory-implementation.md` (incl. Grade A/B/C + warehouse multi-select) |
| M5·7 | Warehouse | `m5-step7-warehouse-implementation.md` |
| M5·8 | Billing & Invoices | `m5-step8-billing-implementation.md` |
| M5·9 | Market Rates | `m5-step9-market-rates-implementation.md` |

### GATED / PARTIAL

| # | Milestone | Status | Detail |
|---|---|---|---|
| M5·3 | Farm Visits | **PARTIAL** | List/schedule/complete shipped. Remaining client gaps: `POST /farm-visits/reminders` (no call site), `createVisit` dead code, `pending_review` filter chip, dialog error surfacing (flutter-03 recs 2–4). **Cancellation API does not exist in the contract → BLOCKED (backend) — confirm semantics with Syed, do not invent.** |
| M5·10 | Next M5 step (identity **not documented** — likely Farm Visits completion incl. cancellation/reminders) | **GATED (human)** | `m5-step9-market-rates-implementation.md:231` "STOP — do not begin M5 Step 10 without human approval"; notification task added device-verification dependency |
| M9 | Notifications & Android system popups | **CODE DONE / BLOCKED (device)** | Investigation + popup fix complete (`docs/bugs/admin-manager-notification-dynamic-fix.md`, `docs/bugs/android-system-popup-notification-fix.md`); 553/553 tests; gate `BLOCKED — DEVICE VERIFICATION` (adb recheck 2026-09-28: no device attached, gate stays closed); terminated delivery → BLOCKED (backend FCM) |

### RECONSTRUCTED remaining milestones (confidence < 0.70 — confirm titles)

#### M6 — Remaining business workflows (unblocked, contract-supported) — ✅ DONE (2026-09-28, items 1–7; report: `m6-remaining-business-workflows-verification-report.md`; item 8 DEFERRED pending product-intent confirmation; device-verified on CPH2381)
All have live contract routes; purely Flutter work:
1. `POST /farm-visits/reminders` → repository + controller + UI entry (flutter-03 rec 2)
2. `POST /bookings/{id}/inspect` → crop-inspection sheet (FEAT-03, pre-M8 §17.2)
3. `PATCH /grain-sales/{id}/yield` → yield entry UI (grain ds stops at `/pay`)
4. Schedule Farm Visit create sheet (FEAT-02; `POST /farm-visits` route live)
5. Farmer Profile Edit form (FEAT-04; `PATCH /farmers/{id}` ready per pre-M8 §17.3)
6. Farmer fixes: pagination `hasNext` P0 (flutter-03 rec 1), `loadFarmerDetail` wiring (rec 7), bank-request pagination + race (recs 8–9), mutation error surfacing (rec 4)
7. Filter parity: visit `pending_review` chip; grain-sales chip split `pending/received/approved/rejected` (rec 3)
8. `POST /auth/change-password` + first-login force-change (cross-ref finding 5) — confirm product intent

#### M7 — Admin & Analytics modules (routes live, dirs empty) — ✅ DONE (2026-09-28; report: `m7-admin-analytics-verification-report.md`; code-complete, DEVICE VERIFICATION BLOCKED — device disconnected after M6)
`lib/features/{managers,reports,event_logs}` are `.gitkeep`-only; shells render `ModulePlaceholderScreen`:
1. **Managers admin** (adminOnly): `GET/POST /managers`, `PATCH /managers/{id}/status`, `POST /managers/{id}/reset-password` (AGENTS §2.3; RBAC: Super Admin & Admin only)
2. **Reports & Analytics** (adminOnly): `GET /admin/reports/monthly` full screen — date range/type switch (no export: BLOCKED (backend) for PDF/CSV)
3. **Event Logs** (adminOnly): `GET /admin/audit-logs` with pagination/filters

#### M8 — UI & Polish — ✅ DONE (2026-09-28; report: `m8-ui-polish-verification-report.md`; code-complete, DEVICE VERIFICATION BLOCKED — device disconnected after M6)
1. ISSUE-P3-01 WCAG AA muted-text contrast · 2. ISSUE-P3-03 ≥48×48dp touch targets · 3. FEAT-02/03 sheets (coordinate with M6 — same items, one implementation) · 4. Raw-ISO-date cleanup + shared components (flutter-03 recs 11–12)

#### M10 — Account, Settings, Help, Credits, Cache — ✅ DONE (2026-09-28; report: `m10-account-settings-help-verification-report.md`; code-complete, DEVICE VERIFICATION BLOCKED — device disconnected after M6)
- **Client-side (shipped):** `settings`/`help` screens (routed from both shells + account rows), profile self-edit on `GET/PATCH /users/me` (contract-scoped `{name,email}` only; phone read-only → Backend API required; zone/branch omitted), notification toggles device-local (no backend endpoint), Terms/Privacy/FAQ copied from HTML
- **BLOCKED (backend):** Credits ledger (item 2) + Cache stats/clear (item 14) — no contract → honest "Blocked (backend)" placeholder, never fake data
- Gates: analyze 0 · tests **687/687** (+20 M10) · contract 50/50 · probes 17 OK · debug APK ✓

#### M11 — Hardening & workflow alignment — ✅ DONE (2026-09-28; report: `m11-hardening-workflow-verification-report.md`; code-complete, DEVICE VERIFICATION BLOCKED — device disconnected after M6)
- **Verify-only:** P1-01 grain `booking_slot_id` fallback ✓ P1-02 manager dashboard `scheduled` vs `in_progress` ✓ P2-03 admin trend `Future.wait()` ✓ bank-change sheet load-more/error display (already shipped M7/M8) ✓ · P2-01 bookings date query params → BLOCKED (backend)
- **Client-side (shipped):** manager dashboard honest relabels (all-time/MTD basis, `scheduled` visit count, fabricated constants/deltas removed), StatusPill `pending_review`/`inspected` cases, shared `AppApiException` + typed 409 conflicts, shared `FarmerLookupService` (flutter-03 rec 5) + 15s timeouts on farm-visit/booking calls, seed-purchase invoice PDF download (cross-ref finding 8, client-side only)
- **BLOCKED (backend):** booking date filtering, server-side "today" aggregates (cross-ref finding 8 root cause), dedicated manager dashboard API
- Gates: analyze 0 ✓ tests **712/712** (+25 M11) ✓ contract 50/50 ✓ probes 17 OK ✓ debug APK ✓

#### M12 — Final regression & release readiness — ✅ DONE (2026-09-28; report: `m12-final-regression-release-readiness-report.md`; code-complete, DEVICE VERIFICATION BLOCKED — device disconnected after M6)
- Full gate sweep re-measured: G0 LINT OK · G1 analyze 0 · G2 tests **712/712** · G3 debug APK ✓ · **release APK ✓ (61.8 MB)** · G4 contract 50/50 (123 ops) · G5 probes 17 OK (control 404) · G6 wiring OK (9 admin routes, 5 manager tabs) · G7 report sections present
- RBAC spot-check matrix (10 rows, AGENTS §3): manager read-only on Seeds/Warehouses/Market Rates ✓ adminOnly destinations blocked at manager shell ✓ KYC approve/reject + grain intake + visit completion open to both ✓ — all rows code+test evidenced in report §3
- Device QA T0–T10: ⛔ all BLOCKED (no adb device) — queued for re-attach; reports M6/M7/M8/M10/M11/M12 archived in `docs/milestones/`

### BLOCKED (Syed) — global dependency register (do not fake around)
From `docs/backend-requirements-admin-mobile.md` + cross-ref "Backend API required" (16 items) + task gates, the ones that block milestones: farm-visit **cancellation** · manager dashboard API / date-scoped "today" aggregates (11) · booking server-side date filter + slot_time (12) · report export (13) · billing invoice creation (1) · credits ledger (2) · market-rate edit/delete (3) · manager profile edit (5) · cache endpoints (14) · staff FCM (15) · seed-purchase search (16). **All marked: "Backend API required — to be supplied by Syed."**

---

## Execution rules (binding for all remaining milestones)

```text
CYCLE per milestone: AUDIT → IMPLEMENT → VERIFY → REGRESSION → DOCUMENT → NEXT
BOUNDARY: Flutter frontend only. Backend/DB/migrations/business rules = Syed. Never
  modify backend to make a milestone look complete; never invent endpoints/fields.
RETRIES ≤ 3 per action then STOP + report blocker.  Confidence < 0.70 → investigate or
  ask human, never guess.  Keep context < 50k tokens → compress preserving
  requirements/decisions/errors/test results/API contracts/blockers.
PARALLELIZE investigation (contract audits for M6+M7 can run concurrently); NEVER two
  agents editing the same Flutter file simultaneously.
MILESTONE COMPLETE = FUNCTIONALITY + API CONTRACT + UI/UX + ERROR STATES + TESTS +
  ANDROID VERIFICATION + REGRESSION, each with evidence. Android verification is
  currently BLOCKED (no adb device) → milestones close as
  "code-complete, DEVICE VERIFICATION BLOCKED" until a device exists.
GATES: stop at every human gate already defined (M5 Step 10, M5 step approvals pattern);
  GATES.md G0–G7 must stay green after every milestone.
```

## Definition of Done (per milestone, evidence required)
`flutter analyze` 0 issues · full `flutter test` green (no weakened tests) · relevant new
tests added · endpoint list matches live OpenAPI (`scripts/verify-endpoints.mjs contract`)
· error/loading/empty states present · RBAC per AGENTS §3 · report saved under
`docs/milestones/` with tag AUTOMATED / REAL BACKEND / BLOCKED · regression on prior
milestones (full suite + G6 wiring check).

## Recommended execution order
**M6 → M7 → M8 → M9 (close device gate when device available) → M10 → M11 → M12**,
with M5·10 human approval requested at the start (it may re-sequence ahead of M6).

---

## Appendix — Single execution prompt (for Antigravity)

```text
You are executing the AgriFlow Admin/Manager Flutter migration, milestones M6→M12,
against docs/milestones/m1-m12-remaining-execution-checklist.md as the source of truth.

HARD RULES
- Frontend boundary: Flutter UI/navigation/state/API-integration/error-states/validation/
  tests ONLY. Zero backend, DB, migration, or business-rule changes. Missing capability =
  write "Backend API required — to be supplied by Syed" in the milestone report; never
  invent endpoints, payloads, or reference data.
- Never weaken or delete existing tests (baseline: 553 passing, flutter analyze 0 issues).
- GATES.md G0–G7 must remain green after each milestone.
- Control policy: MAX_RETRIES_PER_ACTION=3 then STOP+report blocker; MIN_CONFIDENCE=0.70
  else investigate/ask; keep context <50k tokens (compress: requirements, decisions,
  errors, test results, API contracts, blockers).

PER-MILESTONE CYCLE (M6, then M7, M8, M9-close, M10, M11, M12)
1. AUDIT: read React reference (agriflow/agriflow-web/src/pages), HTML UI refs
   (AdminMobile UIUX*.html, Manager Dashboard UIUX*.html), current Flutter code, and
   live OpenAPI (openapi_dump.json / live_openapi.json). Produce a contract gap list
   with evidence line refs.
2. IMPLEMENT only contract-confirmed behavior with error/loading/empty states and
   RBAC per AGENTS.md §3 (Admin/Super Admin mutations; Manager read-only on catalogs).
3. VERIFY: flutter analyze (0 issues) + flutter tests for the touched feature.
4. REGRESSION: full flutter test + node scripts/verify-endpoints.mjs contract.
5. DOCUMENT: save docs/milestones/m<N>-<name>-verification-report.md tagging every claim
   AUTOMATED VERIFIED / REAL BACKEND VERIFIED / BLOCKED.
6. NEXT MILESTONE immediately. Stop only at: human gates (M5 Step 10), BLOCKED items,
   or control-policy violations.

MILESTONE-ITEM MAP (from checklist): M6 = contract-supported workflow gaps (reminders,
inspect, yield, farmer fixes/filters/errors, FEAT-02/03/04). M7 = Managers admin +
Reports + Event Logs screens (empty dirs, live routes). M8 = pre-m8 Phase 3 polish.
M9 = notifications — already code-complete; only attempt device verification if adb
reports a device, else keep BLOCKED — DEVICE VERIFICATION. M10 = settings/help/profile
(client-side); credits/cache stay placeholder until Syed ships contracts. M11 = pre-M8
Phase 2 verify + flutter-03 hardening recs. M12 = full gate sweep incl. release APK.

PARALLELIZATION: run M6 and M7 contract audits in parallel; implement sequentially in
one file-owner at a time (M6 feature dirs first, then M7 dirs). Prepare regression/
reports while audits run.

ANDROID VERIFICATION: at each milestone run `adb devices`; if empty, mark
"code-complete, DEVICE VERIFICATION BLOCKED" and continue — do not stall, do not claim
device-proven behavior.

FINAL REPORT when M12 completes: milestone status board updated (DONE/BLOCKED with
evidence), remaining Syed dependency register, GATES.md state, total test count, and
explicit device-verification status.
```
