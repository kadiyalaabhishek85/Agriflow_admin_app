# UI/UX Visual Reference Review — AgriFlow Admin, Manager and Farmer Mockups

## Scope

This review covers the four root HTML mockups plus the whole `agriflow/ui-ux/` pack (19 files). The
mockups are single-file, self-contained prototypes: each one carries its own `:root` token block, its
own component CSS, an inline SVG icon sprite, and a vanilla-JS router that swaps `.screen` elements
inside a simulated 392×836 phone frame. They are the approved visual source of truth for the Flutter
Admin/Manager app under `lib/`, so this document records the extracted design system (palette, type,
layout, motion), enumerates every screen, and lists the gaps between the mockups and the current
Flutter implementation. Files were mined structurally (targeted searches for `:root`, `id="screen-"`,
`id="flow-"`, class definitions, `@media`, `@keyframes`, hex literals), not read linearly. The Flutter
cross-check was read-only against `lib/core/constants/app_colors.dart`, `lib/core/theme/app_theme.dart`,
`lib/core/constants/app_typography.dart`, `lib/core/navigation/nav_destination.dart` and
`lib/core/widgets/`. Nothing outside this document was created or modified.

## Files reviewed

FILE: AdminMobile UIUX.html
FILE: AdminMobile UIUX_screen_home.html
FILE: Manager Dashboard UIUX.html
FILE: Manager Dashboard UIUX_screen_home.html
FILE: agriflow/ui-ux/.vscode/settings.json
FILE: agriflow/ui-ux/AdminDashboard Mobile UI/AdminMobile UIUX.html
FILE: agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html
FILE: agriflow/ui-ux/FarmersMobileApp UI/Smart Agri Flow.mp4
FILE: agriflow/ui-ux/FarmersMobileApp UI/bajra.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/cotton.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/globe.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/groundnut.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/image.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/maize.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/onb_farmer_help_1784644890148.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/onb_mandi_prices_1784644862143.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/onb_track_crop_1784644792435.png
FILE: agriflow/ui-ux/FarmersMobileApp UI/onb_weather_water_1784644824818.png
FILE: agriflow/ui-ux/ManagerDashboard Mobile UI/Manager Dashboard UIUX.html

## Screen inventory

### Admin console — `AdminMobile UIUX.html` (479,590 bytes, 2,812 lines)

Three top-level flows: `flow-splash` (`AdminMobile UIUX.html:403`), `flow-login` (`AdminMobile UIUX.html:411`)
and `flow-app` (`AdminMobile UIUX.html:459`). Inside `flow-app` there are 25 screens: home/dashboard
(`:478`), seed purchase requests (`:643`), booking slots (`:669`), create booking slot (`:694`), farm
visits (`:750`), schedule farm visit (`:778`), grain sales (`:814`), log received crop (`:843`), seeds
inventory (`:890`), warehouse (`:905`), billing & invoices (`:919`), market rates (`:939`), reports &
analytics (`:953`), event logs (`:979`), managers (`:994`), all farmers (`:1009`), credits (`:1028`),
cache management (`:1048`), notifications (`:1063`), my account (`:1077`), edit profile (`:1119`),
settings (`:1135`), help & support (`:1162`), terms (`:1185`) and privacy (`:1199`). Chrome: a 4-item
bottom tab bar (`AdminMobile UIUX.html:1214`), a hamburger drawer with Overview / Operations /
Administration / Account groups (`AdminMobile UIUX.html:1224`), six bottom-sheet overlays — seed request
detail, slot detail, visit detail, sale detail, a generic edit sheet and a read-only farmer view
(`AdminMobile UIUX.html:1264`–`:1304`) — and a pill toast (`AdminMobile UIUX.html:1312`).

### Manager dashboard — `Manager Dashboard UIUX.html` (623,356 bytes, 3,374 lines)

