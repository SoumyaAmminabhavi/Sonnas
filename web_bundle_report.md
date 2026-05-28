# Web Build Bundle Analysis — Before Optimization

**Date:** 2026-05-28
**Build:** `flutter build web --release --source-maps --dump-info`
**Flutter:** 3.41.9 (stable)

## Summary

| Metric | Value |
|--------|-------|
| main.dart.js total | 4854 KB (4.74 MB) |
| Mapped bytes | 2660 KB (54.8%) |
| Unmapped bytes | 2033 KB (41.9%) |
| EOL whitespace | 161 KB (3.3%) |

## Bundle Files (build/web/)

| File | Size |
|------|------|
| main.dart.js | 4,854 KB |
| canvaskit.wasm | 7,012 KB / 5,554 KB (auto-detected) |
| skwasm_heavy.wasm | 5,020 KB |
| skwasm.wasm | 3,467 KB |
| wimp.wasm | 3,381 KB |
| canvaskit.js | 85 KB |
| flutter_bootstrap.js | 10 KB |
| flutter.js | 9 KB |
| flutter_service_worker.js | 1 KB |
| main.dart.js_1.part.js | <1 KB |
| index.html | 2 KB |

## Code Composition (mapped portion of main.dart.js)

| Component | Size | % of Mapped | % of Total |
|-----------|------|-------------|------------|
| **flutter_sdk** | 1051.8 KB | 39.5% | 21.7% |
| **other (engine/internal)** | 511.1 KB | 19.2% | 10.5% |
| **dart_sdk** | 353.5 KB | 13.3% | 7.3% |
| **app_code** | 346.1 KB | 13.0% | 7.1% |
| fl_chart | 44.3 KB | 1.7% | 0.9% |
| pdf | 39.7 KB | 1.5% | 0.8% |
| flutter_map | 30.6 KB | 1.1% | 0.6% |
| riverpod | 29.5 KB | 1.1% | 0.6% |
| material_color_utilities | 21.7 KB | 0.8% | 0.4% |
| realtime_client | 17.8 KB | 0.7% | 0.4% |
| intl | 17.7 KB | 0.7% | 0.4% |
| gotrue | 17.2 KB | 0.6% | 0.4% |
| bidi | 11.8 KB | 0.4% | 0.2% |
| source_span | 11.4 KB | 0.4% | 0.2% |
| google_fonts | 10.9 KB | 0.4% | 0.2% |
| archive | 10.6 KB | 0.4% | 0.2% |
| vector_math | 10.3 KB | 0.4% | 0.2% |
| http | 9.4 KB | 0.4% | 0.2% |
| postgrest | 8.4 KB | 0.3% | 0.2% |
| supabase_flutter + supabase + storage_client | 13.5 KB | 0.5% | 0.3% |

## Largest Individual Files in main.dart.js (≥6 KB)

| File | Size |
|------|------|
| dart:_engine font_fallbacks | 157.0 KB |
| dart:_engine font_fallback_data | 87.0 KB |
| Flutter framework.dart | 39.3 KB |
| dart:ui geometry | 33.6 KB |
| dart:js_util | 32.1 KB |
| Flutter rendering/object | 27.1 KB |
| Flutter editable_text | 25.5 KB |
| Flutter input_decorator | 24.5 KB |
| Flutter rendering/box | 22.5 KB |
| dart:native_typed_data | 21.5 KB |
| Flutter time_picker | 20.4 KB |
| sales_reports_page.dart (app) | 18.5 KB |
| menu_page.dart (app) | 18.2 KB |
| Dart core/uri | 18.8 KB |
| Flutter semantics | 18.2 KB |
| whatsapp_settings_page.dart (app) | 17.7 KB |
| order_details_page.dart (app) | 15.5 KB |
| profile_screen.dart (app) | 15.3 KB |
| expense_reports_page.dart (app) | 13.5 KB |
| owner_settings.dart (app) | 12.3 KB |
| add_staff_page.dart (app) | 12.2 KB |
| staff_add_page.dart (app) | 11.2 KB |
| contact_screen.dart (app) | 9.4 KB |
| inventory_analytics_page.dart (app) | 9.3 KB |
| profile_page.dart (app) | 8.6 KB |
| dashboard_page.dart (app) | 8.5 KB |

## App Code Files (lib/)

