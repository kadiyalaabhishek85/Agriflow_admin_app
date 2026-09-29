# M12 - Final Regression & Release Readiness: Verification Report

## 1. Scope & Status

M12 is the closing milestone: a full re-measured gate sweep (G0-G7), the RBAC spot-check matrix, report archival, and the device QA plan.

- **Status:** code-complete. **Release readiness: GREEN for build/contract/tests, DEVICE VERIFICATION BLOCKED** (`adb devices` empty on 2026-09-28) — all Android QA (T0-T10) queued for device re-attach.
- **Cycle:** AUDIT → IMPLEMENT → VERIFY → REGRESSION → DOCUMENT → NEXT (no implementation changes in M12 — pure verification; Flutter-only boundary intact).

## 2. Gate Sweep (re-measured 2026-09-28)

| Gate | Check | Result |
|---|---|---|
| G0 | `gate-lint.mjs GATES.md` | ✅ LINT OK |
| G1 | `flutter analyze --no-pub` | ✅ No issues found |
| G2 | `flutter test` | ✅ **712/712** All tests passed |
| G3 | `flutter build apk --debug` | ✅ `app-debug.apk` built |
| G4 | `verify-endpoints.mjs contract` | ✅ ENDPOINTS CONNECTED — 50 unique client paths, 123 ops, all in live contract |
| G5 | `verify-endpoints.mjs probes` | ✅ PROBES OK — 17 probes, 404 control confirmed |
| G6 | shell wiring measurement | ✅ WORKFLOW WIRING OK — 9 admin routes, 5 manager tabs, placeholder fallbacks present |
| G7 | review report sections | ✅ (unchanged `docs/audits/build-endpoint-workflow-review.md` still contains all required sections) |
| Release | `flutter build apk --release` | ✅ **`app-release.apk` built (61.8 MB)** — first release build of the cycle; tree-shaken icons confirmed |

Regression across prior milestones: M6/M7/M8/M10/M11 all re-verified by the same full-suite + contract + probe run above; no test was weakened, none skipped.

## 3. RBAC Spot-Check Matrix (AGENTS.md §3)

Measured from code and locked by tests:

| # | Capability | Admin / Super Admin | Manager | Evidence |
|---|---|---|---|---|
| 1 | Seeds catalogue mutations (create/edit/delete) | ✅ full | ❌ read-only | `seeds_inventory_screen.dart:297,482,510` + `seed_inventory_card.dart:245` gate on `isAdmin`; tests `seeds_inventory_test.dart:964` (admin controls render) and `:982` (Add Seed hidden for manager) |
| 2 | Warehouse catalogue | ✅ full | ❌ read-only | `warehouse_test.dart:1159,1189,1207,1227` admin/manager render variants |
| 3 | Market rates | ✅ create (`canEditMarketRates`) | ❌ read-only board | `user_role.dart:74`; tests `market_rates_test.dart:698` (canSetRate RBAC), `:901` (manager sees no Set Rate) |
| 4 | Manager administration | ✅ adminOnly destination | ❌ blocked | `nav_destination.dart:131` (`adminOnly: true`); manager shell role-isolation defense `manager_shell.dart:346-348` |
| 5 | Admin-only destinations (Reports, Event Logs, Managers, Credits, Cache) | ✅ 5 × `adminOnly: true` | ❌ blocked at navigation | `nav_destination.dart:107,115,131,139,147`; defense `manager_shell.dart:346-348`; capability getters `user_role.dart:71-76` |
| 6 | Farmer KYC approve/reject | ✅ | ✅ (per AGENTS §3) | `farmer_screen.dart:82-113` available to both roles; suspend is admin-only `:126` (`onSuspend: !isManagerRole`); tests `farmer_test.dart:789,808,863,884,1107,1132` |
| 7 | Grain intake / procurement | ✅ (Grain Sales desk) | ✅ (Crop Procurement mode) | `grain_sale_screen.dart:257-274` role-specific header/mode; tests `grain_sale_test.dart:1336-1433` |
| 8 | Farm visit completion | ✅ | ✅ | no client-side gate (contract enforces assignment server-side); data-source 409 conflict path covered in `m11_workflow_hardening_test.dart` |
| 9 | Role propagation into feature screens | ✅ `isAdmin: true` / role-aware | ✅ `isAdmin: false`, `isManagerRole: true` | `admin_shell.dart:240,310,512,550`; `manager_shell.dart:218,295,466,489,497,504,513`; `farmer_screen.dart:79`; `seeds_inventory_screen.dart:17` |
| 10 | Role mapping from backend token | admin/superAdmin → `isAdmin` true; manager → false | | `user_role.dart:34`; tests `role_mapping_test.dart:9,21,31,41`; `auth_controller_test.dart:105` |

