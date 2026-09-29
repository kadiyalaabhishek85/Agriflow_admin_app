# Repository root, documents, scratch scripts and the OpenAPI dump — deep review (leaf 1.4.1)

## Scope

This report discharges `.unlazy/deep-review/gates/leaf-1.4.1.md`. Its OWNS path is
`docs/deep-review/repo-01-root-docs-scratch.md`, and that is the only file this review writes.
Nothing under `docs/` other than this report was created, edited or deleted; no ledger checkbox was
touched, no source file was modified, no commit was made, and no live backend endpoint was called —
every live-network statement below is read out of the scripts themselves, not reproduced.

**In scope.** (a) Every repository *root* file that is not Flutter project configuration — 13 files.
(b) Everything under `docs/` — 20 files at the time of writing (1 request-for-change document, 8
milestone reports, 11 deep-review reports). (c) Everything under `scratch/` — 59 scripts. (d) The
cached contract `openapi_dump.json`. Total: 92 files, each cited individually under
`## Files reviewed`.

**Explicitly out of scope** (Flutter/IDE project configuration, owned by leaf 1.1.1 and already
covered in `docs/deep-review/flutter-01-core-entry-config.md`): `.flutter-plugins-dependencies`,
`.metadata`, `agriflow_admin.iml`, `analysis_options.yaml`, `pubspec.lock`, `pubspec.yaml`.

**Ground truth.** `openapi_dump.json` is the authoritative backend contract, as mandated by
`AGENTS.md:15-18`. No endpoint, payload, response property or business rule in this report is
invented: every endpoint named below was looked up in that file, and every "does not exist" claim is
the absence of the path key in `openapi_dump.json`. Where a document in the tree proposes backend
capability the contract does not yet have, it is reported as pending and marked with the exact
literal sentence: Backend API required - to be supplied by Syed.

**Concurrency caveat.** `docs/deep-review/` was being written by sibling leaves while this review
ran (`docs/deep-review/react-01-ui-workflows.md`, `docs/deep-review/react-02-services-and-backend.md`
and `docs/deep-review/repo-02-vendored-and-inventory.md` appeared during it, and
`docs/deep-review/file-inventory.md` grew). The `FILE:` list below is the tree as measured at write
time; the four gate-check commands were re-run against that same tree.

## Files reviewed

FILE: .gitignore
FILE: .reticle-setup-crash.log
FILE: AdminMobile UIUX.html
FILE: AdminMobile UIUX_screen_home.html
FILE: AGENTS.md
FILE: brandLogo_decoded.jpeg
FILE: decoded_logo.png
FILE: GEMINI.md
FILE: Manager Dashboard UIUX.html
FILE: Manager Dashboard UIUX_screen_home.html
FILE: openapi_dump.json
FILE: README.md
FILE: skills-lock.json
FILE: docs/backend-requirements-admin-mobile.md
FILE: docs/deep-review/file-inventory.md
FILE: docs/deep-review/flutter-01-core-entry-config.md
FILE: docs/deep-review/flutter-02-auth-admin-manager-dashboard.md
FILE: docs/deep-review/flutter-03-farmers-visits-grain-booking.md
FILE: docs/deep-review/flutter-04-seeds-and-placeholders.md
FILE: docs/deep-review/flutter-05-test-suite.md
FILE: docs/deep-review/flutter-06-platform-targets.md
FILE: docs/deep-review/react-01-ui-workflows.md
FILE: docs/deep-review/react-02-services-and-backend.md
FILE: docs/deep-review/repo-02-vendored-and-inventory.md
FILE: docs/deep-review/uiux-visual-reference.md
FILE: docs/milestones/m5-seed-inventory-backend-contract-blockers.md
FILE: docs/milestones/m5-seed-inventory-backend-contract-verification.md
FILE: docs/milestones/m5-seed-inventory-feature-parity-audit.md
FILE: docs/milestones/m5-step5-all-farmers-contract-audit.md
FILE: docs/milestones/m5-step5-all-farmers-verification-report.md
FILE: docs/milestones/m5-step6-seeds-inventory-contract-audit.md
FILE: docs/milestones/m5-step6-seeds-inventory-verification-report.md
FILE: docs/milestones/m5-step7-warehouse-contract-audit.md
FILE: scratch/audit_farm_visits_html.js
FILE: scratch/audit_farmer_admin_view.js
FILE: scratch/audit_farmer_endpoint_details.js
FILE: scratch/audit_farmer_schemas.js
FILE: scratch/audit_farmers_admin.js
FILE: scratch/audit_farmers_html.js
FILE: scratch/audit_farmers_js.js
FILE: scratch/audit_farmers_openapi.js
FILE: scratch/audit_save_edit.js
FILE: scratch/audit_seed_parity_openapi.js
FILE: scratch/audit_seed_schemas.js
FILE: scratch/audit_seeds_html.js
FILE: scratch/audit_seeds_openapi.js
FILE: scratch/audit_warehouse_openapi.js
FILE: scratch/check_all_farmer_paths.js
FILE: scratch/check_all_inventory_paths.js
FILE: scratch/check_billing_openapi.js
FILE: scratch/check_live_openapi.js
FILE: scratch/check_update_visit_status.js
FILE: scratch/check_warehouse_openapi.js
FILE: scratch/extract_farmer_purchase_flow.js
FILE: scratch/extract_setup_seed_purchase.js
FILE: scratch/find_screens.js
FILE: scratch/inspect_admin_open_farmer.js
FILE: scratch/inspect_admin_open_farmer_rest.js
FILE: scratch/inspect_confirm_and_wh.js
FILE: scratch/inspect_drawer.js
FILE: scratch/inspect_farmer_js.js
FILE: scratch/inspect_farmer_overlays.js
FILE: scratch/inspect_farmer_uiux_seed.js
FILE: scratch/inspect_farmers_endpoint_json.js
FILE: scratch/inspect_farmers_html_content.js
FILE: scratch/inspect_fv_js.js
FILE: scratch/inspect_manager_drawer.js
FILE: scratch/inspect_manager_farmers_js.js
FILE: scratch/inspect_manager_open_farmer.js
FILE: scratch/inspect_render_inventory.js
FILE: scratch/inspect_save_seed.js
FILE: scratch/inspect_screen_warehouse.js
FILE: scratch/inspect_seed_form.js
FILE: scratch/inspect_seed_purchase_endpoints.js
FILE: scratch/inspect_seeds_endpoint_security.js
FILE: scratch/inspect_seeds_inventory.js
FILE: scratch/inspect_upload_details.js
FILE: scratch/inspect_uploads.js
FILE: scratch/inspect_visit_modal.js
FILE: scratch/inspect_wh_details.js
FILE: scratch/inspect_wh_flow.js
FILE: scratch/inspect_wh_js.js
FILE: scratch/list_openapi_endpoints.js
FILE: scratch/list_screens_and_drawers.js
FILE: scratch/live_admin_login_e2e_test.dart
FILE: scratch/print_seed_schemas.js
FILE: scratch/print_warehouse_paths.js
FILE: scratch/search_cancel.js
FILE: scratch/search_spec_seeds.js
FILE: scratch/test_cancel_endpoint.js
FILE: scratch/test_live_fv.js
FILE: scratch/verify_admin_login.js

