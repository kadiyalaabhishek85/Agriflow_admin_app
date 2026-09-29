# Repo meta 02: vendored agent-tooling trees and the full file inventory

## Scope

This report discharges leaf-1.4.2. It owns exactly two artefacts:

1. `docs/deep-review/file-inventory.md` - the machine-generated, hand-verified manifest that
   classifies **every** repository file exactly once (`INV|<path>|<CLASS>|<review document>`).
2. This document - the written review of the six vendored agent-tooling trees
   (`.agents`, `.claude`, `.opencode`, `.idea`, `.codex`, `.reticle`) plus the root
   `skills-lock.json` pin file, together with the classification rules and the
   generated/dependency exclusions that define the inventory universe.

Deliberate limits on this report:

- The vendored trees are summarised **at directory level** (structure, file counts, provenance,
  contribution). This is *not* a line-by-line review of `.agents/**`, `.claude/**`, `.opencode/**`,
  `.idea/**`, `.codex/**` or `.reticle/**`, and nothing below should be read as one. The
  exhaustive per-file coverage for the whole repository - vendored included - lives as one line
  per file in `docs/deep-review/file-inventory.md`.
- The deep, line-by-line review of AgriFlow application source belongs to the other leaves
  (Flutter `flutter-01..06`, UI/UX `uiux-visual-reference.md`, React `react-01/02`,
  repo meta `repo-01-root-docs-scratch.md`). This leaf only assigns each file to its owning
  document; it does not restate their findings.
- No backend endpoint is cited here. This leaf is about classification and inventory, not the
  API surface; the API contract work is covered by `openapi_dump.json` and the Flutter/React leaves.

## Files reviewed

Directory-level review of the vendored trees, with representative file citations inside each:

FILE: .agents/rules/backend_api_memory.md
FILE: .agents/skills/animate/SKILL.md
FILE: .agents/skills/impeccable/SKILL.md
FILE: .agents/skills/impeccable/scripts/bin/windows-x64/impeccable.exe
FILE: .claude/settings.local.json
FILE: .claude/agents/impeccable-documenter.md
FILE: .claude/skills/impeccable/SKILL.md
FILE: .opencode/package.json
FILE: .opencode/commands/impeccable.md
FILE: .opencode/skills/impeccable/SKILL.md
FILE: .idea/workspace.xml
FILE: .idea/libraries/Dart_SDK.xml
FILE: .idea/runConfigurations/main_dart.xml
FILE: .codex/hooks.json
FILE: .reticle/.gitignore
FILE: skills-lock.json
FILE: .reticle-setup-crash.log

Inventory artefact produced and verified by this leaf:

FILE: docs/deep-review/file-inventory.md

The exhaustive per-file listing (851 lines) is in the manifest; the paths above are the
representative members cited from each vendored tree, as required for directory-level review.

## Vendored trees

All six trees plus `skills-lock.json` are agent/IDE tooling installed by, or written for, the
coding agents used on this project. None of it is AgriFlow project source: nothing here is
compiled, bundled or shipped by the Flutter or React builds, and no path in these trees is read
by the application at runtime. (The trees do contain Dart and JavaScript files - skill examples
such as `json_patterns.dart` and the `impeccable` helper scripts - but those are skill content,
not application code.) Together they account for **274 of the 851** inventoried files, all classed
`VENDORED` and all owned by this document.

**`.agents/` - 148 files, ~17.2 MB.** The primary agent skill store plus one rules file.
Layout: `rules/` (1 file) and `skills/` (46 directories: 45 general skills - `animate`, `ponytail`,
`flutter-*`, `dart-*`, `design-taste-frontend`, `unlazy`, `write-swift` and so on - plus the
`impeccable` design-review skill, 147 files in total). Content is Markdown skill definitions,
recipe files, small `.mjs`/`.js` helper scripts and JSON data. The `impeccable` copy carries the
bulk of the weight: a 14.4 MB Windows binary `scripts/bin/windows-x64/impeccable.exe`, a 1 MB
`font-index.json`, and a 0.5 MB `live-browser.js`. The one AgriFlow-specific file in the tree is
`rules/backend_api_memory.md`, which is agent memory about this project's backend contract - it
is tooling knowledge about the app, not app source. These skills are third-party (installed from
GitHub sources such as `emilkowalski/skills` and hashed in `skills-lock.json`); they contribute
agent capability (design review, animation, Flutter/Dart conventions, review discipline) and are
consumed by opencode/Claude/Codex sessions, never by `flutter build`.

