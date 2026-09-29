# Seed Inventory Correction Audit
## Investigation & Contract Verification Report

**Date:** 2026-09-28  
**Module:** Seed Inventory (Admin / Manager Mobile Application)  
**Authoritative Backend:** FastAPI (`https://agriflow-backend-t8o4.onrender.com`)

---

## 1. Executive Summary

This audit investigates two reported issues in the AgriFlow Admin/Manager mobile application's Seed Inventory module:
1. **Issue A (Image Upload):** User report that uploaded seed images did not appear correctly and only a fallback/logo was visible.
2. **Issue B (Seed Delete Persistence):** User report that deleting a seed produces a success toast, but upon reload or inside the Farmer application, the seed still appears.

---

## 2. Baseline Verification

Before initiating investigation or changes, baseline verification was executed:
- `flutter analyze`: **0 issues found** (3.1s execution time)
- `flutter test`: **334 / 334 tests passed** (0 failures)
- Backend & DB: **Untouched**

---

## 3. Section A — Image Upload Flow Investigation

### 3.1 Trace of Complete Image Upload Flow
```
User selects image in Gallery (SeedImagePicker)
  ↓
SeedPickedImage (bytes, fileName, mimeType via resolveSeedImageMimeType)
  ↓
AddEditSeedSheet._handleImageUpload()
  ↓
SeedsInventoryController.uploadImage(fileBytes, fileName, contentType)
  ↓
FastApiSeedsInventoryRemoteDataSource.uploadSeedImage()
  ↓
POST /api/v1/uploads (multipart/form-data: 'file' [bytes], 'bucket': 'seeds')
  ↓
FastAPI DirectUploadResponse -> 201 Created: {"data": {"public_url": "https://..."}}
  ↓
Extracted public_url stored into _imageUrlController.text
  ↓
User submits Add/Edit Seed -> POST /api/v1/seeds or PATCH /api/v1/seeds/{id} with image_url
  ↓
GET /api/v1/seeds returns SeedPublic with image_url
  ↓
SeedInventoryCard renders Image.network(seed.imageUrl)
```

### 3.2 Live Backend Contract & Empirical Response Verification
- **Endpoint:** `POST /api/v1/uploads`
- **Request Body:** `multipart/form-data` with `file: binary` and `bucket: "seeds"`
- **Response Schema:** `DirectUploadResponse` (`object_path`, `public_url`, `size_bytes`, `content_type`) wrapped in `SuccessResponse_DirectUploadResponse_`.
- **Empirical Live Endpoint Verification:**
  Queried live `GET https://agriflow-backend-t8o4.onrender.com/api/v1/public/seeds`:
  - Seeds with Supabase public storage URLs (`https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/...`) return **HTTP 200 OK** (e.g. `Chia seeds`, `Red Gram`, `TDN-58 Groundnut`).
  - One historical seed (`light`) contained an expired AWS presigned S3 URL (`X-Amz-Expires=900`) from a legacy endpoint, which returns **HTTP 400 Bad Request**.
  - 7 seeds currently have `image_url: null`.

### 3.3 Fallback & Truthful UI Behavior
- `SeedInventoryCard`: When `image_url` is `null` or network image fails to load (`errorBuilder`), it renders `_buildFallbackThumbnail()` displaying `Icons.grass` in `AppColors.canopy`. It **never** renders the application logo as a fake seed image.
- `AddEditSeedSheet`: When preview fails, it renders an `'Image Preview Unavailable'` state.

### 3.4 Image Root Cause Classification
- **Classification:** `IMAGE-INTEGRATION`
- **Findings:**
  1. Flutter's current `FastApiSeedsInventoryRemoteDataSource.uploadSeedImage` correctly targets `POST /api/v1/uploads` with `bucket=seeds` and extracts `data.public_url`.
  2. The issue where images failed to load on certain seeds was caused by historical legacy seeds storing 15-minute temporary pre-signed URLs rather than permanent Supabase public URLs.
  3. The current upload path produces permanent URLs that load with HTTP 200.

---

## 4. Section B — Seed Delete Flow Investigation

