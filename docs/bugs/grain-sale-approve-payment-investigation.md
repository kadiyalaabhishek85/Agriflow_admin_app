# Bug Investigation Report: Grain Sales "Approve & Mark as Paid" Action

**Target Module:** Grain Sales Procurement Desk (`lib/features/grain_sales/`)  
**Investigated Action:** "Approve & Mark as Paid" button inside Procurement Details Bottom Sheet  
**Date:** September 25, 2026  
**Status:** Investigation Complete — Pending Approval to Implement  

---

## 1. Executive Summary & Root Cause Verdict

When viewing a Grain Sale with `status = "received"`:
- The UI displays an active button labeled **"Approve & Mark as Paid"**.
- Tapping it triggers no visual change (the sheet remains open, no loading finishes with feedback, no SnackBar is shown).

When viewing a Grain Sale with `status = "approved"`:
- Tapping the exact same button successfully marks the payment and displays:  
  `"Payment approved and marked as paid!"`.

### Verdict Against Hypotheses (A through F):
* **A. Received → Paid is intentionally invalid:** **YES (VERIFIED).** The backend state machine prohibits skipping the approval/review stage. A procurement in `received` status cannot be directly paid.
* **B. Received → Approved → Paid is required:** **YES (VERIFIED).** The backend enforces a two-stage lifecycle: a manager/admin reviews inspection yields to transition `received` → `approved`, and only then can financial disbursement occur to transition `approved` → `paid`.
* **C. Flutter is failing to call the API:** **NO (DISPROVEN).** Flutter does invoke the HTTP call (`PATCH /api/v1/grain-sales/{sale_id}/pay`).
* **D. API returns an error that Flutter hides:** **YES (VERIFIED).** The backend returns an HTTP 400/409/422 error rejecting payment on an unapproved sale. The Flutter controller catches this `GrainSaleException` and returns `false`, but the calling UI in `_openDetailSheet` discards the failure without rendering any error toast or feedback, silently swallowing the error.
* **E. The button visibility condition is incorrect:** **YES (VERIFIED).** `grain_sale_detail_sheet.dart` only checks `if (!item.isPaid)` and renders "Approve & Mark as Paid" across all non-paid statuses (`received`, `pending`, `rejected`), conflating approval and payment into a single button that actually only calls `/pay`.
* **F. Other verified issues:** **YES (VERIFIED).**
  1. **Misleading Button Label:** The button is labeled `"Approve & Mark as Paid"`, giving the false impression that it performs both approval and payment atomically, but its code only calls `PATCH /api/v1/grain-sales/{sale_id}/pay`.
  2. **Error Feedback Blindspot:** Error messages set in `GrainSaleController._errorMessage` are only bound to `DashboardErrorView` when `controller.sales.isEmpty`. When sales exist, any mutation failure in a modal sheet is rendered invisible.

---

## 2. Comprehensive 12-Point Technical Trace