## Root files

**`AGENTS.md`** (3,980 bytes, mtime 2026-09-25 10:57) — the workspace-memory and backend-invariant
file that is injected as agent instructions for this repository. Four sections: ground-truth backend
authority (`AGENTS.md:7-18`), a memorised live-endpoint summary (`:22-50`), RBAC rules (`:54-57`) and
a pointer to the pending-contract document (`:61-64`). It is the *current* root document — newest
mtime of any root artefact. Verified rather than assumed: all 62 endpoint references it names resolve
against `openapi_dump.json` once path-parameter placeholders are normalised, and the single
non-live reference (`GET /warehouses/{id}/inventory`, `AGENTS.md:39`) is expressly labelled pending
in the same bullet, so §2 does not mislead. Two qualifications are recorded under `## Findings`: §2
covers only 62 of the 112 operations in the contract, and §3's RBAC table assumes an `Admin` role the
contract cannot return.

**`GEMINI.md`** (3,980 bytes, mtime 2026-09-25 10:57) — a byte-for-byte duplicate of `AGENTS.md`
except the H1 word itself (`Compare-Object` of the two line arrays yields exactly one changed line,
line 1: `# GEMINI.md — AgriFlow Workspace Memory & Backend Invariants` versus
`# AGENTS.md — …`, `GEMINI.md:1`). It exists so the Gemini CLI picks up the same invariants that
opencode picks up from `AGENTS.md`. Nothing in the tree references it. Same currency and same two
qualifications as `AGENTS.md`; the duplication is the risk (Finding F7).

**`README.md`** (653 bytes, mtime 2026-09-23 15:08) — untouched `flutter create` boilerplate:
`# agriflow_admin` (`README.md:1`), `A new Flutter project.` (`README.md:3`), and four links to
generic Flutter documentation (`:11-17`). It is **misleading**: it describes neither the AgriFlow
Admin & Manager application, nor the RBAC split, nor the authority of `openapi_dump.json`, nor where
the design references live. Sibling leaf 1.1.1 already flagged it
(`docs/deep-review/flutter-01-core-entry-config.md:95`); it remains unfixed.

**`openapi_dump.json`** (1,572,425 bytes, 14,187 lines, mtime 2026-09-23 21:09) — the cached backend
contract, treated by every document in the tree as the sole authority. Fully measured in
`## OpenAPI dump`.

**`.gitignore`** (748 bytes, mtime 2026-09-23 15:08) — stock Flutter ignore list: `*.log` (`:3`),
`*.iml` (`:16`), `.idea/` (`:19`), `.dart_tool/` (`:29`), `.flutter-plugins-dependencies` (`:30`),
`/build/` (`:33`). Current as Flutter boilerplate and correctly excludes every generated artefact
present at the root. It is, however, inert: the workspace contains no `.git` directory, so nothing is
actually tracked or ignored and the repository has no history for any of the contract documents
described below (Finding F16).

**`.reticle-setup-crash.log`** (570 bytes, mtime 2026-09-24 09:17) — an eight-line Node stack trace
for `Error: EPIPE: broken pipe, write` raised inside `@reticlehq/server`'s MCP command path
(`.reticle-setup-crash.log:1`, `:6-7`). A one-off setup diagnostic. It is already covered by
`.gitignore:3` (`*.log`), is referenced by no document and no script, and is safe to keep only as
evidence of a failed tool bootstrap; safe to delete the moment that is understood.