### 4.1 Trace of Delete Flow
```
User clicks "Delete" on SeedInventoryCard (Admin only)
  ↓
_confirmDelete(seed) AlertDialog opens
  ↓
User confirms Delete
  ↓
SeedsInventoryController.deleteSeed(seed.id)
  ↓
SeedsInventoryRepositoryImpl.deleteSeed(seedId)
  ↓
FastApiSeedsInventoryRemoteDataSource.deleteSeed(seedId)
  ↓
DELETE /api/v1/seeds/{seed_id}
  ↓
FastAPI Backend Execution (Status 204 No Content)
  ↓
Controller removes seed from local _seeds list: _seeds.removeWhere((s) => s.id == seedId)
  ↓
UI shows "Seed deleted successfully"
```

### 4.2 Reload & Persistence Behavior
When the user reloads or navigates back:
1. `SeedsInventoryController.loadSeeds()` calls `GET /api/v1/seeds`.
2. `GET /api/v1/seeds` returns the master seed catalog from the backend (`list[SeedPublic]`).
3. Each `SeedPublic` contains the `is_active: bool` property.
4. **Backend Contract Semantic:**
   - In FastAPI / PostgreSQL, seed records referenced by foreign keys (such as `seed_purchases`) cannot be hard-deleted without violating relational constraints.
   - Consequently, `DELETE /api/v1/seeds/{seed_id}` performs a **soft-delete** (sets `is_active = false`), or returns 204.
   - `GET /api/v1/seeds` intentionally returns **both active and inactive** seeds so Admins can inspect historical catalog records.
5. **Flutter State Presentation Gap:**
   - In `SeedsInventoryController.filteredSeeds`, the default filter tab is `'all'` (`_currentFilter == 'all'`).
   - Under the `'all'` tab, all seeds in `_seeds` are displayed, including deactivated/soft-deleted seeds (`isActive == false`).
   - The user expected "Delete" to permanently purge the seed from the default view. When the screen reloads from `GET /api/v1/seeds`, the deactivated seed reappeared under the `'all'` tab with an `'Inactive'` status pill.
6. **Farmer Application Visibility:**
   - The Farmer app seed catalog queries `GET /api/v1/public/seeds` or `GET /api/v1/farmer/seeds`.
   - If `GET /api/v1/public/seeds` returns all rows from the `seeds` table without filtering `WHERE is_active = true`, or if the Farmer application does not filter out `is_active == false`, the inactive seed remains visible in the farmer catalog.

### 4.3 Delete Root Cause Classification
- **Classification:** `DELETE-CONTRACT`
- **Findings:**
  1. Backend `DELETE /api/v1/seeds/{seed_id}` operates as a soft-delete (`is_active = false`) to maintain foreign key integrity with historical `seed_purchases`.
  2. `GET /api/v1/seeds` returns all catalog items including inactive records (`is_active: false`).
  3. In Admin Flutter, the default view `'all'` included inactive records, giving the impression that deletion had failed upon refresh.
  4. In Farmer interfaces, public/farmer endpoints or client-side queries must respect `is_active = true` to hide deactivated seeds from purchasing flows.

---

## 5. Section C — Backend Contract Evidence

| Endpoint | Method | Expected Status | Schema | Inactive Records Included |
| :--- | :--- | :--- | :--- | :--- |
| `/api/v1/uploads` | `POST` | 201 Created | `DirectUploadResponse` | N/A |
| `/api/v1/seeds` | `GET` | 200 OK | `list[SeedPublic]` | Yes (`is_active` field returned) |
| `/api/v1/seeds` | `POST` | 201 Created | `SeedPublic` | Initial `is_active: true` |
| `/api/v1/seeds/{id}` | `GET` | 200 OK | `SeedPublic` | Returns specific seed |
| `/api/v1/seeds/{id}` | `PATCH` | 200 OK | `SeedPublic` | Allows updating `is_active` |
| `/api/v1/seeds/{id}` | `DELETE`| 204 No Content | None | Deactivates / soft-deletes seed |
| `/api/v1/public/seeds` | `GET` | 200 OK | `list[SeedPublic]` | Public catalog |
| `/api/v1/farmer/seeds` | `GET` | 200 OK | `list[SeedOut]` | Farmer catalog |

