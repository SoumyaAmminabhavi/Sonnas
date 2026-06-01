# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.7] - 2026-06-01

### Image Rendering & WASM Stability

#### Added
- **`SafeWasmImage` Component**: Introduced a unified image loading widget ([wasm_image.dart](file:///c:/Arka/Bakery/Sonna/lib/widgets/wasm_image.dart)) that automatically chooses the correct image rendering strategy based on target platform.
  - **Web/WASM**: Renders natively using `Image.network` to leverage browser-native rendering and caching pipelines, bypassing the legacy JS interop exceptions that crashed WebAssembly.
  - **Mobile (Android/iOS)**: Uses `CachedNetworkImage` to maintain high-performance offline caching support.

#### Changed
- **Refactored All UI Pages**: Replaced direct instantiations of `CachedNetworkImage` with `SafeWasmImage` across all client, owner, and staff views:
  - Owner: `menu_page.dart`, `menu_details_page.dart`, `order_details_page.dart`, `sales_reports_page.dart`.
  - Customer: `catalog_page.dart`, `product_detail_page.dart`.
  - Staff & Shared: `glass_order_sheet.dart`, `kitchen_page.dart`, `orders_page.dart`.
- **Removed Unused Imports**: Cleaned up all unused `CachedNetworkImage` imports from those files to resolve compilation warnings.
- **Enclosed blocks**: Fixed lint warnings in [supabase_service.dart](file:///c:/Arka/Bakery/Sonna/lib/services/supabase_service.dart) regarding nested code blocks.

## [1.0.6] - 2026-05-31

### Phase 1 (Continued): Flutter Web Performance — Lighthouse 90+

#### Performance
- **Lighthouse score: 90** (measured on production build, desktop emulation).
  - FCP: 181 ms → score **100**
  - LCP: 257 ms → score **100**
  - CLS: 0 → score **100**
  - TBT: 222 ms → score **75**
  - Speed Index: 1,825 ms → score **70**
- **Icon tree-shaking**: MaterialIcons reduced **1,645 KB → 34 KB** (97.9%), CupertinoIcons reduced **258 KB → 1.5 KB** (99.4%) in release builds.

#### Changed
- **Build target: WASM** — switched production build from `--web-renderer html` to `--wasm`. Dart now compiles to WebAssembly instead of JavaScript, removing Dart execution from the JS main thread and significantly lowering Total Blocking Time.
- **Fonts fully bundled locally**: Migrated from `web/fonts/` (woff2) approach to `assets/google_fonts/` with the `google_fonts` package. Downloaded 17 font variant TTF files (Plus Jakarta Sans, Noto Serif). Set `GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart` — zero runtime font HTTP requests.
- **Eliminated `.env` 404 on web**: Added `!kIsWeb` guard around `dotenv.load()` in `lib/main.dart` — the browser no longer attempts to fetch a non-existent `assets/.env` file, eliminating a 404 console error on every load.
- **Splash animation speed**: Fade transition reduced `0.5s → 0.3s`, DOM removal delay reduced `600ms → 350ms` — visually settles ~500ms earlier, improving Speed Index.
- **Removed unused DNS preconnects**: Eliminated `fonts.gstatic.com` and `fonts.googleapis.com` preconnect links from `web/index.html` (fonts are now local; these were wasted DNS lookups).
- **Bootstrap loading**: Changed `flutter_bootstrap.js` from `async` to `defer` to ensure Flutter engine initializes only after full DOM parse and stable viewport dimensions.
- **HTML/body CSS reset**: Added `html, body { height: 100%; width: 100%; margin: 0; padding: 0; overflow: hidden; }` to guarantee the Flutter engine always receives valid positive viewport dimensions.
- **Viewport meta tag**: Removed conflicting custom viewport tag — Flutter Web injects its own; having both caused a console warning and renderer conflict.

#### Infrastructure
- **`scripts/build-web-prod.ps1`**: Rewritten — now defaults to `--wasm`, reads credentials from `.env` automatically, prints build size summary after compile. Accepts `-NoWasm` flag to fall back to JS release build.
- **`.github/workflows/deploy.yml`**: Updated CI/CD pipeline to use `--wasm` build; removed the now-unnecessary `Patch HTML Renderer and Clean CanvasKit` step.
- **`vercel.json`**: Added cache headers for `main.dart.wasm` and `main.dart.mjs` (WASM output files). Added `Cross-Origin-Embedder-Policy: require-corp` and `Cross-Origin-Opener-Policy: same-origin` headers globally — required for WASM `SharedArrayBuffer` / multi-threading support in Chrome and Firefox.

#### Fixed
- Viewport meta tag warning: `Found an existing <meta name="viewport"> tag. Flutter Web uses its own viewport configuration.`
- Console error: `GET /assets/.env 404 (Not Found)` on every web load.
- Console errors: `GoogleFonts: PlusJakartaSans-ExtraBold not found in application assets` (all 17 variants).

## [1.0.5] - 2026-05-30


### Phase 7: Staff Space Optimization (Clean UI & Spacing)

#### Changed
- **Unified Staff Headers**: Applied the compact uppercase theme (`fontSize: 12`, `color: cs.primary`, `letterSpacing: 2.5`) to headers and action areas across all staff pages including Dashboard, Inventory, Profile, and Management.
- **Staff Add / Edit Page**: Standardized nested and non-nested headers using uppercase styling, minimized vertical element spacings from `40` to `20`, and removed duplicate nested back buttons.
- **Layout Adjustments**: 
  - Reduced vertical spacing on Staff Dashboard from `48` to `24`, and converted stacked metrics cards into a single horizontal row with responsive padding and text scaling to align with the owner dashboard layout.
  - Optimized margins and layout dividers on Staff Inventory, Profile, and Management.
  - Swapped component container backgrounds from `cs.surfaceContainerLow` (pinkish) to `cs.surfaceContainer` (pure white) across all staff views (Dashboard, Kitchen, Orders, Inventory, Profile, Staff List, Add/Edit Pages), matching the owner portal's clean white-on-mild-pink look.
- **Bug Fixes & Flow Improvements**:
  - Integrated `PopScope` to intercept system/browser back presses when the nested "Add/Edit Staff" form is active, closing the form overlay cleanly rather than popping the whole application.
  - Fixed a `RenderFlex` overflow exception (by 13 pixels) in the staff operations overview tabbar header by tightening padding/spacing and adjusting the `PreferredSize` height to `115`.

## [1.0.4] - 2026-05-30

### Phase 6: Owner Space Optimization (Clean UI & Spacing)

#### Changed
- **Unified Header Theme**: Replaced bulky page headers on owner pages (Sales Reports, Expense Reports, Inventory Analytics, WhatsApp Settings, Orders Page, and Menu Page) with a unified, space-efficient uppercase label theme (`fontSize: 12`, `color: cs.primary`, `letterSpacing: 2.5`).
- **Layout and Spacing Reductions**:
  - Tightened vertical layout gaps (reduced spacing from `48` to responsive `32/20`) on the main Dashboard view.
  - Converted stacked KPI and analytics metrics cards to flat horizontal rows (`Row` with `FittedBox`) to eliminate excessive scrolling on mobile.
  - Reduced vertical margins on Order Details and Menu Details pages (cutting vertical spacers to `16/24/20`).
  - Streamlined Edit Menu Item and Add Staff forms (removing redundant subtitle views and decreasing form spacers).
- **Cleaned Code**: Removed unused widgets (such as the customer reviews section on the dashboard) to solve compiler warnings.

## [1.0.3] - 2026-05-29

### Phase 5: HTML Renderer (Eliminate Canvaskit Wasm)

#### Changed
- **Switched Flutter web renderer** from `canvaskit` to `html` via `--dart-define=FLUTTER_WEB_RENDERER=html`. The HTML renderer uses the browser's native Canvas 2D API instead of downloading and compiling 7 MB+ of WebAssembly.

#### Performance
- Eliminated **canvaskit.wasm (7 MB)** + **canvaskit.js (87 KB)** + **wimp.wasm (3.5 MB)** + **skwasm.wasm (3.5 MB)** runtime downloads — total **~14 MB** of renderer wasm files no longer fetched.
- Faster initial paint: HTML renderer begins rendering immediately without waiting for WebAssembly compilation.
- Text rendering uses browser's native engine (crisper text on all devices).
- No change to `main.dart.js` size (renderer selection is a runtime bootstrap decision).

### Phase 4: Deferred Imports (Bundle Splitting)

#### Changed
- **Deferred `package:pdf`, `package:printing`, `package:csv`** — moved to deferred imports in `lib/services/report_service.dart`. These 530 KB (pdf + transitive deps bidi, archive) and 1.7 KB (csv) are now loaded only when user clicks Download/Print Report, not on initial page load.
- **Deferred `package:flutter_map`** — moved to deferred import in `lib/customer/screens/checkout_screen.dart`. The 72 KB map rendering code loads in background when checkout screen opens (no visible delay — user fills form while map loads).

#### Performance
- Initial `main.dart.js` reduced from **4.97 MB → 4.16 MB** (−730 KB, **14.7% reduction**).
- No change to total transferred size (deferred chunks sum to ~604 KB, loaded on demand).

## [1.0.2] - 2026-05-28

### Phase 1: Quick Wins (Web Performance)

#### Fixed
- **Accessibility**: Removed `user-scalable=no` and `maximum-scale=1.0` from viewport meta tag in `web/index.html` — critical a11y violation (axe rule `meta-viewport`) that disabled zooming on mobile devices.

#### Changed
- **Fonts**: Self-hosted Google Fonts (Plus Jakarta Sans, Inter, Noto Serif, DM Serif Display) as local `.woff2` files in `web/fonts/`. Added `@font-face` CSS declarations and font preloads in `web/index.html`. Set `GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart` to eliminate ~1 MB+ of runtime HTTP fetches from Google Fonts CDN. Expected FCP improvement: 200-400ms.
- **Caching**: Added `vercel.json` with long-term cache headers (`max-age=31536000, immutable`) for static assets (fonts, JS, WASM, images, icons). Added security headers (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`).

#### Added
- `web/fonts/` directory with 6 self-hosted `.woff2` font files (latin subsets).
- `vercel.json` for Vercel deployment configuration and cache headers.
- `changelog.md` — this file.
- `contributing.md` — contribution guidelines.

### Previously (pre-changelog)

#### Fixed
- Dashboard revenue excludes custom orders (₹0 totalPrice).
- Dashboard chart counts only paid orders (fixed "Orders: 3 Amount: 0" tooltip).
- Sales report category matching with fuzzy name fallback.
- Completed `completedAt` column added to Supabase Order table.
- WhatsApp settings unified into single page.
- Staff profile self-editing with form validation and blood group dropdown.
- App label set to "Sonnas" on Android and iOS.
- Dine N Dash branding replaced with Sonna's in `web/index.html`.
- Duplicate viewport meta tag removed from `web/index.html`.

#### Added
- Time range selectors (Today/Weekly/Monthly/Yearly) for sales and expense charts.
- Stock distribution bar chart in inventory analytics.
- Payment status badge and custom item price editing in order details.
- WhatsApp settings inside staff Operations tab.
- Staff self-editing profile with form validation.

#### Changed
- Chart styling harmonized across dashboard, sales, expense, and inventory pages.
- Charts aggregate data by time bucket instead of showing last 7 entries.

#### Security
- Biometric auth verified: USE_BIOMETRIC (Android), NSFaceIDUsageDescription (iOS).
- `.env` file gitignored and copied to `assets/.env` for Flutter web.
