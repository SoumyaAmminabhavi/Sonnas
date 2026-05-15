# WhatsApp Bot Tech Stack (Detailed)

The Sonna's Patisserie WhatsApp bot is built with a modern, serverless-first architecture optimized for speed and reliability.

## Core Technologies
- **Framework**: [Next.js 15.5+](https://nextjs.org/) (App Router). Leverages Route Handlers for high-concurrency webhooks.
- **Runtime**: Node.js 20+ (Vercel Serverless Functions).
- **Messaging Gateway**: [WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api) (v21.0).
- **Styling**: Tailwind CSS for the Admin Dashboard and image rendering templates.

## Infrastructure & Configuration
- **Deployment**: Vercel (Auto-scaled serverless environment).
- **Environment Variables**:
    - `WHATSAPP_TOKEN`: Permanent system user access token.
    - `WHATSAPP_PHONE_ID`: Unique ID for the business phone number.
    - `WHATSAPP_VERIFY_TOKEN`: Shared secret for webhook handshake.
    - `DATABASE_URL`: PostgreSQL connection string (Transaction-mode pooling).

## Data & Persistence
- **Database**: [PostgreSQL](https://www.postgresql.org/) (Supabase).
- **ORM**: [Prisma](https://www.prisma.io/). Client is generated to a custom location (`./generated/prisma`) to avoid Vercel build-time artifacts issues.
- **Media Storage**: [Supabase Storage](https://supabase.com/storage). 
    - Bucket: `cakes`
    - Logic: Stable filenames using Database IDs (`{id}.png`) to prevent URL staleness.
- **Caching**: 
    - `convoCache`: In-memory session tracking.
    - `cakeCache`: 30-minute TTL cache for the full menu to reduce DB pressure.

## Intelligence & Utilities
- **Fuzzy Search**: [Natural](https://www.npmjs.com/package/natural). Implements `JaroWinklerDistance` to handle user typos when typing cake names directly.
- **Price Formatting**: Custom `Intl.NumberFormat` wrapper in `src/lib/format.ts` (INR - ₹).
- **Rate Limiting**: Custom window-based limiter (15 msgs / min) implemented in `src/server/whatsapp/conversation-handler/rate-limit.ts`.

## Integration Layer
- **Razorpay**: Used for `cta_url` payment buttons. Links are generated via the Razorpay Node SDK.
- **Vercel Cron**: `cron/status-update` runs every morning to notify the admin of pending orders.