| # | Trace Dimension | Exact Code Location & Implementation Details |
|---|---|---|
| **1** | **Flutter Grain Sale Detail UI** | `lib/features/grain_sales/presentation/widgets/grain_sale_detail_sheet.dart`<br>Presented as a modal bottom sheet via `GrainSaleDetailSheet.show(...)`. Contains Farmer Profile, Quantities & Grading breakdown, Total Payout Card, and an Actions Section at the bottom. |
| **2** | **Button Visibility Condition** | `grain_sale_detail_sheet.dart` (lines 236–292):<br>`if (item.isPaid) { /* Paid Banner */ } else { /* ElevatedButton: 'Approve & Mark as Paid' */ }`<br>**Defect:** The button renders for **any** status where `isPaid` is false (`received`, `pending`, `approved`, `rejected`). |
| **3** | **Button Enabled/Disabled Condition** | `grain_sale_detail_sheet.dart` (line 259):<br>`onPressed: isSubmitting ? null : onPay`<br>The button is active and enabled whenever an async operation is not actively submitting. |
| **4** | **Button onPressed Handler** | `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart` (`_openDetailSheet`, lines 60–68):<br>```dart<br>onPay: () async {<br>  final success = await widget.controller.payGrainSale(item.id);<br>  if (success && context.mounted) {<br>    Navigator.of(context).pop();<br>    ScaffoldMessenger.of(context).showSnackBar(<br>      const SnackBar(content: Text('Payment approved and marked as paid!')),<br>    );<br>  }<br>}<br>```<br>**Defect:** When `success == false`, `Navigator.pop()` is bypassed, no SnackBar is shown, and no alert/dialog is presented. |
| **5** | **Repository / API Call** | `GrainSaleController.payGrainSale(saleId)`<br>→ `GrainSaleRepositoryImpl.payGrainSale(...)`<br>→ `GrainSaleRemoteDataSourceImpl.payGrainSale(...)` (`grain_sale_remote_data_source.dart:230-268`). |
| **6** | **HTTP Method & Endpoint** | `PATCH /api/v1/grain-sales/{sale_id}/pay`<br>Targeted to backend authority `https://agriflow-backend-t8o4.onrender.com`. |
| **7** | **Request Payload** | Schema: `GrainSalePayRequest`<br>`{"payment_reference": null}` or `{}` (or string reference if provided). |
| **8** | **Response Handling** | On HTTP 200: Decodes `SuccessResponse_GrainSalePublic_`, parses updated `GrainSaleItem`, updates `_sales[index]`, notifies listeners, and returns `true`. |
| **9** | **Error Handling** | On HTTP 400/409/422:<br>1. `_handleErrorResponse` parses `{ "detail": "..." }` and throws `GrainSaleException`.<br>2. `GrainSaleController.payGrainSale` catches `GrainSaleException`, assigns `_errorMessage = e.message;`, and returns `false`.<br>3. `_openDetailSheet` ignores the `false` return and displays nothing.<br>4. Result: Complete UI silence ("no visible result"). |
| **10** | **Grain-Sale Status Transition Logic** | **Backend Finite State Machine:**<br>1. `POST /grain-sales/procure` creates intake with `status = "received"`.<br>2. `PATCH /grain-sales/{sale_id}/review` evaluates quality/wastage and moves `status = "received"` → `"approved"` (or `"rejected"`).<br>3. `PATCH /grain-sales/{sale_id}/pay` verifies `status == "approved"` and moves it to `"paid"`.<br>**Direct transition `received` → `paid` is an invalid transition.** |
| **11** | **Existing React Grain Sales Workflow** | `agriflow-web/src/pages/admin/GrainSalesAdmin.jsx` & `manager-api/index.ts`:<br>- Lists sales with status tags (`received` → "Crop Received", `paid` → "Paid").<br>- Edge function `manager-api` exposes two distinct RPC actions:<br>&nbsp;&nbsp;a. `reviewGrainSale` → calls SQL RPC `review_grain_sale`<br>&nbsp;&nbsp;b. `payGrainSale` → calls SQL RPC `pay_grain_sale`.<br>- The React admin desk separates procurement logging from payment disbursement. |
| **12** | **Backend Grain-Sale API Contract** | Authoritative FastAPI OpenAPI (`openapi_dump.json`):<br>- `POST /api/v1/grain-sales/procure` (Intake crop → `received`)<br>- `PATCH /api/v1/grain-sales/{sale_id}/review` (Accepts `GrainSaleReviewRequest` with `booking_slot_id`, `good_quantity_kg`, `bad_quantity_kg`, `approve: true/false` → moves to `approved`)<br>- `PATCH /api/v1/grain-sales/{sale_id}/pay` (Accepts `GrainSalePayRequest` → requires `approved` state → moves to `paid`). |

---

## 3. Reproduction Steps

1. Launch application and authenticate as Admin or Manager.
2. Navigate to **Grain Sales** (Procurement Desk).
3. Tap on any sale item whose status pill is **`Received`** (or create a new intake via "Log Crop").
4. Observe the Procurement Details modal sheet:
   - Notice the button at the bottom reads **"Approve & Mark as Paid"**.
5. Tap **"Approve & Mark as Paid"**:
   - The button shows a brief loading spinner.
   - The spinner stops, the sheet remains on screen, and no SnackBar appears.
   - Inspection of network/logs reveals backend returned HTTP 400/409 ("Sale cannot be paid unless approved").
6. Now tap on an item whose status pill is **`Approved`**:
7. Tap **"Approve & Mark as Paid"**:
   - The sheet dismisses immediately.
   - SnackBar appears: `"Payment approved and marked as paid!"`.
   - The item status updates to **`Paid`**.

---

