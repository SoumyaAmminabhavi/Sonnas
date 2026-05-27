# WhatsApp Bot Architecture & Message Lifecycle

This document describes the complete system design and the lifecycle of a message within the Sonna's Patisserie WhatsApp Bot ecosystem.

---

## 1. System Overview

```
User (WhatsApp) ←→ Meta Cloud API ←→ Vercel Webhook ←→ Conversation Handler ←→ PostgreSQL (Supabase)
                                                                                ↓
                                                                       Supabase Storage (Images)
                                                                       Razorpay (Payments)
                                                                       Nominatim (Geocoding)
```

---

## 2. Webhook Entry (The Injection Point)

All incoming messages arrive via a **POST** request from Meta's servers to our webhook endpoint:
`src/app/api/webhooks/whatsapp/route.ts`

### Webhook Security & Handshake
- **Verification (GET)**: Handles the one-time `hub.verify_token` handshake with Meta during setup. Returns `hub.challenge` on match.
- **Signature Validation (POST)**: In production, validates the `X-Hub-Signature-256` header using `WHATSAPP_APP_SECRET` via `crypto.timingSafeEqual` to ensure the request is authentically from Meta.

### Message Parsing
The webhook normalizes 4 message types into a unified `IncomingMessage` interface:

| Message Type | Fields Extracted | Use Case |
|---|---|---|
| `text` | `text.body` | Free-form input (names, addresses, cake queries) |
| `interactive` | `button_reply.id` / `list_reply.id` | Button clicks, list selections |
| `location` | `latitude`, `longitude`, `name`, `address` | GPS delivery address |
| `image` | `image.id`, `image.caption`, `mime_type` | Custom cake reference photos |

### Immediate UX
- **Mark as Read**: Every incoming message is immediately marked as "read" (blue double-tick ✓✓) via `markAsRead()` for professional UX, before any processing begins.

---

## 3. Concurrency Control (The Global Lock)

In `src/server/whatsapp/conversation-handler/index.ts`:

- **`processingLocks` Map**: A `Map<string, Promise<void>>` keyed by phone number.
- **Mechanism**: Every incoming message waits for the previous message from the same user to finish processing (`existingLock.then(...)`). This prevents race conditions where a user clicks two buttons rapidly, potentially creating duplicate orders or inconsistent state.
- **Cleanup**: Locks are automatically removed from the map after the chain completes.

### Anti-Flood Protection (`rate-limit.ts`)
A two-tier system prevents abuse:
1. **Sliding Cooldown** (150ms): If a user sends a message within 150 milliseconds of their last activity, it is silently ignored. Prevents button-mashing floods.
2. **Rolling Window** (15 msgs/min): If a user exceeds 15 messages in a 60-second window, they receive a polite "slow down" message and further messages are blocked until the window resets.

Both counters are tracked in-memory via `convoCache` (not in the database) for zero-latency enforcement.

---

## 4. Session & State Management (`session.ts`)

The bot retrieves the current `WhatsAppConversation` record using `getConversation()`.

### Caching Strategy
- **L1 Cache**: `convoCache` (in-memory `Map`) — checked first, updated on every state change.
- **L2 Storage**: Prisma/PostgreSQL — queried on cache miss, with a `DB_TIMEOUT` of 15 seconds to prevent serverless hangs.
- **Fallback**: If both fail, a safe default `{ state: IDLE }` is used to ensure the bot never crashes.

### Integrity Checks
- **Zombie State Protection**: If a user is in a state like `SELECTING_SIZE` or `SELECTING_QUANTITY` but the session has lost the `selectedCakeId` (e.g., manual DB edit), the bot automatically resets to `IDLE`.
- **Stale Cart Cleanup**: Cart items older than 24 hours are automatically pruned when a session is loaded.
- **Session Timeout**: If `lastActivityAt` is older than the configured timeout (default 60 mins, configurable via `SESSION_TIMEOUT_MINS` in `WhatsAppSetting`), the cart is cleared and the user is welcomed fresh.

---

## 5. Dynamic Configuration Management (`WhatsAppSetting`)

The `getWhatsAppSetting(key, defaultValue)` helper in `session.ts` provides a unified interface for database-driven configuration. This allows admins to change bot behavior in real-time without code deployments.

