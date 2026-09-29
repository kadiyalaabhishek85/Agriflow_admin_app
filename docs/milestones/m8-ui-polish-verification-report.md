# M8 — UI & Polish: Verification Report

**Date:** 2026-09-28 · **Milestone:** M8 (checklist line 65) · **Verdict:** ✅ **CODE-COMPLETE** — audit + implementation + tests + gates green. **DEVICE VERIFICATION BLOCKED** (device disconnected after M6).

---

## 1. Scope & Status

| # | Item | Status | Evidence |
|---|------|--------|----------|
| 1 | **ISSUE-P3-01** WCAG AA muted-text contrast | ✅ COMPLETE | [E-P1], [E-T4] |
| 2 | **ISSUE-P3-03** ≥48×48dp touch targets | ✅ COMPLETE | [E-P2], [E-T4] |
| 3 | **FEAT-02/03** Schedule-visit + inspect-booking sheets | ✅ ALREADY SHIPPED (M6), verified wired | [E-F1] |
| 4 | **flutter-03 recs 11–12** raw-ISO-date cleanup + shared components | ✅ COMPLETE | [E-R11], [E-R12], [E-T4] |

Tag: **AUTOMATED** (static analysis, unit/widget tests, contract & probe sweeps) · no live-backend behavior added by M8 → **REAL BACKEND VERIFIED** not applicable beyond regression [E-G4]/[E-G5].

## 2. Audit Evidence

- [E-F1] **FEAT-02/03 already shipped in M6** — `ScheduleVisitSheet.show` called at `lib/features/farm_visits/presentation/farm_visit_screen.dart:161`; `InspectBookingSheet.show` called at `lib/features/booking_slot/presentation/booking_slot_screen.dart:156`. No duplicate implementation created (checklist: "coordinate with M6 — same items, one implementation").
- [E-A1] **Eyebrow ground truth:** both HTML design sources carry the flawed *"Farm visit scheduling"* subtitle on the Booking Slots screen; the React reference (`agriflow-web/src/pages/BookingSlots.jsx`) subtitle is *"Approve or reject farmer delivery slot requests"*. Chosen replacement: **"Farmer delivery bookings"** (rendered uppercased by `AppTypography.eyebrow`). One existing assertion pinned the old copy — updated to the corrected text (copy fix, not a weakened check).

## 3. Implementation Evidence

### ISSUE-P3-01 — muted-text contrast [E-P1]

`lib/core/constants/app_colors.dart`:
- `textMuted` → `0xFF4E5A51` — **6.6:1** on background, 5.98:1 on surfaceAlt (was 4.45:1, below AA).
- `textFaint` → `0xFF5F6C63` — **5.04:1** on background, 4.72:1 on surfaceAlt.
- Both now pass **WCAG AA (≥4.5:1)** for normal text on background/surface/surfaceAlt; a doc comment cites ISSUE-P3-01. Grep confirmed neither token is used on navy/forest (dark) surfaces, so no inverse-text regression.

### ISSUE-P3-03 — ≥48×48dp touch targets [E-P2]

- `lib/core/widgets/squircle_icon_button.dart`: exported `kMinTouchTargetSize = 48.0`; painted visual keeps its `size` (32/36/38) while the hit box is `SizedBox(max(size,48)) > Center`; badge restructured inside the visual `Stack` (`top:7, right:8`) so it stays pinned to the visual, not the hit box.
- `lib/features/booking_slot/presentation/widgets/date_selector_strip.dart`: chip content `ConstrainedBox(minHeight: 32)` inside 8+8 vertical padding → **48dp** tall chips without changing horizontal footprint.
- Explicit `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` on icon `IconButton`s / `PopupMenuItem` triggers at: `farm_visit_screen.dart:236`, `warehouse_detail_sheet.dart:595` (compact removed), `warehouse_card.dart:119`, `grain_sale_screen.dart:250`, `edit_rate_disabled_action.dart:74` (compact removed); `billing_screen.dart:503` `visualDensity: compact` removed.
- **Decision:** Material `TextButton`/`ElevatedButton` sites with `visualDensity: compact` were left at Material's own ≥36dp standard — out of the audit's cited icon-button scope (documented, not silently skipped).

### flutter-03 rec 12 — date formatting + eyebrow [E-R12]

- New **`lib/core/utils/app_dates.dart`** — single source: `dayMonthYear`, `dayMonthYearOf`, `isoDateTimeLabel`, `dateTimeLabel`, `numericDate`. Byte-compat rules: day zero-padded (`05 Sep 2026`), unparseable non-empty passes through raw, null/empty → caller `fallback`.
- Converted sites: `farm_visit_detail_sheet` (fallback `Not set`), `farm_visit_card` (`Date TBD`), `booking_card.dart:98`, `booking_detail_sheet.dart:128`, `seed_purchase_detail_sheet.dart:130`, `seed_purchase_card`, `notification_screen` (now unified `28 Sep 2026, 10:32`), `audit_log_item.createdLabel` (delegate, output-identical), `booking_slot_screen` eyebrow → **"Farmer delivery bookings"**.
- Left alone by design: `create_slot_sheet._formatDate` — its ISO string is the **API payload** for `POST /bookings`, not display text.