**`skills-lock.json`** (11,299 bytes, mtime 2026-09-24 23:16) — the agent-skill installation
manifest: `version`, then a `skills` map of `{source, sourceType, skillPath, computedHash}` entries
(`skills-lock.json:2-12`). Generated tooling state, not Flutter configuration, which is why it sits in
this leaf. Nothing in `lib/`, `test/` or `docs/` reads it. It is safe to keep (it pins skill
provenance and integrity hashes) but it should not be mistaken for project configuration, and it will
churn on every skill install.

**`AdminMobile UIUX.html`** (479,590 bytes, mtime 2026-09-21 10:09) — the approved Admin console
mockup, `<title>Sri Siva Sai Seeds - Admin Console</title>`. It is byte-identical (SHA-256
`867A64D9…`) to `agriflow/ui-ux/AdminDashboard Mobile UI/AdminMobile UIUX.html`, i.e. a root-level
duplicate of a file already inside the repository. It is current and load-bearing — it is the visual
authority cited by every milestone audit (`docs/milestones/m5-step5-all-farmers-contract-audit.md:15`)
— but the duplication creates two "authoritative" copies that can silently diverge (Finding F11).

**`Manager Dashboard UIUX.html`** (623,356 bytes, mtime 2026-09-21 10:09) — the same for the Manager
console (`<title>Sri Siva Sai Seeds - Manager Console</title>`), byte-identical (SHA-256 `6CB98DAC…`)
to `agriflow/ui-ux/ManagerDashboard Mobile UI/Manager Dashboard UIUX.html`. Same status and same
duplication risk.

**`AdminMobile UIUX_screen_home.html`** (11,374 bytes, mtime 2026-09-23 21:11) and
**`Manager Dashboard UIUX_screen_home.html`** (7,481 bytes, mtime 2026-09-23 21:11) — 166- and
113-line extracts beginning at `<section class="screen active" id="screen-home">`. Measured: neither
contains `<!doctype`, `<html` or `<style`, so neither is a standalone page — opened directly they
render unstyled fragments with no router and no `:root` token block. They are cited as in-scope files
by `docs/deep-review/uiux-visual-reference.md:20` and `:22`, but no document says what they are for or
how they were produced (Finding F13).

**`brandLogo_decoded.jpeg`** (12,548 bytes, 180×179 JPEG, mtime 2026-09-23 19:33) — a decoded brand
logo. Referenced nowhere except the inventory row `docs/deep-review/file-inventory.md:482`. Orphaned.

**`decoded_logo.png`** (47,680 bytes, 140×140 PNG, mtime 2026-09-23 19:32) — SHA-256 identical
(`9C851A9A…`) to the asset the application actually ships, `assets/images/sri_siva_sai_seeds_logo.png`.
No code, `pubspec.yaml` entry (`pubspec.yaml:65-66` declares only `assets/images/`) or document loads
the root copy; it is referenced solely by `docs/deep-review/file-inventory.md:483`.

**Excluded, listed for completeness:** `.flutter-plugins-dependencies`, `.metadata`,
`agriflow_admin.iml`, `analysis_options.yaml`, `pubspec.lock`, `pubspec.yaml`.

## Documents

### `docs/backend-requirements-admin-mobile.md`
Purpose: the formal request-for-change sent to the backend owner. Author "Antigravity Engineering /
Admin Mobile Team", recipient "Syed (Backend Developer / Database Owner)", `Date: 2026-09-25`,
`Version: 1.0.0` (`:3-7`). Audience: the backend developer, not the mobile team. Status: **open** —
§7 "Next Steps" still asks Syed to deploy Priority 0 and notify the team when
`/api/v1/openapi.json` is updated (`:446-452`), so nothing in it is yet delivered. It contains the
present-backend snapshot table (`:30-42`), the 14-row master OpenAPI delta table (`:319-334`), full
proposed SQL migrations (`:342-421`) and an RBAC invariant matrix (`:425-441`). Two problems: (1)
`:80` presents `GET /api/v1/seeds/{seed_id}` as an existing route, but the contract defines only
`patch` and `delete` on that path (`openapi_dump.json:1790-1791`); (2) it never uses the project's
own pending marker — every capability in the delta table must be read as pending and is marked here
as: Backend API required - to be supplied by Syed.

### `docs/milestones/` (8 files, all dated 2026-09-24 or 2026-09-25)
Audience for all eight: the mobile team and the human gate approver; each reconciles the same four
authorities (FastAPI/OpenAPI, React web, approved HTML mockups, Flutter code).

- `m5-step5-all-farmers-contract-audit.md` — `Date: 2026-09-24`, "Complete Audit & Contract
  Discovery" (`:3-5`). Purpose: discover the farmers contract before coding. Status: satisfied; it
  correctly marks profile-edit and hard-delete as `BACKEND GAP / PENDING CONTRACT` (`:39-40`) — both
  Backend API required - to be supplied by Syed.
- `m5-step5-all-farmers-verification-report.md` — `Date: 2026-09-24`,
  `Status: IMPLEMENTATION COMPLETE & FULLY VERIFIED`, `Gate Status: AWAITING HUMAN GATE APPROVAL`
  (`:4-6`). **Stale on two counts:** it still reports "all **197/197** tests passing" (`:19`) while
  `docs/backend-requirements-admin-mobile.md:13` reports 226/226 as of the next day, and the approval
  it is awaiting has no recorded outcome anywhere in `docs/`.
