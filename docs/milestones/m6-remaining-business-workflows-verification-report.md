# M6 — Remaining Business Workflows: Verification Report

**Date:** 2026-09-28 · **Milestone:** M6 (checklist item 1–8) · **Verdict:** ✅ **COMPLETE for items 1–7** (code + tests + contract + on-device). Item 8 deferred pending product-intent confirmation.

**Device verification performed on:** Oppo CPH2381, Android 14, 1080×2412, app `com.example.agriflow_admin` (debug APK built from this tree), session: super_admin `9999900000`.

---

## 1. Scope & Status

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | `POST /farm-visits/reminders` full stack + UI entry (flutter-03 rec 2) | ✅ COMPLETE | [E-T1], [E-D2] |
| 2 | `POST /bookings/{id}/inspect` → crop-inspection sheet (FEAT-03) | ✅ COMPLETE | [E-T2] |
| 3 | `PATCH /grain-sales/{id}/yield` → yield entry sheet | ✅ COMPLETE | [E-T2] |
| 4 | Schedule Farm Visit create sheet (FEAT-02, `POST /farm-visits`) | ✅ COMPLETE | [E-T1], [E-D3], [E-D4] |
| 5 | Farmer Profile Edit form (FEAT-04, `PATCH /farmers/{id}`) | ✅ COMPLETE | [E-T3], [E-D6] |
| 6 | Farmer fixes: pagination `hasNext` P0 (rec 1), `loadFarmerDetail` wiring (rec 7), bank-request pagination + race (recs 8–9), mutation error surfacing (rec 4) | ✅ COMPLETE | [E-T3], [E-C1] |
| 7 | Filter parity: visit `Pending Review` chip; grain chips `pending/received/approved/rejected` (rec 3) | ✅ COMPLETE | [E-D1], [E-D5], [E-T4] |
| 8 | `POST /auth/change-password` + first-login force-change | ⏸ DEFERRED — "confirm product intent" per checklist; requires human decision before implementation | — |

## 2. Contract Evidence (openapi_dump.json — authoritative)

[E-C1] Every mutation used matches a live route; nothing invented:
- `POST /farm-visits/reminders?days_ahead=N` → `MessageResponse` — implemented as `sendReminders` (DS) / `sendVisitReminders` (repo+controller); response parsed `data.message` → `message` → fallback `'Visit reminders sent.'`.
- `POST /farm-visits` → `FarmVisitCreate{crop_id, visit_month:1–6, scheduled_date, staff_id?}` → `SuccessResponse[FarmVisitPublic]` — schedule sheet enforces month 1–6, required crop/date, optional staff.
- `POST /bookings/{id}/inspect`, `PATCH /grain-sales/{id}/yield` — implemented in M6-B/M6-C.
- `PATCH /farmers/{id}` → `FarmerAdminUpdateRequest` (all fields optional) — edit form sends **only non-empty values** (no blind clobber).
- `Pagination` schema = `{page, page_size, total, total_pages}` (no `has_next`/`total_records`) — `FarmerPagination.fromJson` now reads `total` and **derives** `hasNext = page < totalPages`, `hasPrevious = page > 1` (flutter-03 rec 1 P0 root fix).

[E-C2] Contract sweep: `node scripts/verify-endpoints.mjs contract` → **48 unique client paths, all present in live contract (123 ops)**.

## 3. Test Evidence

[E-T1] `test/features/farm_visits/farm_visit_test.dart` — **40/40**, incl. new group *M6-A Reminders, Schedule Sheet & Pending Review* (13 tests: dialog inline errors, sheet validation/happy/failure, snackbar, pending-review filter).
[E-T2] `test/features/booking_slot` + `test/features/grain_sales` M6-B/C — **70/70**.
[E-T3] `test/features/farmers/farmer_test.dart` — new group *M6-D Farmer Fixes & FEAT-04 Profile Edit* **13/13** (loadMoreFarmers pagination, loadFarmerDetail wiring, updateFarmerProfile success/failure, bank pagination loadMore, rec-8 lookup warm-up, detail Edit button admin/manager visibility, bank error banner, edit-sheet validation→submit→pop, inline backend failure, screen wiring Edit flow). Pagination tests rewritten to contract keys (`total`/`total_pages`).
[E-T4] `test/features/grain_sales/grain_sale_test.dart` — **48/48**, incl. new `grain_chip_*` key assertions for all six chips + Approved-filter data-source request test. (Chips gained stable `Key('grain_chip_$filterKey')` for testability.)
[E-T5] **Full regression:** `flutter analyze --no-pub` → **0 issues**; `flutter test` → **580/580 pass** (baseline 553 → +27 net new tests; no tests weakened).