Flows: splash (`:453`), login (`:461`), main app (`:511`). Eighteen screens: home (`:530`), seed
purchase (`:642`), booking slots (`:668`), create slot (`:688`), farm visits (`:744`), grain sales
retitled **"Crop Procurement"** (`:776`), seeds inventory (`:809`), warehouse (`:835`), billing
(`:849`), market rates (`:917`), all farmers (`:931`), notifications (`:950`), account (`:964`),
edit profile (`:1006`), settings (`:1031`), help (`:1058`), terms (`:1081`), privacy (`:1095`).
The manager mockup pushes far more work into **dedicated full-page flows** rather than sheets — 15 of
them: edit stock (`:1190`), warehouse inventory (`:1230`), add time slot (`:1290`), add inventory
(`:1340`), schedule visit (`:1384`), visit detail (`:1448`), visit full detail (`:1461`), slot detail
(`:1474`), seed request detail (`:1487`), farmer profile (`:1500`), add bill (`:1514`), sale detail
(`:1613`), log received crop (`:1618`), add seed (`:1698`), add farmer (`:1777`). It keeps the same
six overlays (`:1156`–`:1227`), a **5-item** tab bar that adds Account (`Manager Dashboard UIUX.html:1111`)
and a leaner 3-group drawer (`Manager Dashboard UIUX.html:1121`).

### Farmer app — `agriflow/ui-ux/FarmersMobileApp UI/Farmers UIUX.html` (283,475 bytes, 4,954 lines)

Five flows: splash (`:1317`), language picker (`:1339`), 4-slide onboarding (`:1380`), login (`:1436`)
and main app (`:1623`). The login flow has three stacked views — `login-choice` with an autoplaying
video background (`:1438`), `login-new` signup (`:1497`) and `login-form` phone+password (`:1555`).
Fifteen screens: home (`:1645`), crops and cycles / fields (`:1869`), seed purchase (`:2096`), grain
slot booking (`:2550`), grow & learn (`:3545`), profile (`:3635`), personal info (`:3745`), agri
details (`:3790`), bank details (`:3852`), documents (`:3896`), transaction history (`:3951`), terms
(`:4035`), privacy (`:4050`), language (`:4065`), help (`:4080`). Five modals (add crop `:1990`,
purchase `:2818`, book slot `:2998`, invoice `:3110`, language `:3205`) and five overlays (field
detail `:4120`, product `:4210`, product details `:4250`, AI crop scanner `:4383`, scan results
`:4466`). A 5-tab bar — Home, Seed Purchase, Crops, Grain Sales, Account (`:4097`) — plus an
i18n layer of 44 `data-i18n` keys with an `I18N` dictionary at `:4695`.

### Duplicates between root and pack

The root and pack copies are **byte-identical, not diverged**. `AdminMobile UIUX.html` and
`agriflow/ui-ux/AdminDashboard Mobile UI/AdminMobile UIUX.html` are both 479,590 bytes with SHA-256
prefix `867A64D9AB46A5B4`; `Manager Dashboard UIUX.html` and
`agriflow/ui-ux/ManagerDashboard Mobile UI/Manager Dashboard UIUX.html` are both 623,356 bytes with
SHA-256 prefix `6CB98DAC86A80A81`. All four share mtime 2026-09-21 10:09:45, so neither side is
newer or richer — they are mirrors, and the pack is the canonical location. The two `*_screen_home.html`
fragments are extracts, not alternatives: `AdminMobile UIUX_screen_home.html` (11,374 B, 166 lines)
matches master lines 478–642 exactly once leading indentation is trimmed (0 mismatches), and
`Manager Dashboard UIUX_screen_home.html` (7,481 B, 113 lines) matches lines 530–641 (0 mismatches).
The farmer app has no root copy — it exists only inside the pack. `agriflow/ui-ux/.vscode/settings.json`
is a three-line Live Server config pinning port 5501.

## Cited design tokens

### Palette (all hex literals below occur verbatim in the source mockups)

