# WhatsApp Bot State Machine & Conversation Flow

The bot operates as a finite state machine (FSM). This document defines the complete states, transitions, triggers, and logic paths.

---

## 1. High-Level Conversation Flow

```mermaid
graph TD
    IDLE[IDLE State] -->|Greets / Help| WELCOME[Welcome Message + PDF]
    WELCOME -->|"Menu" / "Cakes" / btn_menu| BROWSING[BROWSING_MENU]
    BROWSING -->|cat_{id} / morecat_ / prevcat_| CATEGORY[SELECTING_CATEGORY]
    CATEGORY -->|cake_{id} / more_ / prev_| SIZE[SELECTING_SIZE]
    SIZE -->|size_{idx}| QUANTITY[SELECTING_QUANTITY]
    QUANTITY -->|qty_ / text number| CART[View Cart Summary]
    
    CART -->|btn_checkout| SAVED{Saved Address?}
    SAVED -->|Yes| REUSE[Offer Previous Address]
    SAVED -->|No| ADDRESS_CHOICE[Delivery vs Pickup]
    REUSE -->|saved_addr_yes| NOTES[ADDING_NOTES]
    REUSE -->|btn_delivery| ADDRESS_INPUT[INPUTTING_ADDRESS]
    ADDRESS_CHOICE -->|btn_delivery| ADDRESS_INPUT
    ADDRESS_CHOICE -->|btn_pickup| NOTES
    ADDRESS_INPUT -->|Text / Location| NOTES
    NOTES -->|Notes / Skip| SLOT[ASKING_DELIVERY_DATE]
    SLOT -->|slot_{date}_{id}| CONFIRM[CONFIRMING_ORDER]
    CONFIRM -->|btn_confirm| COMPLETE[Order Created + Pay Now]
    CONFIRM -->|btn_cancel| IDLE
    
    IDLE -->|btn_custom / "design my own cake"| CUSTOM_D[CUSTOM_ORDER_DETAILS]
    CUSTOM_D -->|Text description| CUSTOM_I[CUSTOM_ORDER_IMAGE]
    CUSTOM_D -->|Image sent| COMPLETE2[Custom Order Created]
    CUSTOM_I -->|Image sent| COMPLETE2
```

---

## 2. Conversation States (Complete Reference)

| State | Description | Entry Triggers | Exit Triggers |
|---|---|---|---|
| `IDLE` | Default. Awaiting contact. | Reset, cancel, timeout, order placed | Greeting, "Menu", "Status" |
| `BROWSING_MENU` | Category list with pagination | "Menu", `btn_menu`, `morecat_`, `prevcat_` | `cat_{id}` selection |
| `SELECTING_CATEGORY` | Cakes within a category, paginated | `cat_{id}`, `more_`, `prev_` | `cake_{id}` selection |
| `SELECTING_SIZE` | Cake sizes (buttons or list) | `cake_{id}` | `size_{idx}` selection |
| `SELECTING_QUANTITY` | How many units (1-20) | `size_{idx}` | `qty_` or text number |
| `INPUTTING_ADDRESS` | Delivery address / GPS / Pickup | `btn_checkout`, `btn_delivery` | Text address or location share |
| `ADDING_NOTES` | Cake message personalization | Address provided, `btn_pickup` | Text notes or "Skip" |
| `ASKING_DELIVERY_DATE` | Date + time slot selection | Notes provided | `slot_{date}_{id}` |
| `CONFIRMING_ORDER` | Final review & confirm | Slot selected | `btn_confirm` or `btn_cancel` |
| `CUSTOM_ORDER_DETAILS` | Custom cake text description | `btn_custom` | Text or image |
| `CUSTOM_ORDER_IMAGE` | Reference photo upload | Website deep-link, description provided | Image upload |

---

## 3. Interactive ID Patterns

All user interactions via WhatsApp buttons and lists use structured ID strings:

| Pattern | Example | Handler | Description |
|---|---|---|---|
| `cake_{id}` | `cake_cm4xyz123` | `handleCakeSelection` | Select a specific cake |
| `cat_{id}` | `cat_cm4abc456` | `handleCategorySelection` | Select a category |
| `size_{idx}` | `size_0`, `size_2` | `handleSizeSelection` | Select a size option by index |
| `qty_{n}` | `qty_3` | `handleQuantitySelection` | Select quantity |
| `more_{catId}_{offset}` | `more_cm4abc_9` | `handleCategorySelection` | Next page of cakes |
| `prev_{catId}_{offset}` | `prev_cm4abc_0` | `handleCategorySelection` | Previous page of cakes |
| `morecat_{offset}` | `morecat_9` | `sendMenu` | Next page of categories |
| `prevcat_{offset}` | `prevcat_0` | `sendMenu` | Previous page of categories |
| `slot_{date}_{slotId}` | `slot_2026-05-15_slot2` | `handleDeliverySlotSelection` | Select delivery slot |
| `saved_addr_yes` | — | State machine | Use previous delivery address |
| `btn_*` | `btn_menu`, `btn_back`, etc. | State machine | Action buttons |

---

## 4. Special Triggers & Website Deep-Links

### Direct Order from Website
If a user clicks a WhatsApp link like `?text=Hi! I'd like to order: Chocolate Cake`, the bot:
1. Extracts the cake name via regex
2. Performs fuzzy search via `findCake()`
3. Jumps directly to `SELECTING_SIZE` — bypassing menu browsing

### Custom Design from Website
If the message contains `"design my own cake"`, the bot enters `CUSTOM_ORDER_IMAGE` directly.

### Image Sent Outside Flow
If a user sends an unsolicited image while not in a custom order state, the bot proactively offers:
- "🎨 Start Custom Order" button
- "📋 Browse Menu" button

### Location Sent Outside Address Input
Saved for later use. The bot suggests replying "Menu" to start ordering.

---

## 5. Order Lifecycle (Post-Bot)

Once the bot flow finishes, the order transitions through business states managed in the Admin Dashboard:

```mermaid
stateDiagram-v2
    [*] --> PENDING: Order Placed
    PENDING --> CONFIRMED: Payment Received (Razorpay Webhook)
    PENDING --> CANCELLED: Timeout / Manual Cancel
    CONFIRMED --> OUT_FOR_DELIVERY: Admin dispatches
    CONFIRMED --> COMPLETED: Store Pickup collected
    OUT_FOR_DELIVERY --> DELIVERED: Driver confirms
    OUT_FOR_DELIVERY --> COMPLETED: Auto-complete
    DELIVERED --> COMPLETED: Final state
```

### Payment Flow
```
Order Created → Razorpay Link Generated → CTA Button Sent → User Pays
    → Razorpay Webhook fires → Order CONFIRMED → Premium Bill Sent via WhatsApp
```

---

## 6. Error & Edge Case Handling

| Scenario | Bot Response |
|---|---|
| Unknown text while `IDLE` | Fuzzy match cake names; if no match, show welcome |
| `SELECTING_SIZE` with lost `selectedCakeId` | Auto-reset to `IDLE` (zombie state protection) |
| Session idle > 60 minutes | Clear cart, reset state, fresh welcome |
| Cart empty at checkout | "Your selection is empty!" → show menu |
| Image fails to load during cake display | Skip image, still show size buttons |
| Razorpay link generation fails | Fall back to text with total amount |
| Database query timeout (>15s) | Use cached data or safe defaults |
| User sends >15 messages/minute | "Slow down!" message, further input blocked |
| Maintenance mode enabled | Show maintenance message (all users except status checks) |

---

## 7. Re-Prompt Logic

If a user sends a greeting while mid-flow (e.g., types "Hi" while on the size selection screen), the bot **does not reset**. Instead, it re-sends the current state's prompt:

| State | Re-Prompt Action |
|---|---|
| `BROWSING_MENU` | Re-send category menu |
| `SELECTING_SIZE` | Re-send size buttons for the selected cake |
| `INPUTTING_ADDRESS` | Re-send delivery/pickup choice |
| `ADDING_NOTES` | Re-send notes prompt |
| `CONFIRMING_ORDER` | Re-send order summary with confirm/cancel |
| `CUSTOM_ORDER_DETAILS` | Re-send custom cake description prompt |
| `CUSTOM_ORDER_IMAGE` | Re-send reference photo request |
