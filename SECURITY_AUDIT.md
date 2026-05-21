# Security Audit Report

**Date:** May 21, 2026
**Scope:** Full codebase review (54 Dart files + config/env/SQL)
**Status:** ✅ RESOLVED — Medium finding fixed

---

## Summary

The codebase follows solid security practices overall. No critical or high-severity vulnerabilities were found. One medium-severity issue was identified in build artifacts, and three low-priority notes for future hardening.

---

## Findings by Severity

### 🔴 Critical — None

No critical vulnerabilities found.

### 🟠 High — None

No high-severity vulnerabilities found.

### 🟡 Medium (1)

#### M-01: Build Artifact Secret Exposure — ✅ RESOLVED

**File:** `build/web/assets/.env` (and other build directories)
**Severity:** Medium (was) → Resolved
**Category:** Information Disclosure / Secret Management

**Issue:** The Flutter build process was bundling `.env` into build output because it was listed in `pubspec.yaml` assets.

**Fix Applied:**
1. Removed `.env` from `pubspec.yaml` assets list
2. Deleted all `.env` files from `build/` directories:
   - `build/web/assets/.env`
   - `build/app/intermediates/assets/release/mergeReleaseAssets/flutter_assets/.env`
   - `build/app/intermediates/flutter/release/flutter_assets/.env`
   - `build/flutter_assets/.env`
3. `lib/main.dart` already handles missing `.env` gracefully with try/catch fallback to `--dart-define`

**Production Build Command:**
```bash
flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

**Note:** `build/` is already in `.gitignore`, so secrets were never committed to the repo. However, deploying `build/web` would have exposed them.

### 🟢 Low (3)

#### L-01: Client-Side Timestamps

**Files:** Multiple (various service files)
**Severity:** Low
**Category:** Data Integrity

`DateTime.now()` is used client-side for some timestamps. A malicious client could manipulate these values.

**Mitigation:** The RLS migration includes server-side `update_updated_at_column()` triggers using `NOW()`, which overrides client timestamps on the database side. No action needed, but worth noting for future features.

#### L-02: SharedPreferences for Non-Sensitive Data

**File:** `lib/services/theme_service.dart`
**Severity:** Low
**Category:** Data Storage

`SharedPreferences` is used for theme preferences. This is appropriate for non-sensitive data, but if auth tokens or session data are ever stored locally, migrate to `flutter_secure_storage`.

**Note:** `lib/services/session_service.dart` already correctly uses `FlutterSecureStorage` for staff session data — this is the right pattern.

#### L-03: Public `Order` Table INSERT

**File:** `lib/services/rls_migration.sql`
**Severity:** Low
**Category:** Access Control

The `Order` table allows `anon` INSERT for public checkout flow. This is intentional and safe because:
- The `create_order_with_items` RPC is `SECURITY DEFINER`
- RLS restricts `SELECT`/`UPDATE`/`DELETE` to authenticated users only

No action needed. Documented for audit trail.

---

## Verified Secure Areas

| Area | Status | Details |
|---|---|---|
| **Secrets in source code** | ✅ Clean | No hardcoded keys, passwords, or tokens in any `.dart` file |
| **Environment loading** | ✅ Proper | `String.fromEnvironment` + `.env` fallback in `supabase_service.dart` |
| **`.gitignore` coverage** | ✅ Proper | `.env*` ignored; only `.example` templates tracked |
| **RLS policies** | ✅ Strong | All tables protected. `Staff`/`SystemSetting`/`Expense`/`Inventory` restricted to `service_role` or authenticated staff |
| **Password hashing** | ✅ Proper | `DBCrypt` with `gensalt()`. No plaintext storage |
| **SQL injection** | ✅ Safe | Supabase client parameterizes all queries. No raw SQL concatenation |
| **XSS** | ✅ Clean | No `innerHtml`/`setHtml` usage. All text rendered via Flutter widgets |
| **Command injection** | ✅ Clean | No `eval`/`exec`/`runJavaScript` usage |
| **HTTPS enforcement** | ✅ Proper | All external calls use HTTPS. No insecure `http://` endpoints |
| **PII protection** | ✅ Controlled | Customer data gated by RLS. WhatsApp conversations restricted to authenticated staff |
| **Logging** | ✅ Clean | No `debugPrint` of passwords, tokens, or secrets |
| **Secure storage** | ✅ Proper | `FlutterSecureStorage` used for staff sessions (`session_service.dart`) |
| **URL launching** | ✅ Safe | `url_launcher` with `LaunchMode.externalApplication` (Google Maps, WhatsApp) |
| **Clipboard access** | ✅ Clean | No `Clipboard.setData`/`Clipboard.getData` calls |
| **WebView usage** | ✅ Clean | No WebView or iframe embedding |

---

## Files Reviewed (54 Dart files + configs)

**Source files:**
- `lib/main.dart`
- `lib/customer/catalog_page.dart`, `checkout_page.dart`, `product_detail_page.dart`
- `lib/owner/whatsapp_settings_page.dart`, `expense_reports_page.dart`, `payments_page.dart`, `sales_reports_page.dart`
- `lib/owner/menu_page.dart`, `menu_details_page.dart`, `orders_page.dart`, `order_details_page.dart`
- `lib/owner/owner_dashboard.dart`, `owner_settings.dart`, `add_staff_page.dart`
- `lib/owner/inventory_analytics_page.dart`
- `lib/owner/widgets/dashboard_content.dart`, `order_card.dart`, `owner_bottom_nav.dart`
- `lib/staff/auth/login_page.dart`
- `lib/staff/dashboard/dashboard_page.dart`
- `lib/staff/inventory/inventory_page.dart`
- `lib/staff/management/staff_add_page.dart`, `staff_management_page.dart`
- `lib/staff/operations/kitchen_page.dart`, `orders_page.dart`
- `lib/staff/profile/profile_page.dart`
- `lib/staff/shared/staff_roles.dart`
- `lib/services/supabase_service.dart`, `auth_service.dart`, `auth_provider.dart`
- `lib/services/session_service.dart`, `theme_service.dart`, `constants.dart`
- `lib/services/order_service.dart`, `menu_service.dart`, `inventory_service.dart`
- `lib/services/finance_service.dart`, `report_service.dart`, `staff_service.dart`
- `lib/services/whatsapp_service.dart`, `biometric_service.dart`
- `lib/services/cart_provider.dart`, `dashboard_provider.dart`
- `lib/services/platform_file_stub.dart`
- `lib/services/rls_migration.sql`, `db_migration.sql`
- `lib/models/order.dart`
- `lib/widgets/glass_bottom_nav.dart`, `glass_order_sheet.dart`, `landing_page.dart`
- `lib/widgets/modern_drawer.dart`, `owner_sidebar.dart`, `staff_sidebar.dart`
- `lib/widgets/skeleton.dart`, `secure_avatar.dart`

**Config files:**
- `.env.example`, `.env.client.example`, `.env.server.example`
- `.gitignore`, `.coderabbit.yaml`, `pubspec.yaml`, `analysis_options.yaml`
