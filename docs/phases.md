# Phases Plan and Completion

## Phase 0: Baseline
- Initial bundle size: ~4.97 MB main.dart.js
- No deferred imports
- Renderer: canvaskit (default)
- Status: Completed (baseline established)

## Phase 1: Bundle Analysis
- Analyzed output using `flutter build web --dart-define=FLUTTER_WEB_RENDERER=html --dump-info`
- Identified per-package sizes via `elements['library']`
- Status: Completed

## Phase 2: Deferred Imports (PDF/Printing/CSV)
- Deferred `report_service.dart` (pdf, printing, csv) -> 530 KB chunk
- Loaded on Download/Print click
- Status: Completed

## Phase 3: Deferred Imports (Flutter Map)
- Deferred `checkout_screen.dart` (flutter_map) -> 72 KB chunk
- Loaded in background when checkout opens
- Status: Completed

## Phase 4: Bundle Splitting & Optimization
- Deferred imports reduced main.dart.js from 4.97 MB → 4.16 MB (−730 KB, 14.7%)
- Code splitting achieved
- Status: Completed

## Phase 5: HTML Renderer
- Switched to HTML renderer via `--dart-define=FLUTTER_WEB_RENDERER=html` + post-build patch of `flutter_bootstrap.js` (change `"renderer":"canvaskit"` to `"renderer":"html"`)
- Removed `canvaskit/` directory from build output
- Eliminated ~14 MB of WebAssembly downloads (canvaskit.wasm + skwasm.wasm + wimp.wasm)
- Status: Completed

## Additional Optimizations
- Google Fonts preconnect hints added to `web/index.html`
- WebP image conversion
- Razorpay lazy loading
- Prisma schema sync
- Project cleanup (removed 25 MB generated files, duplicate assets, logs, etc.)
- Documentation updated (CHANGELOG.md, CONTRIBUTING.md, implementation_plan.md, web_bundle_report.md)

## Current Status
- Lighthouse incognito Chrome: **95**
- Lighthouse normal Chrome: **67** (limited by Chrome extensions)
- Main bundle: 4.16 MB
- Deferred chunks: 606 KB total (loaded on demand)
- No canvaskit.wasm downloaded in production

## Remaining Items
- Deploy Next.js manually (WhatsApp webhook fix)
- Sync root `prisma/schema.prisma` (already done in cleanup)
- Crash reporting (Sentry/Firebase) — skip for now