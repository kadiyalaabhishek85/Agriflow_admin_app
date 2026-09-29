# Seed Inventory Image Upload — Flutter-Only Fix Report

**Status:** Flutter implementation complete. Backend contract assumed correct per scope guard; no live production upload was performed.

---

## 1. Root Cause

The Seed Inventory "Upload Image" button never uploaded a real image:

1. **Fake upload** — `_handleSampleUpload` in `add_edit_seed_sheet.dart` skipped the picker entirely and sent a hardcoded 1×1 transparent PNG byte array, so the server always stored a placeholder.
2. **`contentType` dropped** — `SeedsInventoryRepositoryImpl.uploadSeedImage` accepted `contentType` but never forwarded it, and the data source defaulted every part to `image/jpeg` regardless of the actual file.
3. **Silent null** — `SeedsInventoryController.uploadImage` swallowed exceptions (`return null`), so the sheet could only show a generic failure with no status-specific reason.
4. **No `public_url` guard** — a 2xx response without `data.public_url` / `public_url` was treated as success with an empty URL.
5. **Leak path** — `ErrorSanitizer.sanitize` has a message-passthrough branch that can surface raw exception text; upload-path fallbacks previously used it.

## 2. Files Changed

| File | Change |
|---|---|
| `pubspec.yaml` | Added `image_picker: ^1.1.0` (resolved 1.2.3), `http_parser: ^4.0.0` (resolved 4.1.2) |
| `lib/features/seeds_inventory/presentation/widgets/seed_image_picker.dart` | **NEW** — `resolveSeedImageMimeType()`, `SeedPickedImage`, injectable `SeedImagePicker` (gallery-only) |
| `lib/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart` | `_handleSampleUpload` → `_handleImageUpload` (:315-350); `onUploadImage` callback gained `contentType`; injectable `imagePicker` (:56-57, :101, :108); upload button disabled while `_isUploading` (:686) |
| `lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart` | `uploadSeedImage` (:446-487): applied `MediaType.parse(contentType)` (:460), `_extractPublicUrl` (:491-500), `_uploadErrorMessage` (:504-517), network catch → fixed message (:478-485) |
| `lib/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart` | `uploadImage` (:287-316) sets `errorMessage` and **rethrows**; generic catch → fixed `ErrorSanitizer.genericErrorMessage` (:307-311) |
| `lib/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart` | Both `onUploadImage` closures (:117-121, :196-200) now declare and forward `contentType` |
| `test/features/seeds_inventory/seeds_inventory_test.dart` | New group **"Milestone 5 — Seed Image Upload Fix"** — 15 tests |

## 3. Real Image Picker

- New `seed_image_picker.dart` wraps `ImagePicker().pickImage(source: ImageSource.gallery)` — **gallery only, no camera**.
- `pick` is injectable (`SeedImagePickFn`), so widget tests supply a controlled double instead of a platform channel.
- Cancel (`null`) is handled silently: upload state resets, no error shown, button returns to idle.
- MIME resolution (`resolveSeedImageMimeType`): declared type wins unless it is empty/`application/octet-stream`, then extension map (`png/webp/gif/heic/heif/bmp/jpg/jpeg`), then `image/jpeg`.
- **No Android/iOS manifest/Info.plist permission changes** were required — `image_picker` needs none, and only `INTERNET` exists in the manifest.

## 4. Multipart Request (Contract-Faithful)

`POST /api/v1/uploads` (`fast_api_seeds_inventory_remote_data_source.dart:453-461`):

- `Authorization: Bearer <token>` header.
- Field `bucket` = `seeds`.
- File part `file` with picked `filename` and `contentType: MediaType.parse(contentType)` — the picked image's real type is applied, not a hardcoded default.
- Response parsed for `data.public_url` first, then root-level `public_url` (empty-tolerant trim). A URL is **never constructed** by the client.

## 5. Error Handling

Fixed, spec-exact messages (tested against hostile backend detail strings):

| Condition | Message |
|---|---|
| HTTP 401 | `Image upload is not authorized.` |
| HTTP 422 | `Image upload was rejected by the server.` |
| HTTP 5xx | `Image upload service is temporarily unavailable.` |
| `SocketException` / `TimeoutException` | `Unable to upload image. Check your connection.` |
| 2xx missing usable `public_url` | `Image upload completed, but the server did not return a public image URL.` |

- Data source wraps every upload-path exception through `_uploadErrorMessage` (:504-517): 403/404/409 use `ErrorSanitizer.sanitize` (those statuses have fixed constants there), **any other status → `ErrorSanitizer.genericErrorMessage`** — never passthrough.
- Controller (`:304-311`) and sheet (`:345-348`) catch typed exceptions (show `e.message` inline) and route generic `catch` to `ErrorSanitizer.genericErrorMessage` — **no raw exception text can reach the UI**.
- Controller now **rethrows** after setting `errorMessage`, so the sheet shows the real cause instead of a silent null.

