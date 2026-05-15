# WhatsApp Bot Architecture & Message Injection

This document describes the high-level system design and the lifecycle of a message within the Sonna's Patisserie ecosystem.

## 1. Webhook Entry (The Injection Point)
All incoming messages arrive via a **POST** request from Meta's servers to our webhook endpoint:
`src/app/api/whatsapp/webhook/route.ts`

### Webhook Security & Handshake
- **Verification**: The `GET` method handles the one-time `hub.verify_token` handshake.
- **Signature Validation**: In production, the bot validates the `X-Hub-Signature-256` header using the `APP_SECRET` to ensure the request is authentically from Meta.

### Parsing & Deduplication
- **Message Types**: Supports `text`, `interactive` (button/list), `image`, `location`, and `document`.
- **Deduplication**: Meta often retries webhooks. We use a `processedMessages` Set (LRU-evicted at 2000 entries) in `cache.ts` to ignore duplicate `messageId`s.

## 2. Concurrency Control (The Global Lock)
In `src/server/whatsapp/conversation-handler/index.ts`, we implement a per-user lock:
- **`processingLocks` Map**: A `Map<string, Promise<void>>` where the key is the user's phone number.
- **Mechanism**: Every incoming message waits for the previous message from the same user to finish processing (`existingLock.then(...)`). This prevents race conditions where a user clicks two buttons rapidly, potentially creating duplicate orders.

## 3. Session & State Management
The bot retrieves the current `WhatsAppConversation` using `getConversation()` in `session.ts`.

### Integrity Checks
- **Zombie State Protection**: If a user is in a state like `SELECTING_SIZE` but the session has lost the `selectedCakeId` (e.g. manual DB edit), the bot automatically resets to `IDLE` to prevent crashes.
- **Session Timeout**: If `lastActivityAt` is older than the configured timeout (default 60 mins), the cart is cleared and the user is welcomed back fresh.
- **Dynamic Configuration**: The bot uses a `WhatsAppSetting` table to manage runtime behaviors (Greetings, Delivery Slots, Maintenance Mode) without code changes.

## 4. Dynamic Configuration Management
The `getWhatsAppSetting(key, default)` helper in `session.ts` provides a unified interface for database-driven configuration.
- **JSON Parsing**: Settings like `DELIVERY_SLOTS` are stored as JSON strings and safely parsed into typed objects during message processing.
- **Fallback Chain**: The bot implements a strict "Database -> Constant -> Default" fallback chain to ensure reliability even if the database is under load.

## 5. State Machine Logic
Core business logic resides in `src/server/whatsapp/conversation-handler/state-machine.ts`.
- **`_internalHandleMessage`**: The heart of the bot. It maps the current state + user input to a transition.
- **NLP Fallback**: If the bot is `IDLE` and doesn't understand the command, it uses `natural` fuzzy matching to check if the user is trying to mention a cake name.

## 6. Output Service (The Meta Bridge)
`src/server/whatsapp.ts` handles the JSON payload construction for the Meta API.
- **Template Support**: Support for `cta_url` buttons (for Razorpay) and `quick_reply` buttons.
- **Error Handling**: Silent failures for image fetching to ensure the text-based menus still reach the user even if media servers are slow.