| Setting Key | Type | Default | Description |
|---|---|---|---|
| `SESSION_TIMEOUT_MINS` | Number | `60` | Minutes before an idle session resets |
| `GREETINGS` | Comma-separated string | `hi,hello,hey,...` | Words that trigger the welcome message |
| `DELIVERY_SLOTS` | JSON array | `[{id,title,startHour}]` | Available delivery time windows |
| `MAINTENANCE_MODE` | Boolean string | `false` | Pauses the bot for all users |
| `MAINTENANCE_MESSAGE` | Text | _(See code)_ | Custom message shown during maintenance |

### Fallback Chain
```
Database Setting → Code Constant → Hardcoded Default
```
If the DB query fails (e.g., cold start, connection pool exhausted), the bot gracefully falls back to compiled constants.

---

## 6. State Machine Logic (`state-machine.ts`)

Core business logic resides in `_internalHandleMessage`. It maps the current state + user input to a transition.

### Global Interceptors (Run Before State Logic)
These are checked regardless of the current conversation state:

| Trigger | Action |
|---|---|
| Greeting words (`hi`, `hello`, etc.) | Show welcome (if `IDLE`) or re-prompt current state |
| `restart`, `cancel`, `reset`, `start over` | Clear cart, reset to `IDLE`, show welcome |
| `help` | Show welcome message |
| `menu`, `cakes`, or `btn_menu` | Enter `BROWSING_MENU` state |
| `btn_custom` | Enter `CUSTOM_ORDER_DETAILS` |
| `status`, `my order`, `order status`, `btn_status` | Show last 3 orders |
| `btn_add_to_cart`, `btn_checkout`, `btn_checkout_now` | Trigger cart add / checkout flow |
| `btn_clear_cart` | Clear cart, reset to `IDLE`, show menu |
| `btn_back` | Intelligent rollback to previous state |
| `btn_remove_last` | Remove last cart item, show updated cart |
| `btn_pickup` | Set address to "🏪 Store Pickup", enter `ADDING_NOTES` |
| `btn_delivery` | Enter `INPUTTING_ADDRESS`, prompt for address/GPS |
| `saved_addr_yes` | Reuse last non-cancelled order's address, enter `ADDING_NOTES` |
| `morecat_{offset}` / `prevcat_{offset}` | Paginate category list |
| `more_{catId}_{offset}` / `prev_{catId}_{offset}` | Paginate cake list within a category |
| `cat_{id}` | Select a category → show cakes |
| `cake_{id}` | Select a cake → show size options |
| `size_{idx}` | Select a size → auto-add to cart |
| `slot_{date}_{id}` | Select a delivery slot → show order summary |
| Direct order text (`I'd like to order: CakeName`) | Jump directly to `SELECTING_SIZE` |
| `design my own cake` (website link) | Jump to `CUSTOM_ORDER_IMAGE` |
| Image sent outside custom flow | Offer to start custom order |
| Location sent outside address input | Save for later, suggest Menu |

### NLP Fallback
If the user is `IDLE` and sends unrecognized text longer than 3 characters, the bot uses `natural.JaroWinklerDistance` (threshold: 0.8) to fuzzy-match against cake names. This handles typos like "choclate cake" → "Chocolate Cake".

### Back Button Logic
The `btn_back` handler implements intelligent state rollback:

| From State | Goes Back To |
|---|---|
| `SELECTING_SIZE` | `BROWSING_MENU` |
| `SELECTING_QUANTITY` | `SELECTING_SIZE` |
| `INPUTTING_ADDRESS` | Cart summary (with Place Order / Add More / Start Fresh) |
| `ADDING_NOTES` (pickup) | `INPUTTING_ADDRESS` (delivery/pickup choice) |
| `ADDING_NOTES` (delivery) | `INPUTTING_ADDRESS` |
| `ASKING_DELIVERY_DATE` | `ADDING_NOTES` |
| `CONFIRMING_ORDER` | `ASKING_DELIVERY_DATE` |
| Any other | `IDLE` (welcome) |

---

## 7. Menu & Browsing System (`menu.ts`)