Shared `:root` across all three apps (`AdminMobile UIUX.html:13`, `Manager Dashboard UIUX.html:13`,
`Farmers UIUX.html:13`): page/scaffold background `#F3F6EC`; card surface `#FFFFFF`; tinted surface
`#E9F0DD`; ink `#1C2A21`; secondary text `#657268`; tertiary text `#8B9689`; hairline border
`#E1E8D8`. Green ramp: `#15302A`, `#1F4438`, `#2E7D5B`, `#1F5C42`, `#7BC79A`. Warm ramp: `#E39A3B`,
`#F6E2BE`, `#B4794C`, `#F1E1D0`. Alert `#D9704C`. Navy brand ramp (admin/manager only, absent from
the farmer `:root`): `#1E3A5C`, `#16293F`, `#4C7BAA`. Manager adds three semantic aliases to `:root`
(`Manager Dashboard UIUX.html:38`–`:40`): `#28653F`, `#8A5C15`, `#A6431E`.

Status pill backgrounds/texts (`AdminMobile UIUX.html:135`–`:139`): good `#DFF0DF` on `#28653F`;
warn `#F6E2BE` on `#8A5C15`; bad `#F7DDD2` on `#A6431E`; info `#E1EBF6` on `#16293F`.

Dashboard icon-tile tints reused on every stat card and quick action
(`AdminMobile UIUX_screen_home.html:21`, `:27`, `:33`, `:39`): sky `#ECF5FD` with stroke `#0369A1`,
leaf `#F0F8EC`, sand `#FDF5EC` / `#FDF3E5`, lilac `#F4F2F7` with stroke `#6B4C9A`.

Dark surfaces: splash/drawer header gradient `#16293F` → `#1E3A5C` with `#EEF3F9` foreground
(`AdminMobile UIUX.html:198`, `:281`, `:11` of both `_screen_home.html` files); notch/island `#0B1512`
(`AdminMobile UIUX.html:94`); button-on-navy label `#3B2506` for `.btn.amber`
(`AdminMobile UIUX.html:161`). Desktop preview backdrop radial gradient `#EAF1DC` → `#DCE6C9` →
`#CFDCBB` (`AdminMobile UIUX.html:48`). Farmer-only brand greens: `#6CC070` (`Farmers UIUX.html:1326`),
`#4ADE80`, `#16A34A`, and the weather-strip ink `#EFF6E8` (`Farmers UIUX.html:1657`). Manager tables
use a raw `#E0E0E0` rule (`Manager Dashboard UIUX.html:899`).

### Radii

Tokenised: `--radius-sm: 12px`, `--radius-md: 18px`, `--radius-lg: 26px` (`AdminMobile UIUX.html:36`–`:38`).
Component-level: phone body 52px (`:80`), screen clip 40px (`:88`), bottom sheet `30px 30px 0 0`
(`:180`), buttons 14px (`:158`), icon buttons 13px (`:143`), inputs 14px (`:226`), chips and pills
100px (`:134`, `:170`), stat icon tile 10px (`:253`), quick-action tile 16px (`:261`), drawer row 14px
(`:286`), avatars 50%.

### Shadows

`--shadow: 0 10px 30px -12px rgba(21, 48, 42, 0.22)` and `--shadow-sm: 0 4px 14px -6px rgba(21, 48, 42, 0.18)`
(`AdminMobile UIUX.html:34`–`:35`) — the only two elevation tokens. Ad-hoc additions: device frame
`0 40px 80px -20px rgba(15, 30, 25, 0.55)` (`:82`), drawer `8px 0 40px rgba(0,0,0,0.25)` (`:277`),
navbar `0 2px 12px -6px rgba(21, 48, 42, 0.14)` (`:236`), back button `0 3px 10px rgba(22, 41, 63, .09)`
(`:150`), splash logo `0 20px 46px -14px rgba(0, 0, 0, 0.55)` (`:207`).

### Spacing scale

