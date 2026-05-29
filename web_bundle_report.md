# Web Build Bundle Analysis

**Updated:** 2026-05-29  
**Build:** `flutter build web --dart-define=FLUTTER_WEB_RENDERER=html --dump-info`  
**Flutter:** 3.41.9 (stable)

---

## Current Status

Phase 5 (HTML Renderer) completed. ✅

| Metric | Before (Phase 0) | Current | Δ |
|--------|------------------|---------|---|
| main.dart.js | 4.97 MB | 4.16 MB | −730 KB (14.7%) |
| Renderer wasm downloads | ~14 MB (canvaskit + skwasm + wimp) | 0 MB (HTML renderer) | −14 MB |
| Deferred chunks (lazy) | — | 604 KB (loaded on demand) | +604 KB |
| Total runtime transfer | ~19 MB | ~4.8 MB | −14.2 MB |

## Bundle Files (build/web/)

| File | Size | Notes |
|------|------|-------|
| main.dart.js | 4,361 KB | Initial load |
| main.dart.js_1.part.js | 543 KB | Deferred: pdf, archive, bidi |
| main.dart.js_7.part.js | 73 KB | Deferred: flutter_map |
| main.dart.js_{2-6}.part.js | 4 KB total | Deferred: overhead chunks |
| flutter.js | 10 KB | Flutter bootstrap |
| flutter_bootstrap.js | 10 KB | App bootstrap |
| flutter_service_worker.js | 1 KB | PWA service worker |
| canvaskit/ (do not deploy) | ~26 MB | Unused — remove before deploy |
| index.html | 4 KB | Entry point |

## Code Composition

| Category | Size | % of main.dart.js |
|----------|------|-------------------|
| flutter (framework) | 1,446 KB | 33.2% |
| app (application code) | 706 KB | 16.2% |
| dart:_engine | 510 KB | 11.7% |
| fl_chart | 71 KB | 1.6% |
| dart:core | 50 KB | 1.1% |
| riverpod | 45 KB | 1.0% |
| dart:async | 44 KB | 1.0% |
| dart:_js_helper | 42 KB | 1.0% |
| dart:ui | 33 KB | 0.8% |
| realtime_client | 33 KB | 0.8% |
| (remaining 120+ packages) | 403 KB | 9.2% |

## What's Deferred (not in initial load)

| Chunk | Packages | Size | Loaded When |
|-------|----------|------|-------------|
| 1 | pdf, archive, bidi, printing, csv | 530 KB | User clicks Download/Print Report |
| 7 | flutter_map, async, http | 72 KB | User navigates to checkout screen |

## Key Improvements

1. **HTML renderer**: eliminated ~14 MB of WebAssembly downloads (canvaskit.wasm + skwasm.wasm + wimp.wasm) and ~250ms+ WebAssembly compilation time.
2. **Deferred imports**: 604 KB of rarely-used code (PDF generation, map rendering) moved out of initial bundle.
3. **Total runtime transfer reduced** from ~19 MB to ~4.8 MB.

## Before vs After

| Before (Phase 0) | After (Phase 5) |
|---|---|
| 4.97 MB main.dart.js | 4.16 MB main.dart.js |
| 7 MB canvaskit.wasm | 0 MB (HTML renderer) |
| 3.5 MB skwasm.wasm | 0 MB |
| 3.5 MB wimp.wasm | 0 MB |
| PNG images | WebP images |
| Render-blocking Razorpay script | Lazy-loaded Razorpay |
| No deferred chunks | 604 KB deferred |

## Remaining Items

- Deploy Next.js manually (WhatsApp webhook)
- Sync root `prisma/schema.prisma`
- Crash reporting (Sentry/Firebase) — skip for now