- `m5-step6-seeds-inventory-contract-audit.md` — `Date: 2026-09-25`, audit of the seeds contract.
  Accurate: it states "Query Parameters: None (returns full master catalog list)" (`:50`) and lists
  only `price_per_kg, stock_kg, description, is_active` for `SeedUpdate` (`:27`), both matching
  `openapi_dump.json`.
- `m5-step6-seeds-inventory-verification-report.md` — `Date: 2026-09-25`, `Status: Verification
  Complete — Awaiting Human Gate Approval` (`:6`). **Contradicts the contract** at `:26` and `:27`
  (Finding F2). Supersedes nothing but is itself contradicted by its sibling audit of the same day.
- `m5-step7-warehouse-contract-audit.md` — `Date: 2026-09-25`, warehouse contract audit. Its four
  pending rows (`:52-55`): warehouse detail `GET`, warehouse `PATCH`/`DELETE`,
  `GET /api/v1/warehouses/{warehouse_id}/inventory` and slot `DELETE` — none exist in the dump — are
  each Backend API required - to be supplied by Syed. Current and accurate.
- `m5-seed-inventory-feature-parity-audit.md` — `Date: 2026-09-25`, "Complete Feature-Parity &
  Contract Gap Audit". The best of the set: its `SeedCreate`/`SeedUpdate` property lists (`:145-157`)
  match `openapi_dump.json` exactly, and it is the only milestone that uses the project marker (six
  em-dash occurrences at `:29-30`, see F10). Current.
- `m5-seed-inventory-backend-contract-blockers.md` — `Date: 2026-09-25`,
  `Final Status: BLOCKED — BACKEND CONTRACT NOT DEPLOYED` (`:8`). Purpose: stop-condition evidence,
  with verbatim `SeedCreate`/`SeedUpdate` schema dumps. Current and consistent with the contract.
- `m5-seed-inventory-backend-contract-verification.md` — `Date: 2026-09-25`, `Final Gate Status:
  BLOCKED — BACKEND NOT DEPLOYED` (`:26`), audit timestamp `2026-09-25T12:28:30+05:30` (`:36`).
  Adds the seed-image contract finding (`:49-70`). Current; it is the freshest live inspection
  recorded in the tree and it post-dates `openapi_dump.json`'s mtime by two days.

**Net status of `docs/milestones/`:** the three audits (step 5, step 6, step 7) and the two blockers
reports are current; one verification report is stale on test counts and gate status, and one
verification report contradicts the contract.

### `docs/deep-review/` (11 files)
Audience: the unlazy orchestrator and human reviewers; each is a sibling leaf's OWNS artefact, not a
product document, and none carries a `Date` or `Status` header — currency can only be inferred from
mtime (all 2026-09-25, 12:28–12:57).

- `file-inventory.md` — the `INV|<path>|<CLASS>|<review document>` manifest of every repository file;
  it assigns root, `docs/` and `scratch/` rows to this document (e.g. `:759`, `:762-820`).
- `flutter-01-core-entry-config.md` … `flutter-06-platform-targets.md` — leaves 1.1.1–1.1.6: Flutter
  core/entry/config, auth+shells+dashboards, farmers/visits/grain/bookings, seeds and placeholders,
  the test suite, and platform targets/assets. Each carries the required `## Scope` /
  `## Files reviewed` / `## Findings` / `## Recommendations` structure and cites
  `openapi_dump.json` (94 paths) as ground truth.
- `react-01-ui-workflows.md` (leaf 1.3.1) and `react-02-services-and-backend.md` (leaf 1.3.2) — the
  React web portal's UI layer and its services/backend integration. Written during this review.
- `repo-02-vendored-and-inventory.md` (leaf 1.4.2) — vendored agent-tooling trees plus the file
  inventory. Written during this review; overlaps this leaf's manifest observation only.
- `uiux-visual-reference.md` — extracted design system and screen inventory for the four root HTML
  mockups and the `agriflow/ui-ux/` pack; it is what documents the `_screen_home.html` fragments.

**Gap:** there is no `docs/deep-review/README.md` index, although `.unlazy/deep-review/GATES.md:3`
lists it as driver-owned and `.unlazy/deep-review/PLAN.md:74` makes gate C9 depend on it.

## Scratch scripts

59 scripts, 58 JavaScript and 1 Dart. **Nothing references any of them**: no `package.json` exists,
no gate script, CI config or document invokes a `scratch/` path — the only in-tree mentions are the
`INV|scratch/…` assignment rows in `docs/deep-review/file-inventory.md:762-820`. They are ad-hoc audit
probes produced while writing the milestone reports, run by hand as `node scratch/<name>.js`.

**Group A — read-only analysis of `openapi_dump.json` (19 files).**
`audit_farmer_admin_view.js`, `audit_farmer_endpoint_details.js`, `audit_farmer_schemas.js`,
`audit_farmers_admin.js`, `audit_farmers_openapi.js`, `audit_seed_parity_openapi.js`,
`audit_seed_schemas.js`, `audit_seeds_openapi.js`, `audit_warehouse_openapi.js`,
`check_all_farmer_paths.js`, `check_all_inventory_paths.js`, `check_billing_openapi.js`,
`check_warehouse_openapi.js`, `inspect_farmers_endpoint_json.js`, `inspect_seed_purchase_endpoints.js`,
`inspect_seeds_endpoint_security.js`, `list_openapi_endpoints.js`, `print_seed_schemas.js`,
`print_warehouse_paths.js`. Each does `JSON.parse(fs.readFileSync('openapi_dump.json','utf8'))` and
prints paths or schema properties. No network, no writes. **Safe to keep** — they are the reproducible
evidence trail behind the contract claims in `docs/milestones/`.