Page gutter `--section-pad: 0 22px` (`AdminMobile UIUX.html:130`), with negative-margin bleed
`margin: 0 -22px; padding: 0 22px` for edge-to-edge strips (`AdminMobile UIUX_screen_home.html:148`).
Vertical rhythm: screen top padding 6px, block gap 16px (list screens) / 20px (home), card padding
14–18px, grid gap 12px (`stat-grid`, `:251`), quick-action row gap 16px (`:259`), horizontal scroller
gap 13px (`:174`), chip gap 8px (`:168`), drawer row padding 12px (`:286`). Desktop body padding
32px/16px (`:56`).

## Typography

Three families loaded from Google Fonts (`AdminMobile UIUX.html:9`–`:11`, identical in manager and
farmer): **Fraunces** 400/500/600/700, **Manrope** 400–800, **JetBrains Mono** 400/500/600.
`body` is Manrope (`:49`); `.display` is Fraunces (`:72`); `.mono` is JetBrains Mono (`:73`). Money,
IDs, dates and counts are set in `.mono` (e.g. invoice amounts, farmer-count cards).

Declared size ladder, from the CSS and inline styles: 9.5px bar-chart labels
(`AdminMobile UIUX.html:317`), 10px quick-action labels and drawer badges (`:262`, `:292`), 10.5px tab
labels and stat deltas (`:120`, `:257`) and drawer section labels (`:285`), 11px eyebrow/pill/splash
badge (`:132`, `:134`, `:214`), 11.5px meta, 12px field labels (`:225`), 12.5px chips (`:170`), 13/13.5px
body and buttons (`:158`, `:291`), 14/14.5px inputs (`:228`), 15px section headings, 16px navbar name
(`:239`), 19px secondary screen titles, 20px screen titles, 21px stat values in Fraunces (`:255`),
22px greetings, 26px splash wordmark; the farmer app pushes to 30/32/34/36px for splash, login and
product imagery (`Farmers UIUX.html:1323`, `:1458`, `:2276`).

Weights actually used: 600 for Fraunces screen titles, 700 for labels/body emphasis, 800 for section
headings, buttons, stat values and drawer labels. The eyebrow is 11px/700, uppercase, `letter-spacing:
.09em` (`AdminMobile UIUX.html:132`).

Hierarchy per screen: eyebrow (uppercase, navy) → `.display` title at 19–22px/600 → ad-hoc
`font-size:15px; font-weight:800` div section headings → 13.5px body → 10.5–11.5px metadata. There is
essentially **no semantic heading markup**: admin and farmer contain zero `<h1>`–`<h6>` elements; the
manager contains exactly one (`Manager Dashboard UIUX.html:875`, an `<h3>` inside the billing card).

## Layout patterns

**App shell.** Device frame 392×836, radius 52, navy bezel (`AdminMobile UIUX.html:76`–`:84`); inside
it a column of navbar → scrollable `.content` (`:104`) → tab bar. The navbar (`:236`–`:240`) is a 44px
circular logo, a 16px/800 brand name, a 10px uppercase navy subtitle, and a 38px notification button
with a 6px `#D9704C` dot. The tab bar is frosted glass — `rgba(255, 255, 255, 0.86)` with
`backdrop-filter: blur(14px)` and a `#E1E8D8` top border (`:111`–`:116`) — with a 4px active dot that
scales in. The drawer is `82%` wide, capped at 320px, translated off-canvas with a 0.3s cubic-bezier
slide (`:275`–`:280`).

**Cards and grids.** `.card` = white, `var(--radius-md)`, 1px `--line` (`:156`). Stat grid is two
columns, 12px gap, with a 34px tinted icon tile, Fraunces value and 11px label (`:251`–`:257`). Quick
actions are a 4-column `qa-grid` of 52px squircle tiles with 10px labels (`:259`–`:262`). The farmer
home replaces `.qa-grid` with an inline grid and emoji glyphs instead of SVG icons
(`Farmers UIUX.html:1676`–`:1694`).

