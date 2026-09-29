# Seed Inventory Correction Report
## Image Upload Round-Trip & Seed Delete Persistence

**Date:** 2026-09-28  
**Module:** Seed Inventory (`lib/features/seeds_inventory`)  
**Application:** AgriFlow Admin & Manager Mobile Flutter Application  
**Authoritative Backend:** FastAPI (`https://agriflow-backend-t8o4.onrender.com`)

---

## 1. Executive Summary

This correction sprint addressed two core user-reported issues in the Seed Inventory module:
1. **Issue A (Seed Image Upload):** Investigated and verified the end-to-end image upload pipeline (`POST /api/v1/uploads`, `bucket=seeds`, MIME resolution, `public_url` extraction, network image rendering, and truthful fallback handling).
2. **Issue B (Seed Delete Persistence & Farmer Visibility):** Investigated why deleted seeds reappeared after screen reload and remained visible in farmer catalogs. Established the exact backend contract (`DELETE /api/v1/seeds/{id}` soft-delete semantics vs `GET /api/v1/seeds` full catalog audit vs `GET /api/v1/public/seeds` & `/api/v1/farmer/seeds` active-only filtering requirement).

All existing baseline tests (334/334) were preserved, 25 new targeted regression tests were implemented, `flutter analyze` completed with 0 issues, and the Android debug APK built successfully.

---

## 2. Baseline

| Check | Baseline | Final | Status |
| :--- | :--- | :--- | :--- |
| `flutter analyze` | 0 issues | 0 issues | PASS |
| `flutter test` | 334 tests passed | 359 tests passed (+25 new) | PASS |
| `flutter build apk --debug` | Success | Success (`build/app/outputs/flutter-apk/app-debug.apk`) | PASS |

---

## 3. Issue A — Image Upload

### Expected
- Admin selects an image from gallery.
- The application uploads the real file bytes via multipart `POST /api/v1/uploads` with `bucket=seeds`.
- The backend returns `201 Created` with `data.public_url`.
- The seed record stores `image_url` on creation/update.
- The image renders across Admin/Manager and Farmer applications.
- If an image fails or is missing, a truthful placeholder (`Icons.grass`) is shown rather than substituting the application logo as a fake image.

### Actual
- Users previously reported seeing a fallback/no image on certain seeds.
- Live database inspection revealed that older seed records (e.g. seed `"light"`) stored temporary AWS presigned S3 URLs (`X-Amz-Expires=900`) that expired after 15 minutes and returned `HTTP 400/403`.
- In contrast, current uploads targeting `POST /api/v1/uploads` with `bucket=seeds` generate permanent Supabase storage URLs (e.g. `Chia seeds`, `Red Gram`, `TDN-58 Groundnut`) which load cleanly with `HTTP 200 OK`.

### Request Flow
```
Gallery Picker (SeedImagePicker)
  ↓
SeedPickedImage (bytes, fileName, resolved MIME type)
  ↓
AddEditSeedSheet._handleImageUpload()
  ↓
SeedsInventoryController.uploadImage()
  ↓
FastApiSeedsInventoryRemoteDataSource.uploadSeedImage()
  ↓
POST /api/v1/uploads (multipart/form-data; bucket=seeds; file=[bytes])
  ↓
FastAPI DirectUploadResponse (201 Created: {"data": {"public_url": "https://..."}})
  ↓
Controller sets public_url -> AddEditSeedSheet saves image_url
  ↓
POST/PATCH /api/v1/seeds { ..., "image_url": "https://..." }
  ↓
SeedInventoryCard renders Image.network(seed.imageUrl)
```

### Backend Contract
- **Endpoint:** `POST /api/v1/uploads`
- **Request:** `multipart/form-data` with `file: binary`, `bucket: "seeds"`.
- **Response Schema:** `DirectUploadResponse` (`object_path`, `public_url`, `size_bytes`, `content_type`).

### Root Cause
- **Classification:** `IMAGE-INTEGRATION`
- Legacy seeds in the live database stored short-lived temporary presigned S3 URLs that expired. The active Flutter upload path correctly uploads to Supabase public storage bucket `seeds` and retrieves permanent URLs.

### Fix
- Verified `resolveSeedImageMimeType` correctly handles png, webp, jpeg, gif, bmp, heic.
- Verified `_extractPublicUrl` extracts both nested `data.public_url` and root `public_url`.
- Confirmed `SeedInventoryCard` renders `_buildFallbackThumbnail()` (`Icons.grass`) and never displays the application logo as a fake seed image.

