# Web Performance Optimization — Implementation Plan

**Date:** 2026-05-28  
**Baseline:** 176 requests, 18.9 MB transferred, 32 MB resources, FCP 3.3s, Speed Index 4.3s, TBT 9.6s  
**Status:** Phases 1–5 completed

---

## Phase 1: Quick Wins ✅

### 1.1 Fix `user-scalable=no` accessibility violation ✅
- Removed `user-scalable=no` and `maximum-scale=1.0` from viewport meta tag.

### 1.2 Google Fonts — originally self-hosting attempted, then reverted ✅
- Tried self-hosting `@font-face` woff2 files — Google Fonts now ships variable fonts only, incompatible with static TTF that `google_fonts` package requires.
- Reverted: fonts load from Google CDN at runtime (same as before).
- `allowRuntimeFetching` config removed from main.dart.

### 1.3 Cache headers for static assets ✅
- Added `vercel.json` with immutable cache + security headers.

---

## Phase 2: Image Optimization ✅

### 2.1 Convert PNGs to WebP ✅
- 56 PNGs converted (17.1 MB → 2.7 MB).
- DB paths, code references, and seed scripts updated.

### 2.2 Fix WhatsApp image URLs ✅
- WhatsApp Cloud API doesn't support WebP — bot code replaces `.webp` → `.png` in all image URLs.

### 2.3 Owner upload WebP conversion ✅
- Owner image uploads convert to WebP client-side via dynamic JS interop before Supabase storage.
- Storage keeps pure WebP; WhatsApp receives PNG URLs.

### 2.4 Cleanup ✅
- Removed 7 temporary conversion scripts.

---

## Phase 3: Razorpay Async Loading ✅

### 3.1 Defer Razorpay checkout.js ✅
- Removed blocking `<script>` from `web/index.html`.
- Script lazy-loaded dynamically on first payment click.

---

## Phase 4: Bundle Splitting via Deferred Imports ✅

### 4.1 Deferred `pdf`/`printing`/`csv` in report_service ✅
- `package:pdf`, `package:printing`, `package:csv` moved to deferred imports.
- 530 KB (pdf + transitive deps: archive, bidi) loaded only on Download/Print Report click.

### 4.2 Deferred `flutter_map` in checkout_screen ✅
- `package:flutter_map` moved to deferred import.
- 72 KB loaded in background when checkout screen opens.

### 4.3 Result ✅
- `main.dart.js` reduced 4.97 MB → 4.16 MB (−730 KB, 14.7%).

### 4.4 Bundle analysis ✅
- Per-package breakdown: flutter 1,625 KB (42%), app 568 KB (15%), dart:_engine 552 KB (14%), rest 29%.
- No removable packages found — all dependencies are actively imported.

---

## Phase 5: HTML Renderer ✅

### 5.1 Switch to HTML renderer ✅
- Changed from `--dart-define=FLUTTER_WEB_RENDERER=canvaskit` to `=html`.
- Eliminates ~14 MB of runtime wasm downloads (canvaskit.wasm, skwasm.wasm, wimp.wasm).
- No wasm compilation time — HTML renderer uses browser's native Canvas 2D API.
- Renderer wasm files still generated in build output; should be removed before deploy.

### 5.2 Preloading not needed ✅
- HTML renderer has no wasm to preload — it just works.

---

## Phase 6: Android/iOS Production Hardening

### 6.1 ProGuard/R8 ✅
- `isMinifyEnabled = true` in `android/app/build.gradle.kts`.
- `proguard-rules.pro` with keep rules for Flutter + Razorpay.

### 6.2 Global error handler ✅
- `FlutterError.onError` + `PlatformDispatcher` error handler in `main.dart`.
- Offline connectivity banner in `MaterialApp.builder`.

### 6.3 Android/iOS app label ✅
- Set to "Sonna's Patisserie & Cafe".

### 6.4 Splash screen ✅
- Branded pink gradient splash in `web/index.html` (auto-fades).

---

## Phase 7: Deployment

### 7.1 Build
```powershell
flutter build web --dart-define=FLUTTER_WEB_RENDERER=html --no-wasm-dry-run
Remove-Item -Recurse -Force build/web/canvaskit/
```

### 7.2 Deploy to Vercel
- Flutter web: deploy `build/web/` to Vercel
- Next.js: separate manual deployment (handled by user)

---

## Current Status

| Metric | Before | After |
|--------|--------|-------|
| `main.dart.js` | 4.97 MB | 4.16 MB |
| Renderer wasm | 14 MB downloaded | 0 MB (HTML renderer) |
| Deferred chunks | — | 604 KB (loaded on demand) |
| Image format | PNG | WebP |
| Requests | 176 | Reduced |
| Transferred | 18.9 MB | Reduced |