### Data Fetching
- **`safeGetCakes()`**: Fetches all available cakes from DB with category relations and cake options. Results are cached for `CACHE_TTL` (1 minute). Unavailable cakes (`isAvailable: false`) are filtered out and results are sorted by `sortOrder`.
- **`safeGetCategories()`**: Fetches all categories sorted by `createdAt: asc` (oldest first).
- **Image Resolution**: Image paths are resolved using a three-tier check:
  1. Full HTTPS URL → use as-is
  2. Relative filename → prepend Supabase public URL prefix
  3. Empty/null → use placeholder image
- **Image Safety Guard**: Before sending to WhatsApp API, the `isPublicImageUrl()` check ensures only valid `https://` URLs (excluding `localhost`) are sent. Invalid images are skipped silently — the size selection buttons are still sent.

### Welcome Message Structure
The welcome `sendInteractiveList` message contains 2 sections:
1. **📋 Browse by Category**: First 6 categories (oldest first) — each row links to `cat_{id}`
2. **✨ Other Services**: Custom Creation (`btn_custom`) and Track My Order (`btn_status`)

After the interactive list, the **Menu PDF** (`menu_compressed.pdf`) is sent as a separate document message with a 1-second delay to avoid racing conditions with the list.

### Pagination (10-Item Limit)
WhatsApp Cloud API enforces a maximum of **10 rows** per interactive list. The bot implements strict pagination:

- **Page 1**: 9 items + "➡️ Next Page" button
- **Middle Pages**: "⬅️ Previous Page" + 8 items + "➡️ Next Page"
- **Last Page**: "⬅️ Previous Page" + up to 9 items

This logic is applied identically to both:
- **Cake lists** within a category (`more_{catId}_{offset}` / `prev_{catId}_{offset}`)
- **Category lists** in the main menu (`morecat_{offset}` / `prevcat_{offset}`)

### Small Catalogue Optimization
If the total number of cakes across all categories is ≤ 10, the bot skips category pagination entirely and renders a single interactive list grouped by category name.

### Cake Search (`findCake`)
Multi-strategy search with fallback chain:
1. Exact match by ID
2. Exact match by name (case-insensitive)
3. Partial string match (contains)
4. Fuzzy match via JaroWinkler (threshold > 0.8)
5. Direct DB lookup by CUID (if query length > 5)
6. Local product data fallback

### Size Selection
When a user selects a cake:
- **≤ 2 size options**: Rendered as interactive **buttons** (with a "📋 Back to Menu" button appended)
- **> 2 size options**: Rendered as an interactive **list** under the section "Available Sizes"

### Auto-Add to Cart (Size → Quantity → Cart)
When a size is selected, the bot:
1. Sets `selectedSize`, `selectedPrice`, `selectedQuantity: 1` on the session
2. Transitions to `SELECTING_QUANTITY`
3. Immediately calls `handleCartActions()` which auto-adds the item with quantity 1

The user sees the cart summary with buttons: "💳 Place My Order", "➕ Add More", and either "❌ Remove Last" (if > 1 item) or "🔄 Clear Cart" (if exactly 1 item).

---

## 8. Cart System (`cart.ts`)

- **`addToCart()`**: Checks for existing items with same cake+size. If found, increments quantity instead of creating a duplicate. All changes are persisted to `WhatsAppCartItem` table and synced to `convoCache`.
- **`removeLastItem()`**: Removes the most recently added item.
- **`clearCart()`**: Deletes all items for a phone number.
- **`getCartSummary()`**: Formats a readable cart with item names, sizes, quantities, and total.
- **`buildOrderSummary()`**: Extended summary including address, notes, delivery date/slot, and total. Used for the final confirmation screen.

### Cart Summary Buttons
When viewing the cart, the buttons shown are context-dependent:
- **"💳 Place My Order"** (`btn_checkout`) — always shown
- **"➕ Add More"** (`btn_menu`) — always shown
- **"❌ Remove Last"** (`btn_remove_last`) — shown when cart has > 1 item
- **"🔄 Clear Cart"** / **"🔄 Start Fresh"** (`btn_clear_cart`) — shown when cart has exactly 1 item

### Checkout Flow
When "Place My Order" is clicked:
1. Bot fetches a fresh session from DB (force refresh).
2. Bot checks for a **saved address** from the last non-cancelled order.
3. If found (and not "Store Pickup"), offers "✅ Use Previous" / "🚚 New Address" / "🏪 Store Pickup".
4. If not found, shows delivery vs. pickup choice directly (with "⬅️ Back" button).