## 6. Public URL Handling

- `_extractPublicUrl` (:491-500): `data.public_url` → root `public_url`; trims; treats `""`/`"   "` as absent; returns `null` rather than guessing.
- Missing URL raises `SeedsInventoryException` with the fixed message above (null status preserved through the wrapper).
- On success the sheet stores the returned URL into `_imageUrlController` (:336), which renders the `Image.network` preview (:645) and the URL caption (:661), and is submitted as `image_url` on save.

## 7. Seed Form Integration

- Callback signature is now `({required List<int> fileBytes, required String fileName, required String contentType})?` — screen closures forward `contentType` unchanged.
- Upload button: `_isUploading ? null : _handleImageUpload`, label `Uploading...` with spinner while in flight (:686-694).
- Inline `_uploadError` text rendered under the section (:729-735); state resets in `finally`.
- `createSeed` / `updateSeed` already send `image_url` (non-empty trimmed, :212-213 / :270) and the repository impl already forwards `contentType` (:154-166) — now actually exercised.

## 8. Tests (15 new — all in `test/features/seeds_inventory/seeds_inventory_test.dart`)

1. `resolveSeedImageMimeType` extension map + declared-type preference (+ octet-stream fallback).
2. Multipart body asserts: `POST /api/v1/uploads`, `bucket=seeds` field, `file` field with picked filename, applied `content-type: image/png`, and **not** `image/jpeg`.
3. `data.public_url` parsing and root-level `public_url` fallback.
4. Missing/empty/whitespace `public_url` → fixed missing-URL message (3 variants).
5. HTTP 401/422/500 → exact fixed strings, with hostile detail (`XYZ-SECRET-42`, `{"db":"users"}`, `Traceback ... main.py`) proven absent.
6. `SocketException` → fixed connection message, `isNetworkError` true, host absent from message.
7. `createSeed`/`updateSeed` send `image_url` while preserving name/price/stock/is_active.
8. Image URL survives `loadSeeds`, backend JSON round-trip, and controller `updateSeed`.
9. Controller rethrows sanitized typed error; `errorMessage` set; `isUploadingImage` reset.
10. Controller maps non-domain `StateError('boom…')` → fixed generic message, raw text absent.
11. Static source check: no `_handleSampleUpload`, no `1x1 transparent PNG`, no `0x89 0x50 0x4E 0x47` bytes in sheet/controller.
12. Widget: picker opens, real selection bytes/fileName/mime forwarded, returned URL stored, no error shown.
13. Widget: cancel → idle, no upload call, button re-enabled.
14. Widget: typed upload exception shown inline as the fixed message.
15. Widget: `StateError` → generic message; `boom`/`StateError` text never rendered.

## 9. Regression

- **`flutter test` → 334/334 passed** (baseline 319 + 15 new). Zero pre-existing tests modified or weakened.

## 10. Static Analysis

- **`flutter analyze` → "No issues found!"** (clean before and after).

## 11. APK Build

- **`flutter build apk --debug` → `√ Built build\app\outputs\flutter-apk\app-debug.apk`** (Gradle `assembleDebug`, 136.6s, success).

## 12. Backend / Database Modification Check

- **No backend files modified.** Workspace contains no FastAPI source; nothing under any server/database directory was touched.
- Files changed in this task: `pubspec.yaml`, `pubspec.lock`, `.flutter-plugins-dependencies` (tool-generated), the 5 `lib/features/seeds_inventory/**` files, the seeds test file, and this report.

## 13. Database / Migration Check

- **No migrations, schemas, or database artifacts created or altered.** All persistence behavior goes through the existing documented endpoints.

## 14. Remaining Backend Issues (for Syed — no client-side workaround invented)

- **Real upload still unproven against production**: per scope/safety rules no live `POST /api/v1/uploads` was executed; verification used controlled test doubles only. The client is contract-faithful to the documented response shape (`object_path`, `public_url`, `size_bytes`, `content_type`).
- If production ever returns 2xx **without** `public_url`, users now see the explicit fixed message — backend must ensure the field is always present.
- Grade A/B/C pricing and warehouse assignment fields remain pending backend schema additions (unchanged, out of scope).
- Warehouse `PATCH`/`DELETE` and `GET /warehouses/{id}/inventory` remain pending backend additions (unchanged, out of scope).

---

SEED IMAGE UPLOAD FLUTTER FIX COMPLETE — AWAITING HUMAN APPROVAL