**`.claude/` - 57 files, ~16.1 MB.** Claude Code configuration. `settings.local.json` registers
PostToolUse/Stop hooks that invoke the `impeccable` skill; `agents/` holds 4 subagent definitions
(`impeccable-asset-producer`, `impeccable-documenter`, `impeccable-finish-reviewer`,
`impeccable-manual-edit-applier`); `skills/` contains a second real copy of `impeccable`
(52 files) plus **45 directory junctions** that point at `.agents/skills/*` (verified: every
junction target resolves inside `.agents/skills/`). The junctions are filesystem links, not
files, so the inventory enumeration skips them - the 57 inventoried `.claude` files are the real
ones. This tree contributes hook wiring and subagent personas to Claude sessions only.

**`.opencode/` - 61 inventoried files out of 3,728 on disk (~68.6 MB).** opencode configuration:
`commands/` (6 slash-command files: `impeccable`, `ponytail`, `ponytail-audit`, `ponytail-help`,
`ponytail-review`, `unlazy`), a real `skills/impeccable` copy (52 files), plus `package.json` and
`package-lock.json` (pinning `@opencode-ai/plugin` 1.18.32) and a `.gitignore` that ignores
`node_modules`, `package.json`, `package-lock.json`, `bun.lock` and itself. The remaining
**3,667 files (~52.5 MB) are `.opencode/node_modules/`**, a dependency tree excluded from the
inventory by the same `node_modules` rule that applies at the repository root. This tree
contributes opencode command entry points and the plugin dependency; nothing here is executed by
the Flutter or React applications.

**`.idea/` - 5 files, ~4 KB.** JetBrains (IntelliJ/Android Studio) project metadata:
`modules.xml`, `workspace.xml` (open editors, caret and selection state), `libraries/Dart_SDK.xml`,
`libraries/KotlinJavaRuntime.xml`, `runConfigurations/main_dart.xml`. It is IDE session
configuration; the app neither reads nor ships it.

**`.codex/` - 1 file.** `hooks.json`, registering Codex `PostToolUse` and `Stop` hooks that call
`.agents/skills/impeccable/scripts/impeccable` (guarded by an existence test; the target exists).
It is agent hook configuration, not application code.

**`.reticle/` - 1 file.** A single `.gitignore` written by the Reticle tool for its own state
directories (`sessions/`, `runs/`, `visual/` ignored; `contract.json`, `flows/`, `intent.json`,
`capsules/` deliberately tracked). There is no Reticle session and no flow state in this
repository; the only other Reticle trace is the root `.reticle-setup-crash.log`, classed
`GENERATED`, which records an `EPIPE` failure during `@reticlehq/server` setup.

**`skills-lock.json` (root) - 1 file.** The install lockfile for the skill sets: skill name,
GitHub source, skill path and content hash. It is the provenance record for the vendored skills,
so it is classed `VENDORED` with this document rather than `CONFIG`.

Why none of it is project source: every vendored file is keyed to a coding agent, an IDE or a
skill-install tool; the AgriFlow app's own surface is `lib/`, `test/`, `assets/`, `android/`,
`ios/`, `web/`, `windows/`, `linux/`, `macos/`, `agriflow/`, `scratch/`, `docs/` and the root
project files - and none of those paths appears in the `VENDORED` class.

## Classification rules

Classification is first-match-wins, applied in this exact order by the generator
(`.unlazy/deep-review/scripts/gen-manifest.mjs`, function `classify`), and every one of the 851
files matches exactly one rule:

1. **`VENDORED`** - path starts with `.agents/`, `.claude/`, `.opencode/`, `.idea/`, `.codex/`
   or `.reticle/`, or the file is `skills-lock.json`. Reason: third-party agent/IDE tooling,
   summarised by directory, owned by this document. *274 files.*
2. **`GENERATED`** - `.reticle-setup-crash.log`. Reason: machine-written artefact of a tool run,
   carries no reviewable intent. *1 file.*
3. **`DOC`** - path starts with `docs/` (everything under `docs/` except the excluded
   `docs/deep-review/` corpus). Reason: prose/specification, reviewed as documentation rather
   than as code. *9 files.*