**Verdict:** every AGENTS §3 row holds — managers are read-only on Seeds/Warehouses/Market Rates, blocked from the five admin-only destinations, and retain KYC approve/reject, grain intake and visit completion.

## 4. Device QA T0-T10 — ALL BLOCKED

`adb devices` empty (2026-09-28). Queued for device re-attach:

| ID | Scenario | Status |
|---|---|---|
| T0 | Login + role routing into Admin / Manager shells | ⛔ BLOCKED (device) |
| T1 | Dashboards render at target sizes, no overflow, pull-to-refresh | ⛔ BLOCKED (device) |
| T2 | Farmers: pagination, detail sheet, KYC approve/reject/suspend (both roles) | ⛔ BLOCKED (device) |
| T3 | Bank-change requests: sheet load-more + error display | ⛔ BLOCKED (device) |
| T4 | Seeds inventory: admin CRUD vs manager read-only | ⛔ BLOCKED (device) |
| T5 | Warehouse + placeholder honesty fallbacks | ⛔ BLOCKED (device) |
| T6 | Farm visits: schedule/complete, 409 conflict toast, 15s timeout message | ⛔ BLOCKED (device) |
| T7 | Grain procurement (manager) + seed-purchase **invoice download via SAF picker** | ⛔ BLOCKED (device) |
| T8 | Bookings: status changes + client-side date filter | ⛔ BLOCKED (device) |
| T9 | Notifications system popups (M9), Settings/Help/profile edit (M10) | ⛔ BLOCKED (device) |
| T10 | Offline/timeout UX: airplane mode → sanitized `isNetworkError` messages | ⛔ BLOCKED (device) |

## 5. Report Archive

`docs/milestones/` contains: M5 series (13 files), `m6-...`, `m7-...`, `m8-...`, `m10-...`, `m11-...` verification reports + this M12 report; M9 is recorded in the checklist as *CODE DONE / BLOCKED (device)* (popup fix shipped, device-only verification). Checklist M6-M12 entries all carry gate evidence.

## 6. Release Readiness Verdict

**Ready pending device:** build (debug + release), static analysis, 712-test suite, live contract connectivity, live probe semantics, navigation wiring, RBAC matrix and report archive are all green and re-measured today.

**Remaining blockers (unchanged, tracked in checklist):**
1. **Device** — T0-T10 + M5 Step 10 + M9 device gate + M10/M11 device verification.
2. **Syed/backend (do not fake):** farm-visit cancellation, manager dashboard API / "today" aggregates, booking server-side date filter + `slot_time`, report export, billing invoice creation, credits ledger, market-rate edit/delete, manager profile edit, cache endpoints, staff FCM, seed-purchase search, change-password product intent (M6 item 8).
3. M6 item 8 change-password — awaiting human product-intent confirmation.

## 7. Evidence Index

- Gates: §2 table (all re-run 2026-09-28); `GATES.md` G0-G7 checks pass as written.
- RBAC: §3 table with file:line + test citations.
- Reports: `docs/milestones/*.md` (M6-M12 verification reports).
- Checklist: `docs/milestones/m1-m12-remaining-execution-checklist.md` (M12 entry updated).