---

## 9. Delivery System (`delivery.ts`)

### Address Input
Accepts two input methods:
- **Text**: User types their address manually. Validated for minimum length (5 chars) and sanitized.
- **GPS Location**: User shares WhatsApp location. The bot performs **reverse geocoding** via Nominatim API (OpenStreetMap) with a 5-second timeout, and generates a Google Maps link. If the location address is too short (< 5 chars), reverse geocoding is performed automatically.

### Address Format
The final stored address may include:
- Landmark name (prefixed with 🏛️)
- Full address from geocoding
- Google Maps link (prefixed with 🔗)

### Notes / Cake Message Personalization
After address input, the bot asks for cake personalization:
- User can type a custom message (e.g., "Happy Birthday Priya! 🎉")
- User can reply "Skip", "No", or "None" to skip
- Input is validated and sanitized

### Delivery Slot Generation
`getAvailableSlots()` generates time windows for the next 4 days:
- **Time Windows**: Configurable via `DELIVERY_SLOTS` database setting. Defaults to 12-3 PM, 3-6 PM, 6-9 PM.
- **Smart Filtering**: Today's slots are filtered — only shows windows starting 2+ hours from now.
- **WhatsApp Limit**: Output is capped at 10 slots to stay within the API limit.
- **Time Zone**: All calculations use IST (UTC+5:30).

---

## 10. Order & Payment System (`orders.ts`)

### Order Creation
- **Order Number Format**: `SPC-YYMMDD-XXXXX` (e.g., `SPC-260515-A3K7R`)
- **Source**: All bot orders are tagged as `OrderSource.WHATSAPP`
- **Custom Orders**: Flagged with `isCustom: true` and `customImageUrl` pointing to uploaded reference photo.

### Confirmation Flow
When the user taps "✅ Confirm Order" (`btn_confirm`):
1. Cart items are validated (non-empty check)
2. Order is created in PostgreSQL with all items, address, notes, delivery date/slot
3. Razorpay payment link is generated
4. Cart is cleared, state is reset to `IDLE`
5. Success message is sent with delivery date, time slot, and address

Additional confirmation inputs accepted: typing "yes" or "confirm".

### Razorpay Payment Integration
After order creation:
1. A **Razorpay Payment Link** is generated via the Razorpay Node SDK
2. The link is sent to the user as a **CTA URL Button** ("💳 Pay Now") along with the order summary
3. The payment link and Razorpay order ID are saved back to the Order record
4. If Razorpay fails, the bot falls back to a text message with the total amount

### Razorpay Webhook (`/api/webhooks/razorpay`)
When payment is completed:
1. Signature is verified using `RAZORPAY_WEBHOOK_SECRET` (HMAC-SHA256)
2. Order status is updated to `CONFIRMED`, payment status to `PAID`
3. A **premium formatted receipt/bill** is sent to the customer via WhatsApp, including:
   - Order number, date, all items with prices
   - Delivery address, date, and time slot
   - Custom message/notes
   - Thank-you branding

### Order Status
The `sendOrderStatus()` function shows the user's last 3 orders with:
- Status emoji (🕐 Pending, ✅ Confirmed, 👩‍🍳 Preparing, 📦 Ready, 🎉 Delivered, ❌ Cancelled)
- Item details with quantities and prices
- Total and order date

If no orders exist, the bot shows buttons: "📋 Browse Our Cakes" and "🎨 Custom Creation".

### Order Cancellation
When the user taps "❌ Cancel" or types "no"/"cancel" during `CONFIRMING_ORDER`:
1. Cart is cleared
2. State is reset to `IDLE`
3. "❌ Order cancelled." message is sent
4. Welcome message is re-sent

---

## 11. Custom Cake Orders (`custom-orders.ts`)

Two entry points:
1. **Text description first** (`CUSTOM_ORDER_DETAILS`): User describes their cake → bot saves notes → asks for reference photo. If the text looks like an address (contains numbers, > 3 words), bot saves it as the delivery address instead.
2. **Photo first**: User sends an image → bot downloads via Meta API → uploads to Supabase Storage (`cakes/custom-requests/`) → creates order immediately with an auto-generated order number.