4. **`REVIEW`** - path starts with `scratch/`. Reason: analysis scratch space, read and analysed
   but not product source. *59 files, owned by `repo-01-root-docs-scratch.md`.*
5. **Flutter `DEEP`/`REVIEW`** - `lib/main.dart`, `lib/app.dart`, `lib/core/**` are `DEEP`
   (`flutter-01`); `lib/features/{auth,admin,manager,dashboard}/**` are `DEEP` (`flutter-02`);
   `lib/features/{farmers,farm_visits,grain_sales,booking_slot}/**` are `DEEP` (`flutter-03`);
   `lib/features/{seeds_inventory,seed_purchase}/**` are `DEEP` (`flutter-04`); any other
   `lib/features/<name>/**` whose name is in the placeholder set (`booking_slots`, `billing`,
   `cache`, `credits`, `event_logs`, `managers`, `market_rates`, `notifications`, `profile`,
   `reports`, `warehouse`) is `REVIEW` (`flutter-04`); everything else under `lib/` is `DEEP`
   (`flutter-04`). Reason: real feature/core code is line-by-line reviewed, placeholder feature
   directories are only read and analysed. *33 `REVIEW` + 142 `DEEP` under `lib/`.*
6. **`DEEP`** - `test/**`. Reason: the test suite is reviewed line-by-line. *16 files,
   `flutter-05-test-suite.md`.*
7. **`ASSET`** - path starts with `assets/`. Reason: shipped binary media. *1 file.*
8. **`PLATFORM`** - path starts with `android/`, `ios/`, `web/`, `windows/`, `linux/` or
   `macos/`. Reason: Flutter platform scaffold owned by `flutter-06-platform-targets.md`.
   *142 files.*
9. **`REVIEW` (visual reference)** - path starts with `agriflow/ui-ux/`, or the file is a
   root-level `*.html` mockup. Reason: these are the design reference pack, read and analysed by
   `uiux-visual-reference.md`; the path rule deliberately outranks the media-extension rule, so
   the PNG/MP4 files inside the pack are `REVIEW`, not `ASSET`. *19 files.*
10. **React `DEEP`/`REVIEW`/`CONFIG`** - `agriflow/agriflow-web/src/**` is `DEEP`
    (`react-01-ui-workflows.md`); other `agriflow/agriflow-web/**` is `REVIEW` unless the file is
    `package.json`, `package-lock.json`, `vite.config*`, `tailwind.config*`, `postcss.config*`,
    `.eslintrc*`, `netlify.toml` or `vercel.json`, which are `CONFIG`. Reason: the React site is
    a workflow reference, its `src/` layer is reviewed line-by-line, its build configuration is
    configuration. *72 `DEEP` + 61 `REVIEW` + 9 `CONFIG`.*
11. **`CONFIG` (Flutter project config)** - exactly `pubspec.yaml`, `pubspec.lock`,
    `analysis_options.yaml`, `.metadata`, `.flutter-plugins-dependencies`, `agriflow_admin.iml`,
    `.gitignore`. Reason: project/tooling configuration owned by
    `flutter-01-core-entry-config.md`. *7 files; with rule 10's 9 that makes CONFIG = 16.*
12. **`DOC` (root documents)** - exactly `AGENTS.md`, `GEMINI.md`, `README.md`,
    `openapi_dump.json`. Reason: root documentation/specification, owned by
    `repo-01-root-docs-scratch.md`. *4 files; with rule 3's 9 that makes DOC = 13.
    (`skills-lock.json` is listed here in the generator but rule 1 catches it first.)*
13. **`ASSET` (media extension)** - `\.(png|jpe?g|gif|ico|webp|mp4)$` anywhere that has not been
    claimed by an earlier rule. Reason: binary media, no lines to read. Only 2 files reach this
    rule: `brandLogo_decoded.jpeg` and `decoded_logo.png` at the repository root. The eight media
    files under `agriflow/agriflow-web/public/` are already claimed by rule 10 (`REVIEW`), which
    is why `ASSET` totals 3 = 1 (rule 7) + 2 (this rule).
14. **Fallback `CONFIG`** - anything left over, owned by `repo-01-root-docs-scratch.md`. Reason:
    conservative default. *0 files at the time of verification - every file is claimed by rules
    1-13.*

