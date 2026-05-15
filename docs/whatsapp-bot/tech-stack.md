# WhatsApp Bot Tech Stack (Detailed)

The Sonna's Patisserie WhatsApp bot is built with a modern, serverless-first architecture optimized for speed and reliability.

## Core Technologies
- **Framework**: [Next.js 15.5+](https://nextjs.org/) (App Router). Leverages Route Handlers for high-concurrency webhooks.
- **Runtime**: Node.js 20+ (Vercel Serverless Functions).
- **Language**: TypeScript (Strict mode). All modules use typed interfaces defined in `types.ts`.
- **Messaging Gateway**: [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) (v18.0).
- **Styling**: Tailwind CSS for the Admin Dashboard and image rendering templates.

## Infrastructure & Configuration
- **Deployment**: Vercel (Auto-scaled serverless environment).
- **Cron Jobs**: Vercel Cron for daily session cleanup (`/api/cron/cleanup`), secured via `CRON_SECRET`.
- **Environment Variables**:
    - `WHATSAPP_TOKEN`: Permanent system user access token.
    - `WHATSAPP_PHONE_ID`: Unique ID for the business phone number.
    - `WHATSAPP_VERIFY_TOKEN`: Shared secret for webhook handshake.
    - `WHATSAPP_APP_SECRET`: App secret for HMAC signature verification.
    - `DATABASE_URL`: PostgreSQL connection string (Transaction-mode pooling).
    - `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET`: Payment gateway credentials.
    - `RAZORPAY_WEBHOOK_SECRET`: For verifying Razorpay payment callbacks.
    - `SUPABASE_SERVICE_ROLE_KEY`: Admin key for media uploads.
    - `CRON_SECRET`: Bearer token for cron endpoint authorization.

## Data & Persistence
- **Database**: [PostgreSQL](https://www.postgresql.org/) (Supabase).
- **ORM**: [Prisma](https://www.prisma.io/). Client is generated to a custom location (`./generated/prisma`) to avoid Vercel build-time artifacts issues.
- **Key Models**:
    - `WhatsAppConversation`: Per-user session with state, selections, and delivery preferences.
    - `WhatsAppCartItem`: Individual items in a user's cart, linked by phone number.
    - `WhatsAppSetting`: Runtime configuration overrides (Greetings, Delivery Slots, Maintenance Mode, Session Timeout).
    - `Cake` / `CakeOption` / `Category`: Product catalogue.
    - `Order` / `OrderItem`: Order records with payment tracking.
- **Media Storage**: [Supabase Storage](https://supabase.com/storage). 
    - Bucket: `cakes`
    - Product images: `cakes/{id}.png` (stable, ID-based filenames)
    - Custom order references: `cakes/custom-requests/{mediaId}_{timestamp}.jpg`
- **Caching**: 
    - `convoCache`: In-memory `Map<string, WhatsAppConversation>` for zero-latency session reads.
    - `cakeCache` / `categoryCache`: 1-minute TTL cache (configured in `constants.ts`) for the full menu to reduce DB pressure.
    - `processedMessages`: LRU-evicted `Set` (2000 entries) for webhook deduplication.

## Intelligence & Utilities
- **Fuzzy Search**: [Natural](https://www.npmjs.com/package/natural). Implements `JaroWinklerDistance` (threshold: 0.8) to handle user typos when typing cake names directly.
- **Reverse Geocoding**: [Nominatim](https://nominatim.openstreetmap.org/) (OpenStreetMap API) to convert GPS coordinates to human-readable addresses.
- **Price Formatting**: Custom `Intl.NumberFormat` wrapper in `src/lib/format.ts` (INR - ₹, paise-to-rupees conversion).
- **Input Validation**: Centralized `validateAndSanitize()` function for addresses, notes, and quantities.
- **Rate Limiting**: Custom two-tier limiter (1.5s cooldown + 15 msgs/min window) in `rate-limit.ts`.
- **DB Timeout**: All database queries wrapped in `withTimeout()` (15s) to prevent serverless function hangs.

## Integration Layer
- **Razorpay**: Payment link generation via Node SDK. Links delivered as `cta_url` interactive buttons. Webhook at `/api/webhooks/razorpay` handles `payment_link.paid` events with HMAC verification.
- **Vercel Cron**: `/api/cron/cleanup` runs daily to reset stalled sessions (24h) and delete abandoned conversations (7d).
- **Meta Cloud API**: All outbound messages go through `src/server/whatsapp.ts` with 10-second timeouts and structured error logging.

## File Structure

```
src/server/whatsapp/
├── whatsapp.ts                          # Meta API service layer (send text/image/list/buttons/CTA/doc)
├── media.ts                             # WhatsApp → Supabase media pipeline
├── cleanup.ts                           # Cron: stale session cleanup
├── conversation-handler.ts              # Barrel re-export
└── conversation-handler/
    ├── index.ts                         # Entry point: dedup, locking, rate-limit, maintenance check
    ├── state-machine.ts                 # Core FSM: global interceptors + state routing
    ├── menu.ts                          # Menu browsing, pagination, cake selection, size/qty handling
    ├── cart.ts                          # Cart CRUD, checkout flow, order summary
    ├── delivery.ts                      # Address input, geocoding, delivery slot generation
    ├── orders.ts                        # Order creation, payment links, order status display
    ├── custom-orders.ts                 # Custom cake text/image flow
    ├── session.ts                       # Session CRUD, WhatsAppSetting helper, timeout config
    ├── cache.ts                         # In-memory caches, dedup sets, concurrency locks
    ├── rate-limit.ts                    # Two-tier anti-flood system
    ├── constants.ts                     # CACHE_TTL, DB_TIMEOUT, rate limit thresholds, RESET_STATE
    ├── helpers.ts                       # formatItemTotal(), withTimeout()
    ├── validation.ts                    # Input sanitization bridge
    ├── types.ts                         # TypeScript interfaces (Cake, CartItem, IncomingMessage, etc.)
    ├── prisma.ts                        # Prisma client singleton
    └── messages.ts                      # Reserved: common message templates (placeholder)
```