**Group B — read-only mining of the local HTML/React references (26 files).**
`audit_farm_visits_html.js`, `audit_farmers_html.js`, `audit_farmers_js.js`, `audit_save_edit.js`,
`audit_seeds_html.js`, `check_update_visit_status.js`, `extract_farmer_purchase_flow.js`,
`extract_setup_seed_purchase.js`, `find_screens.js`, `inspect_confirm_and_wh.js`, `inspect_drawer.js`,
`inspect_farmer_uiux_seed.js`, `inspect_fv_js.js`, `inspect_manager_drawer.js`,
`inspect_render_inventory.js`, `inspect_save_seed.js`, `inspect_screen_warehouse.js`,
`inspect_seed_form.js`, `inspect_seeds_inventory.js`, `inspect_visit_modal.js`, `inspect_wh_details.js`,
`inspect_wh_flow.js`, `inspect_wh_js.js`, `list_screens_and_drawers.js`, `search_cancel.js`,
`search_spec_seeds.js`. They slice functions out of `AdminMobile UIUX.html`,
`Manager Dashboard UIUX.html`, `agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html`,
`agriflow/agriflow-web/src/pages/admin/FarmVisits.jsx` and
`agriflow/agriflow-web/Backend_Technical_Specification.md`. All of those targets exist inside the
repository (verified). Read-only, no writes. **Safe to keep.**

**Group C — read-only live spec fetches (3 files).** `check_live_openapi.js`, `inspect_uploads.js`,
`inspect_upload_details.js` issue a single `GET https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`
and print. Read-only, but they depend on a sleeping Render free tier and can rate-limit the reviewer.
Safe to keep; do not run them in bulk.

**Group D — live-backend scripts that carry credentials (4 files). Not safe to keep as-is.**
- `scratch/verify_admin_login.js` — tries five phone/password pairs against `POST /api/v1/auth/login`
  (`:74-80`), waits `20000` ms between attempts specifically to stay under the backend's
  ~4 logins/min limiter (`:87-88`), and prints the pair that works as `Working credentials:`
  (`:98`). This is a rate-limit-evading credential probe with plaintext passwords committed to the
  tree (`:75-79`).
- `scratch/test_cancel_endpoint.js` — logs in with a hardcoded account (`:5`) then issues **mutating**
  `PATCH /api/v1/farm-visits/{id}/cancel` (`:71`), `POST …/cancel` (`:75`) and `DELETE /api/v1/farm-visits/{id}`
  (`:79`) against the live backend with a real-looking UUID (`:68`).
- `scratch/test_live_fv.js` — logs in with the same hardcoded account (`:5`) and `PATCH`es
  `/api/v1/farm-visits/{id}/schedule` on the first live record (`:61-63`).
- `scratch/live_admin_login_e2e_test.dart` — a `flutter test` harness that logs in as super_admin with
  a hardcoded pair (`:65-66`) and asserts the role round-trips, plus one deliberate wrong-password
  attempt (`:131`). Well documented (`:1-7`), but still credentials in source.

**Group E — non-portable absolute paths (7 files).**
`inspect_admin_open_farmer.js:2`, `inspect_admin_open_farmer_rest.js:2`,
`inspect_farmers_html_content.js:3-4`, `inspect_farmer_js.js:3-4`, `inspect_farmer_overlays.js:3-4`,
`inspect_manager_farmers_js.js:2`, `inspect_manager_open_farmer.js:2` all read
`C:\Users\DELL\Downloads\agriflow\ui-ux\…` — a sibling checkout **outside** this repository, while
byte-identical copies (SHA-256 verified, `867A64D9…` / `6CB98DAC…`) exist inside the repo at
`agriflow/ui-ux/…`. They work on this machine only. Safe to keep *after* repointing to the in-repo
relative paths; as written they are portable-in-name-only.

**No scratch script writes to disk** — a scan for `writeFile`, `appendFile`, `createWriteStream`,
`unlink`, `rmSync` and `mkdir` across all 59 files returns zero matches.

## OpenAPI dump

All numbers below were measured by parsing `openapi_dump.json` with Node, not estimated.

- **Path count: 94** path items under `paths` (matching the 94-path figure asserted across
  `docs/deep-review/`).
- **Operations: 112** (`get`/`post`/`patch`/`delete` entries across those 94 paths).
- **OpenAPI version: `3.1.0`** (`openapi_dump.json:2`).
- **`info`:** `title: "AgriFlow Backend"` (`openapi_dump.json:4`), `version: "0.1.0"`
  (`openapi_dump.json:5`).
- **Top-level keys: exactly four** — `openapi`, `info`, `paths`, `components`. There is **no**
  `servers`, **no** `tags` and **no** `externalDocs` block.
- **`components`: two keys** — `schemas` (begins `openapi_dump.json:6385`) and `securitySchemes`.
- **`components.schemas` entries: 199.**
- **`components.securitySchemes`: 1** — `OAuth2PasswordBearer`, `type: oauth2`, password flow,
  `tokenUrl: /api/v1/auth/login`.
