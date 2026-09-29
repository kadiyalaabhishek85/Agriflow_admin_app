# Billing Correction Sprint — Status Filter Fix & PDF Receipt Download

**Date:** 2026-09-28
**Scope:** `lib/features/billing` + billing tests only
**Backend changes:** NONE · **Database changes:** NONE
**Verdict:** READY FOR HUMAN APPROVAL

---

## 1. Symptom

Two defects reported against the Payments Desk screen:

1. **Status filter does nothing.** Tapping the `All / Completed (Paid) / Pending / Failed`
   filter chips highlights the chip, but the transaction list below does not change —
   it keeps showing the previous/unfiltered rows. The bug is intermittent: it disappears
   after a pull-to-refresh or app restart, and it is most visible right after the screen
   opens.
2. **No way to export a receipt.** The receipt bottom sheet only offered *Copy Receipt*
   (clipboard text). Users asked for a downloadable, shippable PDF invoice.

---

## 2. Root Cause

**Issue 1 — dropped reloads (primary), plus two race windows:**

`BillingController.loadTransactions` began with:

```dart
if (_isLoading) return; // original line
```

Filter changes call `loadTransactions()` again to re-fetch with the new `status`
parameter. If any load was still in flight (initial load can take seconds against a cold
Render backend, with a 15 s timeout), the filter-triggered reload was **silently
discarded**. The chip's *visual* state comes from `controller.statusFilter`, which is set
synchronously before the reload — so the UI showed the new chip while the list stayed on
the old data. Exactly the reported symptom.

Two secondary races shared the same missing guard:

- **Refresh race:** pull-to-refresh runs concurrently with a filter change; whichever
  response arrived *last* won, so a stale unfiltered response could overwrite a fresh
  filtered list.
- **Stale load-more:** `loadMoreTransactions` captured no request identity, so a page-2
  response started under an old filter could be appended to the new filter's page-1 list.

Ruled out by evidence (see §3): chip→parameter mapping, repository/datasource pass-through,
and RBAC were all correct — possibilities B (dropped reload), J (refresh race),
T (stale load-more) and M (missing generation guard) were the causes.

**Issue 2 — no backend-free export path:** the receipt was clipboard-only; PDF generation
was not implemented anywhere.

---

## 3. Evidence

- **Contract check:** `GET /api/v1/transactions` verified live against the running
  OpenAPI (fetched 2026-09-28, HTTP 200, 184 966 bytes) — `status` is a supported query
  parameter; response items carry every field the receipt needs.
- **Code trace:** chips pass `'all' | 'completed' | 'pending' | 'failed'`
  (`billing_screen.dart`); `loadTransactions` forwards
  `status: _statusFilter != 'all' ? _statusFilter : null`
  (`billing_controller.dart:95`); datasource builds `query['status']`
  (`fast_api_billing_remote_data_source.dart`). Mapping correct end-to-end.
- **Deterministic repro:** gated mock datasource parks individual requests, so races are
  reproduced on demand. Pre-fix behaviour fails the new suite; post-fix it passes.
- **Mutation testing (proof the tests detect the bugs):**
  - Re-inserted the original `if (_isLoading) return;` → **test 18
    (rapid Completed→Pending→Failed) FAILED** (requests dropped).
  - Disabled the stale-response guard (`if (generation != _requestGeneration) return;`)
    → **test 22 (stale response must not overwrite newer filter state) FAILED**.
  - Both mutations reverted; suite back to green (446/446).
- **Receipt rendered and inspected:** sample PDF generated through the production code
  path and rendered to image — see `test_output/receipt_page1.png`,
  `test_output/receipt_sample.pdf`, `test_output/receipt_text.txt`. `₹8,500` renders
  with a real rupee glyph (text extraction confirms U+20B9 present); every shown field
  matches the source `TransactionPublic` data; no fabricated fields.

---

## 4. Files Changed

**Fixed (production):**

