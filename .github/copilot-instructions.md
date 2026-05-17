# Sonna Patisserie — Copilot Instructions

This is a Flutter app for a luxury artisan bakery (Sonna's Patisserie & Cafe).

## Project Structure

```text
lib/
├── main.dart                 # App entry — theme, routing, Riverpod providers
├── models/                   # Shared data models (Order, etc.)
├── services/                 # Supabase, auth, menu, order, inventory services
├── owner/                    # Owner portal screens & widgets
├── staff/                    # Staff portal (auth, dashboard, operations, profile)
├── customer/                 # Customer catalog, product detail, checkout
└── widgets/                  # Shared UI components
```

## Local Dev Commands

```bash
flutter pub get       # Install dependencies
flutter run           # Run on connected device
flutter run -d chrome # Run on web
flutter test          # Run tests
flutter analyze       # Static analysis
```

## Key Notes

- Backend: Supabase (PostgreSQL + Auth + Storage + RLS)
- State management: flutter_riverpod
- Schema: `lib/services/schema.prisma` (Prisma for schema definition only — not used at runtime by Flutter)
- Environment: Copy `.env.example` to `.env` and fill in Supabase credentials