- **File size/format:** 1,572,425 bytes, 14,187 lines, PowerShell-serialised pretty JSON (four-space
  nested indentation).

**Top-level route groups** (first path segment after `/api/v1/`, plus the three `/health*` paths that
sit outside `/api/v1/`), with path counts summing to 94:

| Group | Paths | Group | Paths |
|---|---:|---|---:|
| `farmer` | 31 | `managers` | 3 |
| `auth` | 9 | `crops` | 2 |
| `farmers` | 8 | `seeds` | 2 |
| `grain-sales` | 5 | `seed-purchases` | 2 |
| `farm-visits` | 4 | `warehouse-slots` | 2 |
| `public` | 3 | `transactions` | 2 |
| `warehouses` | 3 | `events` | 2 |
| `bookings` | 3 | `uploads` | 2 |
| `notifications` | 3 | `users` | 1 |
| `admin` | 3 | `market-rates` | 1 |
| — | | `health` (at `/health`, `/health/live`, `/health/ready`) | 3 |

The 28 operation tags are: `admin`, `auth`, `bookings`, `crops`, `events`, `farm-visits`,
`farmer · auth`, `farmer · crops`, `farmer · dashboard`, `farmer · grain sales`,
`farmer · ledger & documents`, `farmer · notifications`, `farmer · profile`, `farmer · seeds`,
`farmer · warehouses`, `farmers`, `grain-sales`, `health`, `managers`, `market-rates`,
`notifications`, `public`, `seed-purchases`, `seeds`, `transactions`, `uploads`, `users`,
`warehouses`.

**Provenance: not stated anywhere.** No document in the tree records how or when the dump was
produced. `AGENTS.md:12` and `GEMINI.md:12` say only "Local OpenAPI Cache: openapi_dump.json (in workspace
root)" — no fetch command, no source URL bound to the file, no timestamp, no checksum.
A grep across all `*.md` for a dump/capture/fetch/refresh statement returns nothing outside gate
boilerplate, and no `scratch/` script writes the file (see `## Scratch scripts`). The only observable
provenance is the filesystem mtime, **2026-09-23 21:09**, which *predates* the live re-inspections
recorded in `docs/milestones/m5-seed-inventory-backend-contract-verification.md:36`
(`2026-09-25T12:28:30+05:30`). The dump is therefore two days older than the freshest claim made
against it, and nothing in the repository would detect it going stale.

## Findings

**F1 — P0 — Plaintext production credentials and a rate-limit-evading password probe are committed in `scratch/`.**
`scratch/verify_admin_login.js:75-79` holds five phone/password pairs, `:88` spaces the attempts by
20 s to stay under the backend's login throttle, and `:98` prints the working pair. The same account
appears in `scratch/test_cancel_endpoint.js:5`, `scratch/test_live_fv.js:5` and
`scratch/live_admin_login_e2e_test.dart:65-66`. Two of those also send **mutating** requests to the
live service (`scratch/test_cancel_endpoint.js:71,75,79`; `scratch/test_live_fv.js:61`).
`AGENTS.md:15-18` makes the live backend authoritative for everyone; these scripts make it a shared,
guessable target.

**F2 — P1 — A milestone report contradicts the authoritative contract.**
`docs/milestones/m5-step6-seeds-inventory-verification-report.md:26` states `GET /api/v1/seeds`
accepts `Query parameters: is_active (optional bool)`. The contract has no `parameters` key on that
operation at all (`openapi_dump.json:1716-1742`), and its own sibling audit says so
(`docs/milestones/m5-step6-seeds-inventory-contract-audit.md:50`, "Query Parameters: None").
`:27` additionally lists `is_active` inside `SeedCreate`; the schema's properties are `name`,
`variety`, `price_per_kg`, `stock_kg`, `description`, `image_url` only
(`openapi_dump.json:11054-11055` and following — `is_active` appears only on `SeedUpdate`).

**F3 — P1 — `docs/backend-requirements-admin-mobile.md:80` claims an endpoint the contract does not define.**
The line reads "Update Response Schema: `SeedPublic` (`GET /api/v1/seeds` & `GET /api/v1/seeds/{seed_id}`)".
`GET /api/v1/seeds` exists (`openapi_dump.json:1717`), but `/api/v1/seeds/{seed_id}` carries only
`patch` and `delete` (`openapi_dump.json:1790-1791`). A document whose entire purpose is to be the
negotiating contract with Syed must not assert a route as present.

**F4 — P1 — `README.md` misleads about the repository.**
`README.md:1` and `README.md:3` still say `# agriflow_admin` / `A new Flutter project.` for a
repository whose own instruction file opens `This repository is the **AgriFlow Admin & Manager Mobile
Flutter Application**` (`AGENTS.md:3`). First thing every contributor or agent reads is wrong.
Corroborated at `docs/deep-review/flutter-01-core-entry-config.md:95`.

**F5 — P1 — The RBAC rules assume a role the contract cannot return.**
`AGENTS.md:56` grants "Super Admin & Admin" full mutation access and `AGENTS.md:57` constrains
"Manager", but `openapi_dump.json:13460-13466` defines `UserRole` as exactly
`["farmer", "manager", "super_admin"]` — there is no `admin` value. The instructions therefore
describe an actor the backend never emits (the Flutter mapping in
`docs/deep-review/flutter-02-auth-admin-manager-dashboard.md:63` confirms `admin` only exists as a
client-side interpretation).

