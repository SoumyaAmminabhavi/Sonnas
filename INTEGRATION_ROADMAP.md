# Sonna Integration Roadmap

## Project Overview

| Module | Developer | Tech | Status |
|---|---|---|---|
| **Owner Dashboard** | You | Flutter/Dart | In repo (`lib/owner/`) |
| **Staff Portal** | You | Flutter/Dart | In repo (`lib/staff/`) |
| **Customer App** | Friend 1 | Flutter/Dart | External (needs merge) |
| **WhatsApp Automation** | Friend 2 | T3 Stack | External (needs merge) |

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Supabase (Shared)                   │
│  Tables: Products, Orders, Staff, Customers,         │
│          WhatsAppConversations, Inventory, Expenses   │
│  RLS Policies + Webhooks + Edge Functions            │
└────────────┬─────────────────────────────┬──────────┘
             │                             │
    ┌────────┴─────────┐          ┌────────┴──────────┐
    │   Flutter App    │          │   T3 Stack API    │
    │  (Single Binary) │          │  (Vercel Deploy)  │
    │                  │          │                   │
    ├──────────────────┤          ├───────────────────┤
    │ lib/owner/       │          │ /src/api/         │
    │ lib/staff/       │◄────────►│ /src/webhooks/    │
    │ lib/customer/    │          │ /src/services/    │
    │ lib/services/    │          │                   │
    │ lib/main.dart    │          │ WhatsApp Meta API │
    └──────────────────┘          └───────────────────┘
```

---

## Phase 1: Flutter Codebase Merge

### 1.1 Folder Structure

```
lib/
├── main.dart                    # Single entry point (merge both)
├── customer/                    # Friend 1's work
│   ├── catalog_page.dart
│   ├── checkout_page.dart
│   ├── product_detail_page.dart
│   └── ...
├── owner/                       # Your work
│   ├── owner_dashboard.dart
│   ├── menu_page.dart
│   ├── orders_page.dart
│   ├── payments_page.dart
│   ├── expense_reports_page.dart
│   ├── whatsapp_settings_page.dart
│   └── widgets/
├── staff/                       # Your work
│   ├── auth/login_page.dart
│   ├── dashboard/dashboard_page.dart
│   ├── inventory/inventory_page.dart
│   ├── management/
│   ├── operations/
│   ├── profile/
│   └── shared/
├── services/                    # Shared
│   ├── supabase_service.dart
│   ├── auth_service.dart
│   ├── order_service.dart
│   ├── menu_service.dart
│   ├── whatsapp_service.dart
│   ├── constants.dart
│   └── ...
├── models/
│   └── order.dart
└── widgets/                     # Shared UI
    ├── glass_bottom_nav.dart
    ├── modern_drawer.dart
    └── ...
```

### 1.2 Merge Steps

| Step | Action | Owner |
|---|---|---|
| 1 | Get friend's `customer/` folder + `main.dart` | You |
| 2 | Copy `customer/` into `lib/customer/` | You |
| 3 | Merge `main.dart` — keep single entry point with role-based routing | You |
| 4 | Resolve import conflicts | Both |
| 5 | Verify `flutter pub get` + `flutter build web` | You |
| 6 | Test all three flows (owner/staff/customer) | All |

### 1.3 `main.dart` Merge Strategy

```dart
// Single main.dart with role-based navigation
void main() async {
  // Shared initialization (Supabase, theme, dotenv)
  await SupabaseService.initialize();
  runApp(const SonnaApp());
}

class SonnaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RoleRouter(), // Decides: Owner / Staff / Customer
    );
  }
}
```

---

## Phase 2: WhatsApp T3 Stack Integration

### 2.1 Folder Structure

```
sonna-whatsapp/                    # Separate T3 Stack app
├── src/
│   ├── api/                       # API routes
│   │   ├── webhook.ts             # Supabase webhook receiver
│   │   ├── send-message.ts        # Outbound WhatsApp
│   │   └── template.ts            # Template management
│   ├── services/
│   │   ├── supabase.ts            # Supabase client
│   │   ├── whatsapp.ts            # Meta WhatsApp API
│   │   └── template-engine.ts     # Message templating
│   └── types/
├── prisma/                        # (if using separate DB)
├── env.example
├── package.json
└── vercel.json
```

### 2.2 Integration Points

| Trigger | Source | T3 Stack Action |
|---|---|---|
| New order placed | Supabase `orders` table INSERT | Send order confirmation via WhatsApp |
| Order status changed | Supabase `orders` table UPDATE | Send status update (preparing, delivered) |
| Customer replies | WhatsApp inbound webhook | Store in `WhatsAppConversation` table |
| Template update | Flutter owner dashboard | Sync template to Meta via T3 API |

### 2.3 Supabase Webhook Configuration

```sql
-- Create webhook for new orders
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT net.create_subscription(
  'order_created',
  'https://sonna-whatsapp.vercel.app/api/webhook/order-created',
  'POST',
  '{"Content-Type": "application/json"}',
  $$
  SELECT json_build_object(
    'event', 'order.created',
    'order_id', NEW.id,
    'customer_phone', NEW.customer_phone,
    'total', NEW.total_amount
  )
  FROM NEW
  $$
);
```

### 2.4 Merge Steps

| Step | Action | Owner |
|---|---|---|
| 1 | Get T3 Stack folder from Friend 2 | You |
| 2 | Place in repo as `services/whatsapp-api/` or separate repo | You |
| 3 | Connect to shared Supabase project | Friend 2 |
| 4 | Configure Supabase webhooks → T3 Stack URL | You |
| 5 | Deploy T3 Stack to separate Vercel project | Friend 2 |
| 6 | Test end-to-end: order → webhook → WhatsApp message | All |

---

## Phase 3: Shared Services & Contracts

### 3.1 Database Schema (Single Source of Truth)

All three modules share the same Supabase project. Schema changes must be coordinated.

| Table | Used By | Notes |
|---|---|---|
| `Products` | Owner, Customer | Owner manages, Customer views |
| `Orders` | All three | Customer creates, Owner manages, WhatsApp notifies |
| `Staff` | Owner, Staff | Owner creates, Staff authenticates |
| `WhatsAppConversation` | Owner, T3 Stack | T3 writes, Owner reads |
| `Inventory` | Owner, Staff | Shared management |
| `Expense` | Owner | Owner only |

### 3.2 API Contracts

```typescript
// T3 Stack → Supabase (order webhook payload)
interface OrderWebhook {
  event: 'order.created' | 'order.updated';
  order_id: string;
  customer_phone: string;
  customer_name: string;
  items: Array<{ name: string; qty: number; price: number }>;
  total: number;
  status: 'pending' | 'confirmed' | 'preparing' | 'delivered';
}

// Flutter → T3 Stack (template sync)
interface TemplateSync {
  template_id: string;
  version: number;
  body: string;
  header?: string;
  footer?: string;
  buttons?: Array<{ type: string; text: string; url?: string }>;
}
```

---

## Phase 4: CI/CD & Deployment

### 4.1 Deployment Targets

| Module | Deploy To | Trigger |
|---|---|---|
| Flutter Web (Owner + Staff + Customer) | Vercel (`sonna.vercel.app`) | Push to `main` |
| T3 Stack (WhatsApp API) | Vercel (`sonna-whatsapp.vercel.app`) | Push to `main` |
| Supabase | Supabase Cloud | Manual migrations |

### 4.2 GitHub Workflow

```yaml
# .github/workflows/deploy.yml
on:
  push:
    branches: [main]

jobs:
  deploy-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: subosito/flutter-action@v2
      - run: flutter build web --dart-define=...
      - run: vercel deploy build/web --prod

  deploy-whatsapp-api:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v4
      - run: cd services/whatsapp-api && npm ci && npx vercel --prod
```

---

## Phase 5: Testing & QA

| Test | Scope | Owner |
|---|---|---|
| Customer places order | Customer → Supabase | Friend 1 |
| Owner receives order | Supabase → Owner dashboard | You |
| Staff updates order | Staff dashboard | You |
| WhatsApp notification | Supabase → T3 → WhatsApp | Friend 2 |
| Template editing | Owner → T3 → Meta API | You + Friend 2 |
| End-to-end flow | Full cycle | All |

---

## Git Workflow

```
main
├── feature/owner-staff       (You)
├── feature/customer          (Friend 1)
└── feature/whatsapp-api      (Friend 2)

All PRs → new-setup → review → merge → main → deploy
```

### Branch Rules
- Each dev works on their own branch
- PR to `new-setup` for integration testing
- Only merge to `main` after all three modules pass QA
- No force pushes to shared branches

---

## Timeline (Estimated)

| Phase | Duration | Dependencies |
|---|---|---|
| Phase 1: Flutter Merge | 1-2 days | Get customer code from Friend 1 |
| Phase 2: T3 Stack Setup | 2-3 days | Get T3 code from Friend 2 |
| Phase 3: Shared Contracts | 1 day | All three agree on schema |
| Phase 4: CI/CD | 1 day | Vercel projects configured |
| Phase 5: Testing | 2-3 days | All modules integrated |

**Total: ~7-10 days**

---

## Action Items

### You (Owner/Staff)
- [ ] Get `customer/` folder + `main.dart` from Friend 1
- [ ] Get T3 Stack folder from Friend 2
- [ ] Merge Flutter codebases
- [ ] Set up Supabase webhooks
- [ ] Configure Vercel secrets (ORG_ID, PROJECT_ID)

### Friend 1 (Customer)
- [ ] Share `customer/` folder + `main.dart`
- [ ] Test customer flow after merge
- [ ] Verify RLS policies for anon access

### Friend 2 (WhatsApp/T3)
- [ ] Share T3 Stack codebase
- [ ] Connect to shared Supabase project
- [ ] Deploy to separate Vercel project
- [ ] Test webhook → WhatsApp flow