Class vocabulary used in the manifest: `DEEP` (line-by-line reviewed), `REVIEW` (read and
analysed), `VENDORED` (third-party agent tooling, directory-level), `GENERATED`
(machine-written), `ASSET` (binary/media), `CONFIG`, `DOC`, `PLATFORM` (platform scaffold).
Counts in the verified manifest: VENDORED 274, DEEP 230, REVIEW 172, PLATFORM 142, CONFIG 16,
DOC 13, ASSET 3, GENERATED 1 = 851.

## Generated and dependency exclusions

The inventory universe is "every file in the repository" minus seven trees, implemented as
`SKIP_DIRS = {.git, node_modules, .dart_tool, build, .gradle, .unlazy}` (matched at any depth) and
`SKIP_PREFIXES = {docs/deep-review/}` in both `gen-manifest.mjs` and `check-manifest.mjs`:

| Excluded tree | Evidence it exists (or does not) | Why excluded |
|---|---|---|
| `.git/` | **absent at review time** (this workspace is not a git repository) | Version-control internals; the rule stays so the manifest does not change when the repo is initialised. |
| `node_modules/` | absent at the repository root, but present as `.opencode/node_modules/` with **3,667 files (~52.5 MB)** | Third-party dependency trees, re-installable from lockfiles; excluded by the same rule at any depth. |
| `.dart_tool/` | present, **57 files (~105 MB)** | Dart/Flutter tool cache (`package_config.json`, asset graph). |
| `build/` | present, **1,298 files (~2 GB)** | Flutter/Gradle build output, fully reproducible. |
| `.gradle/` | **absent from the workspace** at review time; the Gradle cache lives in the user profile instead (verified: `~/.gradle` exists). The project's own Gradle files (`android/gradle.properties`, `android/gradle/wrapper/*`) are *not* excluded and are inventoried as `PLATFORM`. | Gradle cache would be a no-op in this workspace but is excluded defensively. |
| `.unlazy/` | present, **32 files** | Review-run machinery: gates, plans, scripts, status log - review process, not project content. |
| `docs/deep-review/` | present - this manifest plus the 11 review reports of the run (12 files at the time of writing). Evidence that it is excluded: the manifest lives in that directory and does not list itself or any sibling report. | Review output itself; excluding it keeps the manifest stable while leaves are still writing. |

Because the same enumerator runs in the generator and in the checker, the manifest and the gate
agree on the universe by construction; this leaf re-verified that agreement independently (see
Findings). One consequence worth stating: **directory junctions are not files**, so the 45
junctions under `.claude/skills/` are intentionally absent from the manifest - listing them would
double-count content already inventoried under `.agents/skills/`.

## Findings

1. **Manifest was incomplete by one file - corrected.** `docs/milestones/m5-seed-inventory-backend-contract-verification.md`
   was created at 12:29, after the manifest was generated at 12:19, so it had no `INV` line.
   An independent re-enumeration of the repository (same skip rules) against the manifest showed
   `851 actual / 850 listed / 1 missing / 0 extra / 0 duplicates`. I added exactly one line, in
   sorted position, classified `DOC` owned by `repo-01-root-docs-scratch.md` - identical to what
   re-running the generator would produce. After the fix: **851 listed, 851 actual, 0 missing,
   0 extra, 0 duplicates.** No other entry was added, removed or reclassified; a rule-by-rule
   re-implementation of `classify()` over the live tree showed **0 classification differences**
   against the manifest.
2. **All 8 classes are valid and in use**, and every `<doc>` column value points at a review
   document under `docs/deep-review/`. When this leaf first ran `check-manifest.mjs`, three of
   those documents (`repo-01-root-docs-scratch.md`, `react-01-ui-workflows.md`,
   `react-02-services-and-backend.md`) were still being written by sibling leaves in the same
   batch, so the checker failed with `references missing document`. That was a sequencing
   artefact of the batch, not an inventory error: the class and owner assignments were already
   correct, and the gate reports `manifest coverage verified (851 files)` now that every sibling
   report has landed.
3. **No project source is parked as vendored, and no vendored file is parked as project.**
   `VENDORED` = 274 = `.agents` 148 + `.claude` 57 + `.opencode` 61 + `.idea` 5 + `.codex` 1 +
   `.reticle` 1 + `skills-lock.json` 1, exactly. No path under `lib/`, `test/`, `agriflow/`,
   `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`, `assets/`, `scratch/` or `docs/`
   carries the `VENDORED` class.