**Tables and lists.** Lists are `display:flex; flex-direction:column; gap:10–12px` cards — the dominant
pattern in all three apps. A real `<table>` exists exactly once, in manager billing
(`Manager Dashboard UIUX.html:897`), wrapped in `overflow-x:auto` with `min-width:300px` and 11px
uppercase `#657268` headers on a `#E0E0E0` rule.

**Chips, pills, buttons.** Chips are 100px-radius, 12.5px/700, transparent-ish white with a 1px border;
the active chip inverts to `#16293F` white (`:170`–`:172`) and lives in a horizontally scrollable
`.chip-row` (`:168`). Status pills are the five-state set documented above (`:134`–`:140`). Buttons are
13.5px/800, 14×18 padding, radius 14, with variants `primary` (navy), `amber`, `ghost`, `danger`,
`block`, plus a `.success` variant that exists only in the manager file
(`Manager Dashboard UIUX.html:299`).

**Forms.** Base pattern is `field-group` → `field-label` (12px/800) → `field-input-wrap` (1.6px border,
14×15 padding, radius 14) with `.error` state and an 11px `.field-error` (`AdminMobile UIUX.html:224`–`:231`).
The manager file is a strict superset: `form-card`, `form-illus` gradient banner, `form-head`,
scrolling `form-body`, sticky `form-footer` with safe-area padding, dashed `upload-zone`, `check-list`
and `field-row` (`Manager Dashboard UIUX.html:259`–`:297`). The admin file has none of these — it
builds long forms as flat screen sections.

**Empty and loading states.** `.empty-state` is a 60px circle + 14px title + 12px description
(`AdminMobile UIUX.html:305`–`:309`); it is invoked 20 times in admin and 10 times in manager.
`.skel` is a 1.4s background-position shimmer (`:311`–`:312`) but is only declared once per file and
barely used. The farmer mockup defines **neither** component — zero empty states, zero skeletons.

**Responsive behaviour.** Exactly one breakpoint in each file: `@media (max-width:480px)`
(`AdminMobile UIUX.html:60`, `Manager Dashboard UIUX.html:61`, `Farmers UIUX.html:65`) which drops the
phone frame, runs edge-to-edge, and applies `env(safe-area-inset-*)` to navbar, splash, tab bar and
drawer. There is no tablet/desktop reflow — the mockups are phone-only.

**Motion.** Screen change `fadeIn` 0.35s ease with a 6px rise (`:106`, `:109`); sheet `sheetUp` 0.32s
`cubic-bezier(.2,.9,.25,1)` (`:180`–`:182`); drawer 0.3s same curve (`:278`); toast 0.28s (`:301`);
tactile press `scale(.97)` on cards and `scale(.9)` on chips/tabs/icon buttons (`:246`–`:247`);
`pulseHint` 1.8s infinite on the splash hint (`:218`); `skel` 1.4s infinite (`:312`); the farmer file
adds `scanMove`, `pulse` and `scaleUp`. **No file declares `prefers-reduced-motion`.**

## Findings

**The visual system as a Flutter contract.** A conforming Flutter screen must: use `#F3F6EC` as the
scaffold, white cards with an 18px radius and a 1px `#E1E8D8` border; render every list as a 10–12px
gapped column of those cards; use Fraunces 600 at 20–22px for screen titles with an 11px uppercase
navy eyebrow above it; use JetBrains Mono for any rupee amount, ID or count; use the 4-col quick-action
grid with 52px tinted tiles; and use the five-state pill set verbatim. `lib/core/constants/app_colors.dart:3`
already mirrors the whole `:root` block line-for-line, and `AppTypography` (`lib/core/constants/app_typography.dart:11`)
mirrors the family split — those two files are faithful. Where Flutter currently drifts: the mockup's
single elevation pair (`--shadow`, `--shadow-sm`) is expanded into three different lists in
`app_colors.dart:75`–`:97` with different blur/offset values, so cards in Flutter are softer than the
mockup specifies; and the mockup's page backdrop radial gradient (`AdminMobile UIUX.html:48`) is
absent from Flutter (`EAF1DC`/`CFDCBB` appear zero times in `lib/`), leaving a flat
`scaffoldBackgroundColor`.