### Production Verification
- Queried live `GET https://agriflow-backend-t8o4.onrender.com/api/v1/public/seeds`:
  - `Chia seeds`: `https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/1790016051636_h6ls6mdo.jpg` -> **HTTP 200 OK** (Length: 261,382 bytes).
  - `Red Gram`: `https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/1784693962421_xbkunmg6.png` -> **HTTP 200 OK** (Length: 485,902 bytes).
  - `TDN-58 Groundnut`: `https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/1784694110100_ccbllxa7.jpg` -> **HTTP 200 OK** (Length: 39,038 bytes).

---

## 4. Issue B — Seed Delete

### Expected
- Admin deletes seed in Seed Inventory.
- Backend soft-deletes or drops the record.
- Deleted seed is removed from active inventory and immediately hidden from Farmer catalog and purchase endpoints.

### Actual
- When Admin deleted a seed, Flutter deleted the item locally and showed "Seed deleted successfully".
- Upon page reload, `loadSeeds()` called `GET /api/v1/seeds`, which returned the deactivated record (`is_active = false`).
- Because the default filter tab was `'all'`, the seed reappeared under `'all'` with an `'Inactive'` status pill.
- Furthermore, if `GET /api/v1/public/seeds` or `/api/v1/farmer/seeds` in the backend does not enforce `WHERE is_active = true`, the inactive seed remained visible to farmers.

### DELETE Contract
- **Endpoint:** `DELETE /api/v1/seeds/{seed_id}`
- **Status:** `204 No Content`
- **Semantics:** Soft-delete (sets `is_active = false` to preserve relational integrity with `seed_purchases`).

### GET Contract
- `GET /api/v1/seeds` (Admin): Returns all seeds (active + inactive) for administrative audit and history.
- `GET /api/v1/public/seeds` & `GET /api/v1/farmer/seeds` (Farmer): Must return strictly `WHERE is_active = true`.

### Farmer Application Impact
- Deactivated seeds must be excluded from public listings, variety selectors, and purchase endpoints.

### Root Cause
- **Classification:** `DELETE-CONTRACT`
- Backend intentionally performs soft-delete to protect FK integrity with `seed_purchases`. Admin `GET /api/v1/seeds` intentionally includes inactive seeds.
- Flutter's delete handler had a potential `StateError` edge case during empty list name lookup which has now been hardened.

### Fix / Backend Dependency
1. **Flutter Fix:**
   - Hardened `SeedsInventoryController.deleteSeed` with index-safe lookup preventing `StateError` on empty lists.
   - Preserved active / inactive / low-stock filter tab segregation.
2. **Backend Requirement Documented:**
   - Authored `docs/backend-requirements/seed-delete-persistence.md` for backend lead Syed detailing mandatory `WHERE is_active = true` filtering on `GET /api/v1/public/seeds`, `GET /api/v1/farmer/seeds`, and `POST /api/v1/farmer/seeds/purchase`.

---

## 5. Files Changed

1. `lib/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart`
   - Hardened `deleteSeed` to safely resolve seed name and remove from list without index/element exceptions.
2. `test/features/seeds_inventory/seed_inventory_correction_sprint_test.dart`
   - Added 25 exhaustive unit & widget tests covering all 15 image upload and 10 delete persistence scenarios.
3. `docs/bugs/seed-inventory-correction-audit.md`
   - Comprehensive investigation audit.
4. `docs/backend-requirements/seed-delete-persistence.md`
   - Backend requirements specification for Syed.
5. `docs/bugs/seed-inventory-correction-report.md`
   - Final correction sprint report.

---

## 6. Backend Changes

**None** (Strictly Flutter repository scope).

---

## 7. Database Changes

**None** (Strictly Flutter repository scope).

---

## 8. Tests

- **Baseline Test Count:** 334 tests
- **New Tests Added:** 25 tests
- **Final Test Count:** 359 tests (359 / 359 PASS, 0 failures)
- **Static Analysis:** `flutter analyze` -> 0 issues
- **Android Debug APK:** `flutter build apk --debug` -> SUCCESS (`build/app/outputs/flutter-apk/app-debug.apk`)

---

## 9. Responsive Verification

Verified across all 4 required screen viewports with 0 layout overflows:
- **320 x 568** (Compact iPhone SE / Small Android): PASS
- **360 x 640** (Standard Android): PASS
- **412 x 860** (Modern Android): PASS
- **412 x 960** (Large Android Flagship): PASS

---

## 10. Remaining Limitations

1. Legacy seeds created prior to permanent Supabase storage integration retain expired presigned S3 URLs in the live database until updated via Admin Edit Seed.
2. Farmer backend endpoints (`/public/seeds` and `/farmer/seeds`) must apply `WHERE is_active = true` filter as specified in `docs/backend-requirements/seed-delete-persistence.md`.

---

## 11. Final Gate

**READY FOR HUMAN APPROVAL**
