# Sonna Patisserie & Cafe — Copilot Instructions

This is a **Flutter** application for Sonna's Patisserie & Cafe, a bakery management platform with customer-facing and staff/owner interfaces.

---

## Project Structure

```
lib/
  customer/       # Customer-facing pages (catalog, checkout, product detail)
  owner/          # Owner dashboard (menu, orders, sales reports, inventory)
  staff/          # Staff pages (dashboard, operations, profile)
  services/       # Supabase client, auth, order/menu/report services, constants
  models/         # Dart data models (order.dart, etc.)
  widgets/        # Shared widgets (bottom nav, drawer, order sheet, sidebar)
  main.dart       # App entry point, theme setup, navigation
test/             # Widget and unit tests
android/          # Android-specific build config
ios/              # iOS-specific build config
web/              # Web-specific assets and index.html
```

---

## Requirements

| Tool | Minimum Version |
|------|----------------|
| Flutter SDK | 3.19.x (stable channel) |
| Dart SDK | 3.3.x (bundled with Flutter) |
| Android Studio / Xcode | For mobile builds |
| Node.js | For Vercel CLI (web deploy only) |

---

## Environment Setup

1. Copy `.env.server.example` to `.env` and fill in your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app (Chrome for web, or connect a device):
   ```bash
   flutter run -d chrome
   flutter run -d <device-id>
   ```

---

## Build & Test Commands

```bash
# Development
flutter run -d chrome
flutter run -d <android|ios-device>

# Production builds
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
flutter build apk --release
flutter build ios --release

# Analysis & testing
flutter analyze
flutter test
```

---

## Coding Conventions

- **State management**: Riverpod (`flutter_riverpod`). Providers live in `lib/services/`.
- **Styling**: Material 3 with a custom `ColorScheme`; Google Fonts (`plusJakartaSans`, `notoSerif`).
- **Currency**: Always use `PriceConstants.currencySymbol` and `PriceConstants.normalizePrice()` — never hardcode `₹` or `Rs.`.
- **Images**: Use `SupabaseService.getPublicUrl()` for storage paths. Check `startsWith('http')` / `startsWith('data:')` before passing to the helper.
- **Async context safety**: After every `await`, check `context.mounted` before using `BuildContext`.
- **Error messages**: Log full exceptions with stack traces via `debugPrint`; show only generic strings to end users.
- **Supabase**: All DB calls go through the service layer. RLS policies are in `lib/services/rls_migration.sql`.

---

## Key Entry Points

| File | Purpose |
|------|---------|
| `lib/main.dart` | App bootstrap, theme, top-level navigation |
| `lib/services/supabase_service.dart` | Supabase client + storage helpers |
| `lib/services/constants.dart` | Shared constants (price, auth, order, UI) |
| `lib/models/order.dart` | `SonnaOrder`, `OrderItem`, `OrderStatus` |
| `lib/owner/menu_page.dart` | Owner menu management (CRUD) |
| `lib/staff/dashboard/dashboard_page.dart` | Staff dashboard |