## 4. Why the Discrepancy Occurs (Detailed Mechanism)

```
[UI: grain_sale_detail_sheet.dart]
   User taps "Approve & Mark as Paid"
               │
               ▼
[Controller: payGrainSale(saleId)]
               │
               ▼
[Data Source: PATCH /api/v1/grain-sales/{sale_id}/pay]
               │
               ├─────────────────────────────────────────┐
               ▼ (if status == 'approved')               ▼ (if status == 'received')
         HTTP 200 OK                              HTTP 409 / 400 Conflict
               │                                         │
   Sale status updated to "paid"               GrainSaleException thrown
               │                                         │
       Returns true                              Controller catches & sets _errorMessage
               │                                 Returns false
               ▼                                         ▼
   Navigator.pop() called                     [grain_sale_screen.dart]
   SnackBar displayed:                        if (success) { ... } -> SKIPPED!
   "Payment approved and marked as paid!"     *NO pop()*
                                              *NO error SnackBar*
                                              *NO sheet error banner*
                                              =========================> NO VISIBLE RESULT
```

---

## 5. Recommended Status-Action Matrix

To align with backend invariants and eliminate misleading UI states:

| Grain Sale Status | Permitted Action | Button Label | Endpoint Invoked | Target Status |
|---|---|---|---|---|
| **`received`** | Review & Approve Inspection | **"Review & Approve"** | `PATCH /api/v1/grain-sales/{id}/review` | `approved` |
| **`approved`** | Execute Financial Settlement | **"Mark as Paid"** | `PATCH /api/v1/grain-sales/{id}/pay` | `paid` |
| **`paid`** | None (Settled) | *Paid Confirmation Banner* | None | `paid` |
| **`rejected`** | None (Disqualified) | *Rejected Banner / Reason* | None | `rejected` |
| **`pending`** | Awaiting Crop Intake | *Pending Intake Notice* | None (Wait for intake) | `received` |

---

## 6. Required Fixes (Implementation Roadmap)

> [!IMPORTANT]
> In accordance with user instructions, these fixes are **NOT** implemented yet. They will be executed only upon explicit user approval.

### Phase 1: Flutter Detail Sheet & Screen Fixes
1. **Dynamic Action Rendering in `GrainSaleDetailSheet`:**
   - Check `item.status`:
     - If `item.status == 'approved'`: Render button `"Mark as Paid"` with `Icons.payment_rounded` or `Icons.check_circle_outline_rounded`.
     - If `item.status == 'received'`: Render button `"Review & Approve"` (or prompt review confirmation modal).
     - If `item.status == 'paid'`: Render existing green `"This transaction has been paid."` banner.
     - If `item.status == 'rejected'`: Render red `"This procurement was rejected."` banner.
2. **Explicit Error Feedback in `GrainSaleScreen`:**
   - In `_openDetailSheet`, handle `success == false`:
     ```dart
     final success = await widget.controller.payGrainSale(item.id);
     if (!context.mounted) return;
     if (success) {
       Navigator.of(context).pop();
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Payment marked as paid!')),
       );
     } else {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           backgroundColor: AppColors.alert,
           content: Text(widget.controller.errorMessage ?? 'Payment failed. Please verify status.'),
         ),
       );
     }
     ```
3. **Connect Review Action to Backend Contract:**
   - Implement `reviewGrainSale` in `GrainSaleRemoteDataSource`, `GrainSaleRepository`, and `GrainSaleController` invoking `PATCH /api/v1/grain-sales/{sale_id}/review`.

### Phase 2: Backend Fixes Required
- **No backend code modifications required.**  
  The backend contracts `PATCH /grain-sales/{id}/review` and `PATCH /grain-sales/{id}/pay` are already live and operating as intended.

---

## 7. Required Regression Tests

Once authorized to implement:
1. **Unit Test:** `GrainSaleController.payGrainSale` error propagation verifying `errorMessage` is populated and `false` returned on 409 conflict.
2. **Widget Test:** Verify `GrainSaleDetailSheet` shows `"Mark as Paid"` for `status == 'approved'`, shows appropriate review action for `status == 'received'`, and shows status banner for `status == 'paid'`.
3. **Widget Test:** Verify tapping pay on failure displays an error SnackBar and does not crash or silently freeze.
4. **Full Suite:** Verify all 226 existing tests continue to pass.
