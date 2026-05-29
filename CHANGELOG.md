# Changelog

All notable changes to this project will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
- App label set to "Sonna's Patisserie & Cafe" on Android and iOS.
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