| File | Change |
|---|---|
| `lib/.../billing/presentation/controllers/billing_controller.dart` | Request-generation guard: every page-1 load increments `_requestGeneration`; responses apply only if still current; loading flags cleared only by the current request; `loadMoreTransactions` discards appends if a newer load started. |
| `lib/.../billing/presentation/widgets/billing_card.dart` | Invoice badge wrapped in `Flexible` + ellipsis — fixed a real 412 px-width RenderFlex overflow with production-format invoice numbers (`SP-20260928-94584D0D`). |
| `lib/.../billing/presentation/widgets/billing_receipt_sheet.dart` | Converted to `StatefulWidget`: **Download Receipt** action (duplicate-tap guard, sanitized snackbars), Copy now reads the shared receipt model, sheet content wrapped in `SingleChildScrollView` (reachable on 320×568), header Row made shrink-safe (was overflowing 73 px at 320 px width). |
| `lib/.../billing/presentation/screens/billing_screen.dart` | `ValueKey('billing-filter-<status>')` on the four filter chips (+ `super.key` on `_FilterChip`) for test targeting. |

**Created:**

| File | Purpose |
|---|---|
| `lib/.../billing/domain/receipt/billing_receipt_data.dart` | Single source of truth for receipt content: `from(item)`, `toCopyText()`, `fileName`, filename sanitizer (strips path separators/traversal/reserved chars, `RECEIPT` fallback). UI, clipboard text and PDF all read this one model — they cannot disagree. |
| `lib/.../billing/domain/receipt/receipt_pdf_builder.dart` | Pure-Dart A4 PDF builder (`buildReceiptPdf`) using verified data only; footer "Generated from AgriFlow transaction record." |
| `lib/.../billing/domain/services/receipt_downloader.dart` | `ReceiptDownloader` abstraction + fixed `ReceiptMessages` (sanitized, user-facing). |
| `lib/.../billing/data/services/android_receipt_downloader.dart` | Production impl: Unicode font load → PDF → SAF save via `flutter_file_dialog`; maps failures to sanitized messages (never leaks exceptions). |
| `assets/fonts/NotoSans-Regular.ttf` | OFL Unicode font — standard PDF fonts silently drop ₹ (U+20B9), proven by probe. |
| `test/features/billing/billing_correction_sprint_test.dart` | 56 new tests (see §8). |

**Config:** `pubspec.yaml` — added `pdf 3.13.1`, `flutter_file_dialog 3.3.3`, registered
the NotoSans font. (`path_provider` was added then removed — unnecessary; SAF accepts raw
bytes.)

---

## 5. Contract Verified

From the live OpenAPI (`https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`,
fetched 2026-09-28):

- `GET /api/v1/transactions` supports `page, page_size, search, status, sort, order`.
  Response: `{success, data[], pagination{page,page_size,total,total_pages}}` with
  `id, reference_type, reference_id, farmer_id, amount, direction, status, description,
  invoice_number, created_at` per item.
- `PATCH /api/v1/transactions/{transaction_id}/pay` — used by the existing Settle flow.
- **Not in contract:** the client also sends `reference_type`, `direction`, `from_date`,
  `to_date`. FastAPI ignores unknown query params (harmless), but it means the date-range
  and type/direction filters cannot actually work server-side today. Documented as a
  limitation (§10), not touched in this sprint.
- `POST /api/v1/transactions` does **not** exist — manual transaction creation stays
  intentionally gated (LogTransactionSheet shows the backend-required notice).
- No endpoints, payloads, tables or business rules were invented.

---

## 6. The Fix (Issue 1)

```dart
int _requestGeneration = 0;

Future<void> loadTransactions({bool refresh = false}) async {
  final generation = ++_requestGeneration;   // supersede all older loads
  ...
  final result = await repository.getTransactions(... status: ...);
  if (generation != _requestGeneration) return;  // stale → discard
  _transactions = _enrichList(result.items);
  ...
  } finally {
    if (generation == _requestGeneration) {      // only current request
      _isLoading = false; _isRefreshing = false; notifyListeners();
    }
  }
}
```

- Removed the `if (_isLoading) return;` early-out — every filter change now issues its
  reload; older in-flight requests are superseded instead of suppressing newer ones.
- `loadMoreTransactions` captures `generation` before awaiting and drops its append if a
  newer page-1 load started in the meantime.
- Page semantics unchanged: page 1 always replaces the list.

---

## 7. Receipt Implementation (Issue 2)

- **Single model:** `BillingReceiptData.from(item)` — invoice number, status, amount
  (via existing `displayAmount`), date, farmer/phone (enrichment when present),
  reference ID, direction, category, description. Nothing else exists to display.
