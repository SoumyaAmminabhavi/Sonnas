
# Sonna's Patisserie & Cafe 🍰✨

A production-ready, full-stack Flutter application for a luxury artisan bakery. Features a multi-role architecture (Owner · Staff · Customer), real-time Supabase backend, biometric authentication, and cross-platform support (Android, Web).

---

## ✨ Feature Overview

### 👑 Owner Portal

| Feature                       | Description                                                        |
| ----------------------------- | ------------------------------------------------------------------ |
| **Dashboard**           | Live KPIs — daily revenue, pending orders, staff on shift         |
| **Order Management**    | Full lifecycle tracking with WhatsApp dispatch integration         |
| **Menu Management**     | Add / edit products with Supabase Storage image uploads            |
| **Sales Reports**       | `fl_chart` spline charts for weekly & monthly revenue trends     |
| **Expense Reports**     | Log and categorise operational expenses                            |
| **Inventory Analytics** | Stock-level monitoring and low-stock alerts                        |
| **Payments**            | Transaction history with PDF/CSV export via `printing` & `csv` |
| **Staff Control**       | Add / deactivate staff, assign roles, reset PINs                   |
| **Settings**            | Theme persistence (light/dark/pink), biometric lock toggle         |

### 👷 Staff Portal

| Feature              | Description                                                 |
| -------------------- | ----------------------------------------------------------- |
| **Auth**       | PIN + biometric (fingerprint/face) login via `local_auth` |
| **Dashboard**  | Today's queue, shift summary                                |
| **Operations** | Accept, prepare, and complete orders                        |
| **Inventory**  | Update stock counts                                         |
| **Profile**    | Change PIN, toggle biometrics, personal preferences         |

### 🛍️ Customer Catalog

| Feature                  | Description                                  |
| ------------------------ | -------------------------------------------- |
| **Catalog**        | Browsable menu with `cached_network_image` |
| **Product Detail** | Ingredient info, weight, pricing             |
| **Checkout**       | Cart → order submission flow                |

---

## 🎨 Design System

| Token        | Value                                                        |
| ------------ | ------------------------------------------------------------ |
| Primary      | `#FF4D8D` — Signature Pink                                |
| Background   | `#FFF0F6` — Blush White                                   |
| Gold Accent  | `#D9B87A` — Luxury Gold                                   |
| Heading Font | **Noto Serif**                                         |
| Body Font    | **Plus Jakarta Sans**                                  |
| UI Kit       | Material 3 + custom `ThemeData`                            |
| Theme Modes  | Light · Dark · Pink (persisted via `shared_preferences`) |

---

## 🛠️ Technical Stack

| Layer            | Technology                                               |
| ---------------- | -------------------------------------------------------- |
| Framework        | Flutter (Dart `^3.6.0`, Material 3)                    |
| State Management | `flutter_riverpod`                                     |
| Backend          | Supabase (Postgres + Auth + Storage + RLS)               |
| Schema Tooling   | Prisma (schema definition & migrations only — not used at runtime by Flutter) |
| Hosting (Web)    | Vercel                                                   |
| Auth             | PIN (bcrypt via `dbcrypt`) + `local_auth` biometrics |
| Charts           | `fl_chart`                                             |
| PDF / Export     | `pdf` + `printing` + `csv`                         |
| Networking       | `supabase_flutter`, `http`                           |
| Storage          | `flutter_secure_storage`, `shared_preferences`       |
| Images           | `image_picker`, `cached_network_image`               |
| Config           | `flutter_dotenv` (`.env` file)                       |

---

## 🗄️ Database Schema

The database schema is defined in `lib/services/schema.prisma` using Prisma syntax. This file serves as the **single source of truth** for the Supabase PostgreSQL schema. The Flutter app connects directly to Supabase via `supabase_flutter` — Prisma is **not** used at runtime by the app. It is used only for:
- Schema documentation and modeling
- Running migrations (`npm run db:migrate`)
- Generating a TypeScript client for any future Node.js/Next.js backend

To apply schema changes (requires privileged `DATABASE_URL` located in your server-only env template `.env.server.example`):

```bash
npm install          # install prisma + @prisma/client
npm run db:migrate   # or: npx prisma migrate dev
```

The `vercel.json` configures SPA routing for the Flutter web build only. There is no Node.js backend in this repository.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.6.0`
- Dart SDK `>=3.6.0`
- A [Supabase](https://supabase.com) project with the schema applied (see `lib/services/schema.prisma`)

### 1 — Clone & install dependencies

```bash
git clone <repo-url>
cd Sonna
flutter pub get
```

### 2 — Configure environment

Copy the template and fill in your credentials:

```bash
cp .env.example .env
```

```dotenv
# .env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

> **Never commit `.env`.** It is listed in `.gitignore`.

### 3 — Run

```bash
# Android
flutter run

# Web (Chrome)
flutter run -d chrome

# Release APK
flutter build apk --release
```

---

## 📂 Project Structure

```text
lib/
├── main.dart                 # App entry — theme, routing, Riverpod providers
├── models/                   # Shared data models
├── services/
│   ├── supabase_service.dart # Supabase client initialisation
│   ├── auth_service.dart     # PIN hashing, login, staff registration
│   ├── auth_provider.dart    # Riverpod auth state
│   ├── biometric_service.dart# local_auth wrapper (strict — no PIN fallback)
│   ├── session_service.dart  # Secure session persistence
│   ├── theme_service.dart    # Theme persistence (shared_preferences)
│   ├── order_service.dart    # Order CRUD + real-time subscriptions
│   ├── menu_service.dart     # Menu & product management
│   ├── staff_service.dart    # Staff CRUD
│   ├── inventory_service.dart# Stock management
│   ├── finance_service.dart  # Revenue & expense queries
│   ├── report_service.dart   # PDF/CSV report generation
│   ├── dashboard_provider.dart
│   ├── order_provider.dart
│   ├── cart_provider.dart
│   └── schema.prisma         # Supabase schema reference
├── owner/                    # Owner portal screens & widgets
├── staff/                    # Staff portal (auth, dashboard, operations, profile)
├── customer/                 # Customer catalog, product detail, checkout
└── widgets/                  # Shared UI components
```

---

## 🔐 Security Notes

- **Biometric authentication** is enforced strictly — PIN-based OS fallback is disabled.
- **Passwords / PINs** are stored as bcrypt hashes (`dbcrypt`); plaintext is never persisted.
- **Sensitive tokens** are stored in `flutter_secure_storage` (Android Keystore / iOS Keychain).
- **Row-Level Security (RLS)** is enabled on all Supabase tables.
- **`.env`** is used for local development only; never bundle secrets or private keys in app assets. Store server-only secrets in a secrets manager or CI/CD vault for production.

---

## 📜 License

MIT — see [LICENSE](LICENSE).

---

*Made with ❤️ for Sonna's Patisserie & Cafe*