**Mockups that contradict themselves.** (1) The bottom tab bar's active item is hard-coded to
`seed-purchase` while the initially active screen is `home`
(`AdminMobile UIUX.html:1216` vs `AdminMobile UIUX.html:478`; same in manager at
`Manager Dashboard UIUX.html:1112` vs `:530`) — on first paint the highlighted tab does not match the
rendered screen. (2) The admin tab bar has four items and the manager has five (manager adds Account,
`Manager Dashboard UIUX.html:1116`), yet both carry the same comment claiming four
(`AdminMobile UIUX.html:1214`, `Manager Dashboard UIUX.html:1110`). (3) The manager home omits the
admin home's "System Overview" block and "More Tools" grid entirely
(`Manager Dashboard UIUX_screen_home.html:46`–`:87` vs `AdminMobile UIUX_screen_home.html:46`–`:140`),
so the two dashboards do not share a skeleton. (4) The same feature is titled differently per role —
"Grain Sales" (`AdminMobile UIUX.html:820`) vs "Crop Procurement" (`Manager Dashboard UIUX.html:781`).
(5) The farmer home screen renders a back chevron wired to `showFlow('login')`
(`Farmers UIUX.html:1650`) — a back control that exits the app on the root screen.

**Mockup content the Flutter app does not implement.** `lib/core/navigation/nav_destination.dart:122`
declares 19 destinations, but only 13 screen files exist under `lib/**/screens/`; billing, market
rates, warehouse, reports, event logs, managers, credits, cache management, notifications, account,
settings and help all resolve to `ModulePlaceholderScreen`. Settings rows for Terms and Privacy, which
the mockup offers (`AdminMobile UIUX.html:1148`, `:1153`), have no `NavDestination` at all, and neither
do the sub-flows `create-slot`, `schedule-visit` or `log-crop` that the mockups treat as first-class
screens (`AdminMobile UIUX.html:694`, `:778`, `:843`). The manager mockup's 15 full-page forms have no
Flutter counterpart. The farmer app is entirely unimplemented in `lib/` — no onboarding, language
picker, i18n dictionary, AI crop scanner or crop imagery screens exist.

**Accessibility.** Contrast fails WCAG AA in the default UI: `--text-faint` `#8B9689` on the
`#F3F6EC` background computes to **2.82:1**, and on white to **3.08:1** — it is used for inactive tab
labels at 10.5px (`AdminMobile UIUX.html:119`), drawer section labels (`:285`), `.req-meta` (`:267`),
chart labels at 9.5px (`:317`) and every input placeholder (`:229`). `#657268` on the tinted
`#E9F0DD` chip/avatar surface is **4.32:1**, also below 4.5:1. Touch targets are undersized relative
to the 44×44pt guideline: `.icon-btn` is 38×38 (`:142`), `.chip` computes to roughly 35px tall (`:170`),
and `.switch-track` is 42×24 (`:323`). Semantics are almost absent: the admin file has 8 `aria-label`
attributes across 154 `<button>` elements (72 of which contain only an SVG), the manager file has
**0** across 110 buttons, and the farmer file has **0** across 125 buttons; admin and farmer contain
no heading elements whatsoever, so there is no document outline for a screen reader. Finally, motion
is unconditional — no `prefers-reduced-motion` guard exists in any of the three sources.