- **Download flow:** button (disabled while `_isDownloading` — duplicate taps ignored)
  → `AndroidReceiptDownloader.download` → NotoSans font from assets → `buildReceiptPdf`
  → `FlutterFileDialog.saveFile` (Storage Access Framework system picker: user chooses
  the destination, **no storage permissions needed**, works on Android 10+ scoped
  storage) → success SnackBar shows the saved path.
- **Failure handling:** PDF-generation failure, save failure, permission failure and
  user cancellation each map to a fixed sanitized message
  (`ReceiptMessages.*`) — raw exceptions are never shown.
- **Consistency:** Copy Receipt serialises the *same* `BillingReceiptData` through
  `toCopyText()`; the PDF renders the same fields (test 44 asserts they agree).
- **RBAC:** unchanged — any role that can open a receipt can copy/download it; no new
  mutation surface was added.

---

## 8. Tests

Baseline before sprint: **390**. After: **446** (390 + 56 new, zero changes to existing
tests — the 29 pre-existing billing tests still pass unmodified).

New file `test/features/billing/billing_correction_sprint_test.dart` (56 tests):

| Required coverage | Tests |
|---|---|
| Filter mapping (All→no param, Completed/Pending/Failed exact) | 1–4 |
| Filter state (reload on each chip, page reset, list replacement, empty Pending/Failed states) | 5–13 |
| Sequential filters + rapid taps (unit & widget; final state must match final filter) | 14–18 + UI group |
| Pagination (reset on filter, loadMore carries status, no duplicate page, stale refresh discarded) | 19–22 |
| Error handling (401/403/422/500/network → sanitized message, flags cleared) | 23–27 |
| Receipt data (all fields, copy-text consistency) | 28–34 |
| Filename & resilience (safe filename, sanitizer, missing description/farmer don't crash; `%PDF` header) | 35–38 |
| Download failures (PDF fail, save fail, permission, duplicate-tap guard, success writes file) | 39–42 |
| Copy & consistency (copy works, download ≡ copy data) | 43–44 |
| Responsive: BillingScreen + Receipt sheet at 320×568, 360×640, 412×860, 412×960 | 8 tests, `takeException()` null (0 RenderFlex overflows), Download button reachable/tappable |

**Final gate:**

- `flutter analyze` → **No issues found**
- `flutter test` → **446/446 passed** (baseline 390 met and exceeded)
- `flutter build apk --debug` → **Built** `app-debug.apk` (112 s, no errors)

---

## 9. Manual Device Verification Results

**NOT EXECUTED — no device available.** `adb devices` returns an empty list (no physical
device, no emulator attached). Manual Test A (filter change on device), Test B (download
receipt on device), Test C (copy receipt on device) could not be run.

Covered instead by automated equivalents: filter behaviour (tests 1–22 + 3 UI tests),
download via the real `buildReceiptPdf` with an injected SAF writer (tests 39–42),
clipboard via a mocked platform channel (tests 43–44), responsive checks at the four
required sizes. On-device sign-off remains open for the human reviewer.

---

## 10. Platform & Product Limits

- **Date-range / type / direction filters cannot work server-side** — those query
  parameters are absent from the live contract; the backend ignores them. Out of scope
  here; tracked in §11.
- **`flutter_file_dialog` applies the Kotlin Gradle Plugin** — Gradle prints a warning
  that *future* Flutter versions will fail on KGP plugins. Build succeeds today
  (`app-debug.apk` built). Watch for a compatible release when upgrading Flutter.
- **SAF picker requires a user gesture** — download opens a system save dialog by design;
  cancellation returns a friendly "canc­elled" message, not an error.
- **Clipboard in widget tests:** an unmocked `flutter/platform` channel never answers in
  `flutter test` and deadlocks — tests install a `_FakeClipboard` mock (a latent
  footgun for future tests; noted in the test file).
- Pre-existing unrelated tooling noise: "SDK XML versions up to 3" warning during build.

---

## 11. Remaining Backend Dependencies

None required for this sprint — both issues are fully resolved client-side. For
information (not blockers), tracked in `docs/backend-requirements-admin-mobile.md`:

1. `POST /api/v1/transactions` — needed before manual billing creation can be enabled.
2. Server-side `from_date` / `to_date` / `reference_type` / `direction` query support on
   `GET /transactions` — needed before those secondary filters can be trusted.
3. Optional: an explicit `status` enum in the OpenAPI schema (client currently assumes
   `pending | completed | failed`, matching live data and entity comments).

**Backend API required — to be supplied by Syed:** items 1–3 above.