## 4. On-Device Evidence (Oppo CPH2381, Android 14)

[E-D1] **Grain chip parity** — all six chips render and scroll: `All · Pending · Received · Approved · Rejected · Paid` → `m6-evidence/m6_08_grain_chips_s.png`.
[E-D2] **Reminders POST live** — tapping the header bell produced backend-driven snackbar **"Sent 0 visit reminder(s)"** (response message rendered, not a stub) → `m6_16_reminder_result_s.png`.
[E-D3] **Schedule sheet (FEAT-02)** — opens with Crop\*, Visit Month (1‑6)\*, Scheduled Date\*, Assign Staff (optional), submit button → `m6_17_schedule_sheet_s.png`.
[E-D4] **Client validation** — submitting empty shows inline `Crop is required` / `Required` / `Date is required`, no network call → `m6_18_schedule_validation_s.png`.
[E-D5] **Filter parity live** — Grain `Approved` chip → filtered list of approved sales (active-chip state correct); Farm Visits `Pending Review` chip → only `Pending_review` visits → `m6_09_grain_approved_s.png`, `m6_24_pending_review_s.png`.
[E-D6] **FEAT-04 end-to-end PATCH** — Farmers directory → detail card (GET `/farmers/{id}` data: phone/land/email/joined) → **Edit Profile** → prefilled form (name, phone, acres) → set Address=`Hyderabad` → **Save Changes** → sheet popped → detail now shows **`VILLAGE / ADDRESS: Hyderabad`** (PATCH persisted, local cache refreshed) → `m6_23_save_result_s.png`, `m6_19_farmers_s.png`.
[E-D7] **Error handling** — an expired access token surfaced as inline app snackbar *"Session expired. Please log in again."* (401 handled gracefully; re-login via drawer worked) — session TTL on the test backend is short; worth noting for QA runs.

## 5. Gaps, Deferrals & Backend Notes

1. **Item 8 — change-password / first-login force-change:** checklist says *confirm product intent*. **Open question for human:** should first login after the default password (`AgriFlow@123`, flutter-03 rec 10) force a password change? Not implemented until confirmed.
2. **FEAT-04 omitted fields — Backend API note for Syed:** `FarmerProfilePublic` does **not** return `farm_name / village / district / state / crop_address`; the edit form therefore intentionally covers only returned fields (name, phone, email, address, acres, soil, irrigation, primary/secondary crop). Returning the five extra fields would allow full-profile editing without blind-clobber risk.
3. **Farm-visit cancellation** remains BLOCKED (no contract route) — card action not offered.
4. **flutter-03 rec 10** (hardcoded default password in `add_farmer_sheet.dart`) → routed to M8 (UI/Polish), not fixed here.
5. M6 closed **with live device verification** (device `702bcb80` attached this session) — no "DEVICE VERIFICATION BLOCKED" tag needed for this milestone.

## 6. Evidence Index

- Screenshots: `docs/milestones/m6-evidence/*.png` (8 files, listed inline above).
- Tests: `flutter test` run 2026-09-28 — 580/580; `flutter analyze` — 0 issues.
- Contract: `node scripts/verify-endpoints.mjs contract` — 48/48 paths.
- Key sources: `lib/features/farmers/**` (pagination, DS/repo/controller, `edit_farmer_profile_sheet.dart`, bank sheet, detail sheet), `lib/features/farm_visits/**` (`schedule_visit_sheet.dart`, reminders), `lib/features/booking_slot/**`, `lib/features/grain_sales/**`.