After a custom order is created, the bot:
- Shows the order reference number
- Informs the user that the team will call them for a quote
- Offers buttons: "📋 View Menu" and "📦 My Orders"

### Direct Custom Entry from Website
If a user sends the message `"design my own cake"` (website deep-link), the bot enters `CUSTOM_ORDER_IMAGE` directly, skipping the description step.

### Media Pipeline (`media.ts`)
1. Fetch media URL from Meta Graph API using `mediaId`
2. Download actual image bytes from the temporary Meta URL
3. Upload to Supabase Storage bucket `cakes/custom-requests/` with unique filename (`custom_{mediaId}_{timestamp}.jpg`)
4. Return public URL for storage in the order record

All steps have 10-second timeouts. If any step fails, the order is still created with a `whatsapp://media/{id}` fallback reference.

---

## 12. Automated Maintenance

### Session Cleanup Cron (`/api/cron/cleanup`)
Runs daily via Vercel Cron, secured by `CRON_SECRET` header:
- **24h inactive**: Reset state to `IDLE`, clear all selection fields (cakeId, size, price, address, notes, delivery date/slot, custom image URL), reset quantity to 1
- **7d inactive**: Delete the conversation record entirely
- **Memory cleanup**: Clear `convoCache` after bulk operations (note: only affects the current server instance)

### In-Memory Cache Management (`cache.ts`)
- **Message Deduplication**: `processedMessages` Set (LRU-evicted at 2000 entries) and `inFlightMessages` Set prevent duplicate processing from Meta webhook retries.
- **Menu Cache**: `cakeCache` and `categoryCache` with 1-minute TTL, invalidated by `clearMenuCache()`.
- **Conversation Cache**: `convoCache` Map provides zero-latency session reads, updated via `updateConvoCache()` on every state change.

---

## 13. Output Service — Meta API Bridge (`whatsapp.ts`)

The service layer handles all outbound communication with the WhatsApp Cloud API v18.0.

| Function | WhatsApp Type | Use Case |
|---|---|---|
| `sendTextMessage()` | `text` | Plain messages, error notices |
| `sendImageMessage()` | `image` | Cake photos with captions |
| `sendInteractiveList()` | `interactive/list` | Menu browsing, category selection, delivery slots |
| `sendInteractiveButtons()` | `interactive/button` | Size selection (≤3 options), confirmations, cart actions |
| `sendCTAUrlButton()` | `interactive/cta_url` | Razorpay "Pay Now" button |
| `sendDocumentMessage()` | `document` | Menu PDF |
| `markAsRead()` | `status/read` | Blue double-tick ✓✓ |

### URL Resolution
For `sendImageMessage` and `sendDocumentMessage`, relative URLs (starting with `/`) are automatically prefixed:
1. `NEXT_PUBLIC_APP_URL` (primary)
2. `VERCEL_URL` (fallback on Vercel)
3. Localhost warning if neither is set

All outbound calls have a **10-second timeout** via `fetchWithTimeout` and `AbortController`.

---

## 14. Environment Variables Reference

| Variable | Required | Description |
|---|---|---|
| `WHATSAPP_TOKEN` | ✅ | Meta permanent system user access token |
| `WHATSAPP_PHONE_ID` | ✅ | Business phone number ID |
| `WHATSAPP_VERIFY_TOKEN` | ✅ | Shared secret for webhook verification |
| `WHATSAPP_APP_SECRET` | ⚠️ | App secret for signature verification (recommended) |
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `NEXT_PUBLIC_SUPABASE_URL` | ✅ | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | ✅ | Supabase admin key (for media uploads) |
| `RAZORPAY_KEY_ID` | ✅ | Razorpay API key |
| `RAZORPAY_KEY_SECRET` | ✅ | Razorpay API secret |
| `RAZORPAY_WEBHOOK_SECRET` | ✅ | Razorpay webhook signature secret |
| `NEXT_PUBLIC_APP_URL` | ✅ | Production URL (for image/doc resolution) |
| `VERCEL_URL` | Auto | Set automatically by Vercel |
| `CRON_SECRET` | ✅ | Bearer token for cron endpoint security |
