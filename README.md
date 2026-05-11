# Sonna's Patisserie & Cafe 🍰✨

A premium, luxury Flutter application designed for high-end bakeries. This app features a charming "Sweet Pink & Gold" aesthetic, tailored for a sophisticated and girlish brand identity.

## ✨ Features

### 👑 Owner Dashboard

- **Sales Performance**: Integrated `fl_chart` for visualizing weekly revenue trends with smooth spline line charts.
- **Recent Orders**: Real-time overview of the latest activity in the boutique.
- **Order Management**: Comprehensive status tracking (In Preparation, Ready for Pickup, etc.) with detailed receipt views.
- **Revenue Overview**: Clean, compact interface for tracking pending payments and transaction history.
- **Menu Management**: Easy-to-use portal for adding new pâtisserie items, weight details, and portion sizes.
- **Staff Control**: Manage your team roles and permissions with a modern UI.

### 🎨 Design System

- **Theme**: "Sweet Pink" brand identity using `#FF4D8D` (Primary) and `#FFF0F6` (Background).
- **Luxury Accents**: Signature gold color (`#D9B87A`) for brand headlines.
- **Typography**: Professional pairing of **Noto Serif** for elegant headings and **Plus Jakarta Sans** for modern readability.
- **Visual Separation**: Refined layout with high-contrast white navigation sidebars and soft pink workspace areas.

## 🛠️ Technical Stack

- **Framework**: Flutter (Material 3)
- **Backend**:
  - **Supabase**: Direct database integration and real-time updates (Skeleton ready).
  - **Vercel**: API communication layer.
- **Charts**: `fl_chart`
- **Fonts**: `google_fonts`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.10.1` or higher
- Dart SDK `^3.10.1`

### Installation

1. Clone the repository.
2. Run `flutter pub get` to install dependencies.
3. Configure backend credentials in `lib/services/supabase_service.dart`:
   ```dart
   static const String _supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String _supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
4. Run the app:
   ```bash
   flutter run -d chrome  # For Web/Desktop preview
   ```

## 📂 Project Structure

- `lib/owner/`: Core administrative features (Dashboard, Orders, Payments, Settings).
- `lib/services/`: Backend integration services (Supabase/Vercel).
- `lib/main.dart`: Global theme and application entry point.

---

*Created with ❤️ for Sonna's Patisserie & Cafe*
===============================================