### flutter-03 rec 11 — shared components [E-R11]

- **`lib/core/widgets/detail_row.dart`** — replaces the three private `_buildDetailRow` builders in the booking, seed-purchase and grain-sale detail sheets (default 12px w600 = booking/seed pixel-identical; `emphasis` w800; `mono` money rows; `valueColor` kept; no ellipsis — long values wrap as before). Grain-sheet values shift 13.5→12px (accepted unification).
- **`lib/core/utils/app_initials.dart`** — unifies all seven per-feature initial helpers (farmer/manager/farm-visit/grain/billing entities + booking/seed cards); `fallback` parameter covers the `'?'`/`'TX'` variants. Existing assertions (farmer `RN`/`S`, managers `AK`/`R`) pass unchanged.
- **`lib/core/widgets/sheet_drag_handle.dart`** — replaced **22** copy-pasted handle blocks across all detail/create sheets; standard width 40 (was 36 in farm-visit sheet), caller margins (`bottom: 16/12`) preserved via parameter; `custom_tabbar.dart` intentionally skipped (it is a tab indicator, not a handle).
- **Card consolidation onto `AppCard`:** `AppCard` gained a `margin` param and its tap branch now renders `Material > InkWell > Ink` (was a plain `Container`, which swallowed ripples — existing AppCard users get visible ripples as a side benefit). Converted: `booking_card`, `seed_purchase_card`, `grain_sale_card` (−4 indent), `farmer_card` (−6), `manager_card` (header swap). All five verified by the full suite.

## 4. Test Evidence

- [E-T4] **New tests (27):**
  - `test/core/app_utils_test.dart` (15) — AppDates: ISO/date/space inputs, zero-padded day, null/empty fallbacks, unparseable passthrough, 24h `10:32` label, `dd/MM/yyyy`; AppInitials: two-word, single-word, punctuation stripping, ≥3-word rule, symbol-only fallback.
  - `test/core/m8_widgets_test.dart` (12) — DetailRow render + w600 default + w800 emphasis + valueColor; SheetDragHandle 40×4 + margin; SquircleIconButton: ≥48 hit box with 32dp visual, visual unchanged, **tap at center+(22,22) — inside 48-box, outside 32-visual — fires onTap**, back variant ≥48; DateSelectorStrip: every chip ≥48dp tall + tap callback.
- **Full regression:** `flutter analyze --no-pub` → **0 issues**; `flutter test` → **667/667 pass** (baseline 640 → +27; zero tests weakened — the single edited assertion was the corrected eyebrow copy [E-A1]).

## 5. Gate Evidence

- [E-G1] G1 static analysis: `flutter analyze --no-pub` → **0 issues**.
- [E-G2] G2 full suite: **667/667**.
- [E-G3] G3 debug APK: `flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`.
- [E-G4] G4 contract: **50/50 client paths** in live OpenAPI (123 ops) — unchanged by M8 (frontend-only).
- [E-G5] G5 probes: `PROBES OK (17 probes, control 404 confirmed)`.

## 6. Gaps & Backend Notes

1. **No backend asks from M8** — pure presentation work. (Standing blocked register unchanged; see checklist §BLOCKED (Syed).)
2. **DEVICE VERIFICATION BLOCKED:** device disconnected after M6 verification; M8 closes as *code-complete, DEVICE VERIFICATION BLOCKED* per checklist rule. On-device QA queued for device re-attach (contrast eyeball check, 48dp tap comfort, sheet handle feel) or M12 T0–T10.
3. **Deliberate non-changes (documented, not skipped):** `create_slot_sheet` ISO formatter (payload format); Material TextButton/ElevatedButton compact sites (≥36dp Material standard, out of cited scope); `custom_tabbar` dot (not a drag handle).

## 7. Evidence Index

- Analyze: `flutter analyze --no-pub` → 0 issues (run after every stage).
- Tests: `flutter test` 2026-09-28 → **667/667**; new: `test/core/app_utils_test.dart`, `test/core/m8_widgets_test.dart`; edited: `test/features/booking_slot/booking_slot_test.dart:591` (eyebrow copy).
- Gates: contract 50/50 · probes 17 OK · debug APK built.
- Key sources: `lib/core/constants/app_colors.dart`, `lib/core/widgets/{squircle_icon_button,detail_row,sheet_drag_handle,app_card}.dart`, `lib/core/utils/{app_dates,app_initials}.dart`, `lib/features/booking_slot/presentation/widgets/{date_selector_strip,booking_card}.dart`, `lib/features/{seed_purchase,grain_sales}/presentation/widgets/*_card.dart`, `lib/features/farmers/.../farmer_card.dart`, `lib/features/managers/.../manager_card.dart` + 22 sheet files.