**F6 — P1 — The authoritative cache has no provenance.**
`openapi_dump.json` is 1.5 MB of contract that every document treats as ground truth, yet
`AGENTS.md:12` / `GEMINI.md:12` record only "Local OpenAPI Cache … (in workspace root)" — no fetch
command, URL, timestamp or hash (see `## OpenAPI dump`). Its mtime (2026-09-23 21:09) already
predates the newest live inspection (`docs/milestones/m5-seed-inventory-backend-contract-verification.md:36`).
Nothing detects drift between the cache and `https://agriflow-backend-t8o4.onrender.com/api/v1/openapi.json`.

**F7 — P2 — `GEMINI.md` duplicates `AGENTS.md` with no derivation rule.**
The two files differ on exactly one line (`GEMINI.md:1` versus `AGENTS.md:1`) and are otherwise
identical, 3,980 bytes each. Nothing references `GEMINI.md`. Every future edit to the golden rule,
the endpoint list or the RBAC section must be made twice or the two invariants silently diverge.

**F8 — P2 — The "Memorized Live Endpoints Summary" covers only 62 of 112 operations.**
Measured: `AGENTS.md` + `GEMINI.md` name 62 distinct operations; 50 are unnamed, including the entire
`/api/v1/farmer/**` surface (31 paths), `POST /api/v1/auth/register`, the four `/api/v1/farmers/me*`
routes, `/api/v1/notifications*`, `/api/v1/events*`, `/api/v1/uploads*` and the three `/health*`
routes. An agent that treats §2 as exhaustive will wrongly conclude those routes do not exist —
the mirror-image error of inventing endpoints.

**F9 — P2 — Path-parameter shorthand breaks literal contract matching.**
`AGENTS.md` writes `{id}` where the contract uses `{farmer_id}` (`AGENTS.md:31`), `{seed_id}`
(`:33`), `{manager_id}` (`:29`), `{request_id}` (`:31`), `{slot_id}` (`:38`), `{purchase_id}` (`:34`),
`{booking_id}` (`:44`), `{sale_id}` (`:45`), `{visit_id}` (`:42`) and `{transaction_id}` (`:48`).
`.unlazy/deep-review/scripts/check-api-refs.mjs:45-47` performs an exact `paths` lookup with no
normalisation, so any report citing an endpoint verbatim from `AGENTS.md` fails that gate even though
the route is real.

**F10 — P2 — The mandated pending marker is not used consistently.**
`AGENTS.md:18` and `GEMINI.md:18` specify `Backend API required — to be supplied by Syed.` with an
em dash (byte sequence `e2 80 94`), while the deep-review reports use the ASCII-hyphen form
`Backend API required - to be supplied by Syed.` (5 occurrences in
`docs/deep-review/flutter-01-core-entry-config.md`, 7 in `flutter-04-seeds-and-placeholders.md`). Of
the eight `docs/milestones/` files, only `m5-seed-inventory-feature-parity-audit.md` uses the marker
at all (6 times, em dash, `:29-30`); the other seven use ad-hoc wording such as
`BACKEND GAP / PENDING CONTRACT` (`m5-step5-all-farmers-contract-audit.md:39-40`) and
`PENDING BACKEND CONTRACT` (`m5-step7-warehouse-contract-audit.md:28-30`). A literal-string check
against the canonical sentence fails on `AGENTS.md` itself.

**F11 — P2 — The two "approved visual authority" mockups are byte-identical duplicates.**
`AdminMobile UIUX.html` ≡ `agriflow/ui-ux/AdminDashboard Mobile UI/AdminMobile UIUX.html` (SHA-256
`867A64D9…`) and `Manager Dashboard UIUX.html` ≡ `agriflow/ui-ux/ManagerDashboard Mobile UI/Manager
Dashboard UIUX.html` (`6CB98DAC…`). `docs/milestones/m5-step5-all-farmers-contract-audit.md:15` names
the root copies as the design authority while the `agriflow/ui-ux/` copies are the working tree — two
sources of truth for the same artefact.

