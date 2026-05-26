# Sonna's Patisserie & Cafe 🍰✨

Welcome to the unified workspace repository for **Sonna's Patisserie & Cafe** — a luxury artisan bakery. This repository co-locates two main components in a streamlined monorepo setup, sharing a unified database schema:

1.  **Web Admin Portal & WhatsApp Order Bot Backend** (Next.js · Tailwind v4 · Prisma ^6.6.0 · tRPC · Node.js)
2.  **Mobile & Desktop Application** (Flutter · Riverpod · Material 3 · Supabase SDK)

---

## 📂 Repository Structure

Both projects coexist at the root of this repository, organized as follows:

```text
├── android/, ios/, macos/, windows/, linux/, web/  # Flutter platform-specific native directories
├── lib/                                           # Flutter application codebase (Dart)
├── lib/main.dart                                  # Flutter app entry point
├── lib/models/                                    # Flutter shared data models
├── lib/services/                                  # Flutter services (Supabase service, local auth, etc.)
└── lib/customer/, owner/, staff/, widgets/        # Flutter portal screens and modular UI
│
├── prisma/                                        # Next.js / Server Prisma directory
│   ├── schema.prisma                              # Next.js Prisma Database Schema (Source of truth)
│   └── migrations/, seed.ts                       # Next.js migrations and seed script
│
├── public/                                        # Next.js public assets (Cakes, static media)
├── src/                                           # Next.js web application codebase (TypeScript/React)
│   ├── app/                                       # Next.js Admin and WhatsApp Router Pages
│   ├── components/                                # Next.js React UI Components (Tailwind v4)
│   ├── server/                                    # Next.js backend & WhatsApp Bot state machine handlers
│   └── styles/                                    # Global Tailwind stylesheet
│
├── .env.example                                   # Combined environment template for both platforms
├── package.json                                   # Root configuration, Next.js build scripts, and DB utilities
└── pubspec.yaml                                   # Flutter project configuration & dependency list
```

---

## 🤖 Sub-Project 1: Web Admin Portal & WhatsApp Order Bot (Next.js)

The root workspace operates a robust **Next.js 15 Web Application** designed for the admin dashboard and back-end automation. It houses the **WhatsApp Automated Ordering Bot** that processes conversation-based orders in real-time, compiles customer carts, takes delivery dates, and dispatches Razorpay payment links dynamically.

### ✨ Next.js Feature Highlights
*   **WhatsApp Dynamic Template Engine:** Manage localized interactive greeting templates, lists, and button menus in Supabase dynamically.
*   **Administrative Dashboard:** Manage menu items, view real-time WhatsApp conversations, customize bakery slots, and monitor orders.
*   **Integrated Payment Pipeline:** Real-time Razorpay webhooks dynamically update Supabase transaction records and trigger automated WhatsApp order confirmations upon payment completion.

### 🛠️ Web Tech Stack
*   **Framework:** Next.js 15 (App Router, React 19)
*   **Styling:** Tailwind CSS v4
*   **Database:** Prisma Client `^6.6.0` (with Supabase PostgreSQL)
*   **API & State:** tRPC (fully type-safe client-to-server RPCs)
*   **Authentication:** NextAuth.js v5 (Beta)

### 🚀 Getting Started (Web & Server)

1.  **Install Node Dependencies:**
    ```bash
    npm install
    ```
2.  **Configure Environment:**
    Copy `.env.example` to `.env` and fill in your Supabase connection strings, WhatsApp tokens, Razorpay keys, and administrative secrets:
    ```bash
    cp .env.example .env
    ```
3.  **Run Database Migrations & Seeds:**
    ```bash
    npm run db:generate   # Runs local prisma schema migrations
    npm run db:push       # Synchronizes the DB schema with Supabase
    ```
4.  **Launch the Development Server:**
    ```bash
    npm run dev
    ```
    The Next.js admin interface will be active at `http://localhost:3000`.

---

## 📱 Sub-Project 2: Mobile & Desktop Application (Flutter)

Inside `/lib` is a production-ready, full-stack **Flutter Application** optimized for tablet and mobile viewports. It features a multi-role layout (Owner · Staff · Customer) built with Material 3 design and interacts directly with the Supabase database.

### ✨ Flutter Feature Highlights

#### 👑 Owner Portal
*   **Live Dashboard:** KPIs including daily revenue, active orders, and active staff.
*   **Operational Reports:** Interactive spline charts using `fl_chart` for revenue analytics and expense tracking.
*   **Staff & Settings:** Onboard staff members, assign roles, reset PIN credentials, and enforce biometric locks.

#### 👷 Staff Portal
*   **Secure Access:** Lockout-protected PIN authentication + Biometric login via `local_auth`.
*   **Preparations Queue:** Real-time order fulfillment pipeline (Accept -> Prepare -> Complete).

#### 🛍️ Customer Catalog
*   **Interactive Menu:** Highly responsive cake catalog with ingredient listings, custom sizes, weight pickers, and checkout flows.

### 🎨 Design Tokens & UI Kit
*   **Primary Accent:** `#FF4D8D` (Signature Pink)
*   **Background Base:** `#FFF0F6` (Blush White)
*   **Typography:** *Noto Serif* (Headings) & *Plus Jakarta Sans* (UI Body)
*   **Themes:** Persisted Light, Dark, and Pink themes via `shared_preferences`.

### 🚀 Getting Started (Flutter Client)

1.  **Prerequisites:** Ensure Flutter SDK `>=3.19.0` and Dart SDK `>=3.11.0` are installed.
2.  **Fetch Flutter Packages:**
    ```bash
    flutter pub get
    ```
3.  **Environment Setup:** Create a `.env` file in the root matching the Supabase public API endpoints:
    ```dotenv
    SUPABASE_URL=https://your-project.supabase.co
    SUPABASE_ANON_KEY=your-anon-key
    ```
4.  **Run the Client:**
    ```bash
    # Run on default connected emulator or device
    flutter run
    
    # Run in Chrome for Web testing
    flutter run -d chrome
    
    # Build a production-ready Android APK
    flutter build apk --release
    ```

---

## 🗄️ Database & Prisma Schema Co-Existence

This project utilizes Prisma to define its schemas. To prevent conflicts between the React backend and Flutter client:
*   **Web/Root Schema:** Defined in `prisma/schema.prisma`. It is the master schema used for database migrations and generates the root TypeScript client (`npm run db:*`).
*   **Flutter/Client Schema:** Located in `lib/services/schema.prisma`. It represents the direct Supabase access models used by the client services.
*   **Flutter Prisma CLI Utilities:** To help Flutter developers manage their client-specific schemas without clashing with the Web Portal, special commands are provided in `package.json`:
    ```bash
    npm run db:flutter:generate  # Generates Prisma models under lib/generated/
    npm run db:flutter:push      # Pushes Flutter schema changes to target database
    npm run db:flutter:migrate   # Applies and tests schema migrations
    npm run db:flutter:studio    # Starts Prisma Studio pointing to lib/services/schema.prisma
    ```

---

## 🔐 Security & Operations

*   **Row-Level Security (RLS):** Enabled on all Supabase tables. The client performs operations matching security policies set in migrations.
*   **Biometric Integrity:** Mobile biometric login strictly bypasses OS keyguard fallbacks to prevent security bypasses on shared staff devices.
*   **Production Credentials:** Server keys like `WHATSAPP_TOKEN` and `RAZORPAY_KEY_SECRET` are handled purely on the Next.js server/vercel runtime and are never bundled inside client mobile builds.

---

*Made with ❤️ for Sonna's Patisserie & Cafe*