**Asset weight.** The admin and manager mockups inline their brand logo as base64 — 4 blobs totalling
~248 KB in admin and ~399 KB in manager, i.e. 52% and 64% of each file. The farmer mockup instead
references external images, but they are enormous for their rendered size: `image.png` is 2,962,801
bytes yet displayed at 160×160 (`Farmers UIUX.html:1455`), `bajra.png` is 1,726,245 bytes
(`Farmers UIUX.html:2274`), `groundnut.png` 1,772,008 bytes (`:2438`), and `Smart Agri Flow.mp4` is
7,268,941 bytes looped as a login background (`:1443`). `globe.png` (843,926 bytes) is **referenced by
no file in the repository** — it is dead weight; only the `#i-globe` SVG symbol
(`Farmers UIUX.html:1277`) and the language modal (`:3204`) use the concept.

## Recommendations

1. **Fix the tab-bar/screen desync first** — remove the hard-coded `active` class from
   `AdminMobile UIUX.html:1216` and `Manager Dashboard UIUX.html:1112` and let the router own it, or
   ship the Flutter `CustomTabbar` with home as the default index. This is a visible, user-facing
   wrong-state bug in both approved mockups.
2. **Raise `--text-faint` to at least 4.5:1 on `#F3F6EC`** (currently `AdminMobile UIUX.html:28`,
   ratio 2.82:1) and migrate `.tab` (`:119`), `.drawer-section-label` (`:285`) and `.bar-lbl` (`:317`)
   onto it; the same change belongs in `lib/core/constants/app_colors.dart:47`. Increase `.qa-lbl`
   from 10px (`:262`) and bar labels from 9.5px (`:317`) to ≥11px.
3. **Meet the 44pt touch minimum** by growing `.icon-btn` from 38px (`AdminMobile UIUX.html:142`),
   `.chip` padding from 9px (`:170`) and `.switch-track` from 24px tall (`:323`); apply the same to
   `lib/core/widgets/squircle_icon_button.dart:23`, whose default `size` is 38.0.
4. **Add semantics to the mockups and to Flutter**: give every icon-only button an `aria-label`
   (manager and farmer currently have zero across 235 buttons), replace the div-based screen titles
   with real headings, and add `Semantics(label:)` in `lib/core/widgets/` accordingly.
5. **Reconcile admin and manager before implementation** — decide one tab count (4 vs 5,
   `AdminMobile UIUX.html:1214` vs `Manager Dashboard UIUX.html:1111`), one dashboard section list
   (`AdminMobile UIUX_screen_home.html:46` vs `Manager Dashboard UIUX_screen_home.html:46`), and one
   name for the grain flow (`AdminMobile UIUX.html:820` vs `Manager Dashboard UIUX.html:781`).
6. **Port the manager-only form system** (`.form-card`, `.form-illus`, `.form-head`, `.form-body`,
   `.form-footer`, `.upload-zone`, `Manager Dashboard UIUX.html:259`–`:297`) into shared Flutter
   widgets; the admin mockup has no equivalent, so building screens without it will fork the design.
7. **Close the empty/loading gap in the farmer mockup** — port `.empty-state`
   (`AdminMobile UIUX.html:305`) and `.skel` (`:311`) into `Farmers UIUX.html`, and extend
   `lib/core/widgets/state_views.dart` to cover farmer contexts.
8. **Add a `prefers-reduced-motion` block** to all three sources (none exists) and mirror it with
   `MediaQuery.disableAnimations` in Flutter, keeping `fadeIn`/`sheetUp`/`skel` optional.
9. **Optimize and prune assets**: convert `image.png`, `bajra.png` and `groundnut.png` to WebP at
   2–4× display size, delete the unreferenced `globe.png`, and poster-frame `Smart Agri Flow.mp4`
   (7.27 MB) before autoplay.
10. **De-duplicate the root and pack copies** — the four HTML files are byte-identical
    (`867A64D9AB46A5B4`, `6CB98DAC86A80A81`), so keep the `agriflow/ui-ux/` copies as canonical and
    regenerate the two `*_screen_home.html` extracts from them to prevent future drift.