4. **One AgriFlow-specific file lives inside a vendored tree**: `.agents/rules/backend_api_memory.md`
   holds project backend invariants for agents. It is correctly `VENDORED` for inventory purposes
   (it is agent tooling, not application source), but it is the only project-specific content in
   the six vendored trees - everything else there is generic, third-party tooling.
5. **The `impeccable` skill exists three times**: `.agents/skills/impeccable` (57 files),
   `.claude/skills/impeccable` (52 files) and `.opencode/skills/impeccable` (52 files), each with
   its own 14.4 MB `impeccable.exe` - about 43 MB of binaries for one skill. The copies have
   drifted: the `.agents` copy has 5 extra files (`agents/*.toml`, `agents/openai.yaml`), **32 of
   the 52 files shared with the other two copies differ by hash**, and the `.claude` and
   `.opencode` copies differ from each other on 20 files - so the three agents are not running
   the same skill version.
6. **Vendored trees were not line-reviewed, and are not presented as such.** Everything in
   `## Vendored trees` is structure, counts and provenance sampled from representative paths;
   the 274 files are covered by the manifest only.
7. **Borderline classifications left as-is (deliberate, documented):** media under `agriflow/ui-ux/`
   is `REVIEW` rather than `ASSET` because the whole ui-ux pack is the visual reference under
   review (rule order puts the path rule ahead of the extension rule); `ios/**/ephemeral/**` and
   `macos/Flutter/ephemeral/**` are `PLATFORM` rather than `GENERATED` because they belong to the
   platform target tree owned by `flutter-06`; `.flutter-plugins-dependencies` and `pubspec.lock`
   are `CONFIG` although the tooling rewrites them; `agriflow/agriflow-web/src/assets/react.svg`
   is `DEEP` because it sits under the React `src/` tree; `agriflow/ui-ux/.vscode/settings.json`
   is `REVIEW` for the same path-first reason. Changing any of these would only shuffle which
   leaf owns the citation, so none was changed.
8. **Machine-local noise is inventoried as it stands**: `.idea/workspace.xml` stores editor state,
   `.claude/settings.local.json` stores hook configuration, and `.reticle-setup-crash.log` is a
   tool crash dump at the repository root. All three are real files and are inventoried
   (`VENDORED`, `VENDORED`, `GENERATED` respectively).

## Recommendations

1. **(Highest)** Deduplicate the `impeccable` skill: keep one canonical copy under `.agents/skills/`
   and replace the `.claude` and `.opencode` copies with junctions, the pattern already used for
   the other 45 skills in `.claude/skills/`. Saves ~29 MB (two of the three 14.4 MB binaries) and
   removes the version drift described in Findings 5. Owner: whoever maintains agent tooling; no
   AgriFlow source involved.
2. **Treat the manifest as a snapshot, not a live index.** The one-file gap proves it drifts when
   files are added mid-run. Re-run `node .unlazy/deep-review/scripts/gen-manifest.mjs` (or
   `check-manifest.mjs`) after any batch that writes outside `docs/deep-review/`, and keep the
   checker as the authority rather than hand-editing entries.
3. **Decide the home of `.agents/rules/backend_api_memory.md`.** Either accept it as agent
   tooling (current classification) or fold it into `AGENTS.md` so project knowledge does not live
   only inside a vendored tree.
4. **Before this repository becomes a git repo**, ignore or drop `.idea/workspace.xml`,
   `.reticle-setup-crash.log` and `.opencode/package-lock.json` churn; they are machine state,
   not shared configuration. (`node_modules` under `.opencode/` should also be ignored - its
   `.gitignore` already tries to.)
5. **Only if Reticle verification is actually wanted**, re-run the `@reticlehq/server` setup that
   crashed (`EPIPE` in `.reticle-setup-crash.log`) and confirm a session appears; otherwise remove
   the crash log so `GENERATED` stays at the single deliberate entry it is today.
6. **Confirm the borderline class calls in Findings 7 with the driver** if the ownership of the
   ui-ux media or the ephemeral platform files matters to any leaf's `FILE:` citation budget;
   otherwise leave them, since they change no coverage result.
