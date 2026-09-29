# Deep review index — AgriFlow Admin & Manager

Index of every document produced by the `unlazy` deep review of this repository (scope
`deep-review`, 12 leaves over 5 branches). Each row names the document, the leaf that owns it,
what it covers, and the state of that leaf's manual gate. Automated gate evidence lives in
`.unlazy/deep-review/gates/`.

Ground truth for every backend claim in the corpus is the cached contract
`docs/deep-review/../openapi_dump.json` (`openapi_dump.json`, 94 paths / 112 operations, OpenAPI
3.1.0). Where a review proposes capability the contract does not have, it is marked with the
literal sentence `Backend API required - to be supplied by Syed.`

## Review documents

| Document | Leaf | Covers | Manual gate |
|---|---|---|---|
| `docs/deep-review/flutter-01-core-entry-config.md` | 1.1.1 | Flutter core layer, both entry files, root project configuration, theme tokens, navigation architecture | PASS |
| `docs/deep-review/flutter-02-auth-admin-manager-dashboard.md` | 1.1.2 | Authentication, app shells, Admin and Manager dashboards, API client layer | PASS |
| `docs/deep-review/flutter-03-farmers-visits-grain-booking.md` | 1.1.3 | Farmers, farm visits, grain sales, booking slots and their controllers/repositories | PASS |
| `docs/deep-review/flutter-04-seeds-and-placeholders.md` | 1.1.4 | Seeds inventory, seed purchases, quintal/kg money handling, placeholder feature directories | PASS |
| `docs/deep-review/flutter-05-test-suite.md` | 1.1.5 | The whole `test/` suite, test doubles, responsive-layout test rig | PASS |
| `docs/deep-review/flutter-06-platform-targets.md` | 1.1.6 | `android/ ios/ web/ windows/ linux/ macos/` scaffold, signing, entitlements, assets | PASS |
| `docs/deep-review/uiux-visual-reference.md` | 1.2.1 | Extracted design system and screen inventory from the four root HTML mockups and `agriflow/ui-ux/` | PASS |
| `docs/deep-review/react-01-ui-workflows.md` | 1.3.1 | React routes, role layouts, screen inventory and end-to-end workflows | PASS |
| `docs/deep-review/react-02-services-and-backend.md` | 1.3.2 | React services, Supabase edge functions, RLS, migrations, scripts and configuration | PASS |
| `docs/deep-review/repo-01-root-docs-scratch.md` | 1.4.1 | Repository root artefacts, `docs/`, `scratch/`, and the OpenAPI dump | PASS |
| `docs/deep-review/repo-02-vendored-and-inventory.md` | 1.4.2 | Six vendored agent/IDE trees, classification rules, exclusion rules | PASS |
| `docs/deep-review/workflow-cross-reference.md` | 1.5.1 | React workflow → Flutter screen → backend endpoint mapping, parity gaps, pending APIs | pending review |
| `docs/deep-review/file-inventory.md` | 1.4.2 | Machine-generated manifest of all 851 repository files (`INV\|path\|CLASS\|doc`) | n/a (generated) |

## How the corpus is organised

- **Branch 1.1 — Flutter application.** Six leaves split by layer: core/config, auth and shells,
  farmers domain, seeds domain, tests, platform targets.
- **Branch 1.2 — Visual reference.** One leaf extracts the design system from the approved HTML
  mockups so the app reviews can cite concrete tokens rather than impressions.
- **Branch 1.3 — React website (workflow reference).** Two leaves: UI layer (`src/`) and the
  services/backend layer outside `src/`.
- **Branch 1.4 — Repository meta.** Two leaves: root files, documents, scratch scripts and the
  OpenAPI dump; then vendored tooling plus the full file inventory.
- **Branch 1.5 — Integration.** One leaf maps workflows across React, Flutter and the contract.

Each leaf ledger is at `.unlazy/deep-review/gates/leaf-<id>.md` with three gates: G1 report
structure, G2 citation coverage, G3 a manual review by the orchestrator that requires at least one
attempted refutation per leaf. Node ledgers (`node-1.<n>.md`) reverify their children and add
integration gates. Root gates are in `.unlazy/deep-review/GATES.md`.

## Rules this corpus obeys

1. No endpoint, payload, response property, database table or business rule is invented; anything
   not in `openapi_dump.json` is reported as pending and marked
   `Backend API required - to be supplied by Syed.`
2. Every file in scope is cited as `FILE: <forward-slash path>`; every endpoint as
   `API: <METHOD> <path>` using the exact path string from the contract.
3. Findings are severity-tagged and backed by `file:line` evidence; recommendations map back to
   findings.
4. Nothing outside `docs/deep-review/` and `.unlazy/deep-review/` is written by the review.