| File | Size |
|------|------|
| lib/owner/sales_reports_page.dart | 18.5 KB |
| lib/owner/menu_page.dart | 18.2 KB |
| lib/owner/whatsapp_settings_page.dart | 17.7 KB |
| lib/owner/order_details_page.dart | 15.5 KB |
| lib/customer/screens/profile_screen.dart | 15.3 KB |
| lib/owner/expense_reports_page.dart | 13.5 KB |
| lib/owner/owner_settings.dart | 12.3 KB |
| lib/owner/add_staff_page.dart | 12.2 KB |
| lib/staff/management/staff_add_page.dart | 11.2 KB |
| lib/customer/screens/contact_screen.dart | 9.4 KB |
| lib/owner/inventory_analytics_page.dart | 9.3 KB |
| lib/staff/profile/profile_page.dart | 8.6 KB |
| lib/staff/dashboard/dashboard_page.dart | 8.5 KB |
| lib/customer/screens/menu_screen.dart | 7.8 KB |
| lib/owner/widgets/dashboard_content.dart | 7.7 KB |
| lib/customer/screens/payment_screen.dart | 6.9 KB |
| lib/customer/screens/orders_screen.dart | 6.7 KB |
| lib/staff/inventory/inventory_page.dart | 6.5 KB |
| lib/services/order_service.dart | 6.5 KB |
| lib/staff/auth/login_page.dart | 6.2 KB |
| lib/customer/screens/home_screen.dart | 6.0 KB |
| lib/customer/screens/tracking_screen.dart | 5.8 KB |
| lib/widgets/glass_order_sheet.dart | 5.8 KB |
| lib/customer/screens/checkout_screen.dart | 5.5 KB |
| lib/customer/main.dart | 5.5 KB |
| lib/owner/payments_page.dart | 5.4 KB |
| lib/customer/screens/auth_screen.dart | 5.3 KB |
| lib/owner/menu_details_page.dart | 4.9 KB |
| lib/owner/widgets/order_card.dart | 4.7 KB |
| lib/services/report_service.dart | 4.6 KB |
| lib/staff/operations/kitchen_page.dart | 4.3 KB |
| lib/customer/checkout_page.dart | 4.3 KB |
| lib/customer/screens/product_detail_screen.dart | 4.1 KB |
| lib/widgets/modern_drawer.dart | 4.1 KB |
| lib/customer/screens/cart_screen.dart | 3.5 KB |
| lib/owner/owner_dashboard.dart | 3.5 KB |
| lib/staff/management/staff_management_page.dart | 3.3 KB |
| lib/customer/screens/profile_setup_screen.dart | 3.1 KB |
| lib/services/menu_service.dart | 3.0 KB |
| lib/services/whatsapp_service.dart | 3.0 KB |
| lib/owner/orders_page.dart | 2.7 KB |
| lib/staff/operations/orders_page.dart | 2.5 KB |
| lib/customer/screens/self_checkout_screen.dart | 2.5 KB |
| lib/main.dart | 2.2 KB |
| lib/services/dashboard_provider.dart | 2.0 KB |
| lib/widgets/landing_page.dart | 2.0 KB |
| lib/customer/screens/order_success_screen.dart | 1.8 KB |
| lib/services/supabase_service.dart | 1.7 KB |
| lib/services/auth_service.dart | 1.6 KB |
| lib/models/order.dart | 1.6 KB |
| lib/services/staff_service.dart | 1.5 KB |
| lib/services/auth_provider.dart | 1.5 KB |
| lib/services/inventory_service.dart | 1.3 KB |
| lib/services/settings_service.dart | 1.2 KB |
| lib/widgets/staff_sidebar.dart | 1.2 KB |
| lib/customer/providers/cart_provider.dart | 1.2 KB |
| lib/widgets/owner_sidebar.dart | 1.1 KB |
| lib/customer/providers/favorites_provider.dart | 1.1 KB |
| lib/customer/screens/welcome_screen.dart | 1.0 KB |
| lib/widgets/glass_bottom_nav.dart | 0.9 KB |
| lib/services/session_service.dart | 0.9 KB |
| lib/widgets/secure_avatar.dart | 0.6 KB |
| lib/services/cart_provider.dart | 0.6 KB |
| lib/services/theme_service.dart | 0.6 KB |

## Key Observations

1. **Total JS payload**: 4.74 MB (main.dart.js) + ~20 MB of Wasm (CanvasKit/skwasm)
2. **App code is only 346 KB mapped** (7.1% of total JS) — most of the bloat is Flutter SDK + Dart engine
3. **Largest single file**: `font_fallbacks.dart` (157 KB in the CanvasKit engine)
4. **Biggest third-party packages**: fl_chart (44 KB), pdf (40 KB), flutter_map (31 KB), riverpod (30 KB)
5. **canvasKit.wasm**: 7 MB download — this is the single largest performance factor
6. **Google Fonts**: 11 KB code + runtime HTTP fetches for font files
7. **Unmapped 42%**: typical for minified dart2js output

## Optimization Targets

1. **Self-host fonts** → eliminate Google Fonts CDN round-trips
2. **Async/deferred Razorpay** → don't block initial render
3. **Route-based code splitting** → split into deferred chunks
4. **WebP images** → reduce image download sizes
5. **CanvasKit** → already using via `--dart-define=FLUTTER_WEB_RENDERER=canvaskit`