**F12 — P2 — The deep-review index that the plan gates on does not exist.**
`docs/deep-review/README.md` is absent, although `.unlazy/deep-review/GATES.md:3` lists it as
driver-owned and `.unlazy/deep-review/PLAN.md:74` makes checkpoint C9 ("index lists every review
document and every document exists") depend on it. With 11 reports in the directory and no index,
C9 cannot pass.

**F13 — P3 — The `_screen_home.html` fragments are undocumented and not standalone.**
Measured: no `<!doctype`, no `<html`, no `<style` in either file, so opening them renders unstyled
markup with no router. Only `docs/deep-review/uiux-visual-reference.md:20` and `:22` cite them, and
neither explains how they were cut or what they are for.

**F14 — P3 — Two root images are orphaned; one is a duplicate of a shipped asset.**
`decoded_logo.png` is SHA-256 identical to `assets/images/sri_siva_sai_seeds_logo.png`, and neither
`pubspec.yaml:65-66` nor any `.dart` file references the root copy; `brandLogo_decoded.jpeg` is
referenced only by `docs/deep-review/file-inventory.md:482-483`.

**F15 — P3 — `.reticle-setup-crash.log` is a dead diagnostic.**
An EPIPE stack trace from a tool bootstrap (`.reticle-setup-crash.log:1-8`), already matched by
`.gitignore:3`, referenced by nothing.

**F16 — P2 — The workspace is not under version control, so `.gitignore` and every document's history are inert.**
No `.git` directory exists at the repository root. `AGENTS.md`/`GEMINI.md`, the milestone reports and
`openapi_dump.json` have no history, no blame and no diff; `docs/milestones/` reports can be edited
without any record (which is how F2's contradiction survives beside its own correction).

**F17 — P3 — Superseded figures and open gate statuses remain in `docs/`.**
`docs/milestones/m5-step5-all-farmers-verification-report.md:19` still reports 197/197 tests where
`docs/backend-requirements-admin-mobile.md:13` reports 226/226; that report and
`m5-step6-seeds-inventory-verification-report.md:6` both still read `AWAITING HUMAN GATE APPROVAL`
with no recorded outcome, and no `docs/` file carries an approval record.

**F18 — P3 — None of the 11 `docs/deep-review/` reports carries a date or status header.**
Unlike `docs/milestones/` (every file has `Date:` and `Status:`), the deep-review reports can only be
dated by mtime, so a reader cannot tell a current finding from a superseded one.

## Recommendations

**P0**
1. **Rotate the exposed credentials and quarantine the live probes.** Treat `9999900000` /
   `Admin@123` / `Admin12345` (and the `Manager@123`, `Admin12345` demo pairs) as compromised:
   change them on the backend, then delete or move `scratch/verify_admin_login.js`,
   `scratch/test_cancel_endpoint.js`, `scratch/test_live_fv.js` and
   `scratch/live_admin_login_e2e_test.dart` out of the tree, or strip the literals and read them
   from an ignored local file. Add a rule to `AGENTS.md` forbidding mutating requests against the
   production host. (F1)

**P1**
2. Correct `docs/milestones/m5-step6-seeds-inventory-verification-report.md:26-27` to match
   `openapi_dump.json:1716-1742` and `:11054` (no `is_active` query parameter; no `is_active` on
   `SeedCreate`) — or, if the backend has since added them, refresh `openapi_dump.json` first and
   re-derive. (F2)
3. Fix `docs/backend-requirements-admin-mobile.md:80`: drop the `GET /api/v1/seeds/{seed_id}` claim
   or list it as a required addition — Backend API required - to be supplied by Syed. (F3)
4. Rewrite `README.md:1-17` for the AgriFlow Admin & Manager application: purpose, Admin/Manager
   split, how to run, and the `openapi_dump.json` ground-truth rule. (F4)
5. Reconcile `AGENTS.md:56-57` with `openapi_dump.json:13460-13466` — describe RBAC in terms of
   `super_admin` / `manager` / `farmer`, or state explicitly that `admin` is a client-side alias the
   backend never returns. (F5)
6. Record dump provenance at `AGENTS.md:12`: source URL, exact fetch command, fetch timestamp, path
   count (94) and a checksum, and add a re-fetch step to the contract audits so staleness against
   `…/api/v1/openapi.json` is detectable. (F6)

**P2**
7. Make one of `AGENTS.md` / `GEMINI.md` canonical and reduce the other to a pointer, or add a
   generated-from check so they cannot diverge. (F7)
8. Extend the `AGENTS.md` §2 summary to name the omitted 50 operations, or retitle it
   "Admin/Manager-relevant endpoints (subset of 112)" so absence there is not read as absence in the
   contract. (F8)
9. Either spell the real parameter names in `AGENTS.md` (`{farmer_id}`, `{seed_id}`, …) or teach
   `.unlazy/deep-review/scripts/check-api-refs.mjs:45` to normalise `{…}` placeholders — today the
   two disagree. (F9)
10. Pick one marker string (ASCII form), change `AGENTS.md:18`, `GEMINI.md:18` and
    `.agents/rules/backend_api_memory.md` to match, and replace `PENDING BACKEND CONTRACT` /
    `BACKEND GAP / PENDING CONTRACT` in the eight milestone reports with the literal sentence,
    each marked: Backend API required - to be supplied by Syed. (F10)
11. Keep one copy of each UI/UX mockup — delete the root duplicates or the `agriflow/ui-ux/` ones —
    and update the authority citations in `docs/milestones/*:15` accordingly. (F11)
12. Create `docs/deep-review/README.md` indexing the 11 reports with owner leaf, date and status, so
    `.unlazy/deep-review/PLAN.md:74` checkpoint C9 can pass. (F12, F18)
13. Put the workspace under version control (or state in `AGENTS.md` why it is not), which also
    makes `.gitignore` meaningful and gives the contract documents history. (F16)

**P3**
14. Delete `.reticle-setup-crash.log` and `brandLogo_decoded.jpeg`; either use
    `decoded_logo.png` or drop it in favour of `assets/images/sri_siva_sai_seeds_logo.png`. (F14, F15)
15. Add a two-line header to `AdminMobile UIUX_screen_home.html` /
    `Manager Dashboard UIUX_screen_home.html` (or a note in
    `docs/deep-review/uiux-visual-reference.md`) saying they are extracted, CSS-less fragments.
    (F13)
16. Repoint the seven absolute-path scripts (F9/Group E) at `agriflow/ui-ux/…` so they run outside
    this machine. (F9 group, `## Scratch scripts` Group E)
17. Supersede `m5-step5-all-farmers-verification-report.md:19`'s 197/197 figure with 226/226 and close
    out both `AWAITING HUMAN GATE APPROVAL` statuses with an actual decision. (F17)