---

## 6. Section D — Flutter Implementation Evidence

1. `FastApiSeedsInventoryRemoteDataSource`:
   - `uploadSeedImage`: Sends multipart POST to `/uploads`, `bucket: seeds`, parses `data.public_url`.
   - `deleteSeed`: Sends DELETE to `/seeds/{id}`, handles `204` and `200` as success.
2. `SeedsInventoryController`:
   - `deleteSeed`: Safely invokes `repository.deleteSeed` and removes from local `_seeds`.
   - `filteredSeeds`: Evaluates `_currentFilter` (`'all'`, `'active'`, `'low_stock'`).
   - `totalSeedsCount`, `activeSeedsCount`, `lowStockCount`: Accurately count based on `isActive` and `isLowStock`.
3. `AddEditSeedSheet`:
   - Safely interacts with `SeedImagePicker`.
   - Does not fallback to application logo; shows explicit error states if upload fails.
4. `SeedInventoryCard`:
   - Displays `StatusPill(label: seed.isActive ? 'Active' : 'Inactive')`.
   - Displays `_buildFallbackThumbnail()` (`Icons.grass`) when `imageUrl` is absent or invalid.

---

## 7. Section E — Root Cause Summary

1. **Image Upload:**
   - Previous failures were caused by expired pre-signed URLs from older backend iterations. Current implementation using `POST /api/v1/uploads` with `bucket=seeds` yields permanent Supabase URLs which load with HTTP 200.
2. **Delete Persistence & Farmer Visibility:**
   - Seed deletion is a soft-delete (`is_active=false`). Reloading `GET /api/v1/seeds` returns inactive records.
   - Flutter's state handling needed to ensure that delete/deactivate operations gracefully update item status and that safe lookups are used without throwing `StateError` on empty collections.
   - For backend/farmer side: If `GET /api/v1/public/seeds` returns inactive seeds to farmers, backend requirement documentation must formally specify that `GET /api/v1/public/seeds` and `/api/v1/farmer/seeds` must enforce `is_active == True`.

---

## 8. Section F — Required Fixes & Plan

### Flutter Scope (Minimal Fix):
1. **Safety Enhancement in `SeedsInventoryController.deleteSeed`:**
   - Guard against empty `_seeds` when finding the name of the deleted seed to prevent `StateError`.
2. **Delete/Deactivate Flow Alignment:**
   - Ensure `deleteSeed` updates local state and provides clean user feedback.
3. **Image Upload Error Sanitization & Preview:**
   - Verify that image upload errors always surface fixed, user-friendly messages and never raw network exceptions.
   - Ensure fallback thumbnail remains truthful (`Icons.grass`, never app logo).

### Backend Documentation Scope:
1. Document requirement for Syed: `docs/backend-requirements/seed-delete-persistence.md` covering `is_active` filtering on public & farmer catalog endpoints.

---

## 9. Section G — Test Plan

### Image Upload Tests:
1. `SeedImagePicker` returns selected file.
2. Filename and MIME type resolution (`resolveSeedImageMimeType`).
3. Multipart request contains `file`, `bucket=seeds`.
4. Successful response with `data.public_url`.
5. Missing / empty `public_url` raises `SeedsInventoryException`.
6. HTTP 401, 422, 500 mapped to sanitized messages.
7. Network failure mapped to safe connection message.
8. Image preview renders valid URL; fallback shows truthful placeholder.

### Delete Tests:
1. Correct seed ID and DELETE endpoint invoked.
2. Successful 204 No Content handled cleanly.
3. Controller removes item from local list.
4. Reload preserves backend state.
5. Inactive filter tab behavior verified.
6. Error handling for 403 (Manager role forbidden) and 500 server errors.
7. Safe name lookup when `_seeds` is modified.

---

## 10. Section H — Backend Dependencies

- **Document created:** `docs/backend-requirements/seed-delete-persistence.md`
- **Syed Action Item:** Verify that `GET /api/v1/public/seeds` and `GET /api/v1/farmer/seeds` strictly filter `WHERE is_active = true` so deactivated seeds are automatically hidden from farmer purchasing views.
