/**
 * WhatsApp Conversation State Machine (Custom Flow Enabled)
 * WhatsApp Conversation State Machine
 * Handles the full ordering flow: IDLE → BROWSING → SELECTING_SIZE → CONFIRMING → COMPLETE
 */
import { db } from "~/server/db";
import { products } from "~/data/landing";
import {
  sendTextMessage,
  sendInteractiveList,
  sendInteractiveButtons,
  sendImageMessage,
} from "~/server/whatsapp";
import { createPaymentLink } from "~/server/razorpay";
import natural from "natural";

const { JaroWinklerDistance } = natural;

// ─── Types & Interfaces ──────────────────────────────────────────────────────

interface CakeOption {
  id?: string;
  size: string;
  serves: string;
  price: string;
}

interface Cake {
  id: string | number;
  name: string;
  description?: string | null;
  image: string;
  category?: string;
  options: CakeOption[];
}

interface CartItem {
  id: string;
  cakeName: string;
  size: string;
  price: string;
  quantity: number;
}

// ─── DB Helpers with Caching ─────────────────────────────────────────────

let cakeCache: Cake[] | null = null;
let lastCacheUpdate = 0;
const CACHE_TTL = 30 * 60 * 1000; // 30 minutes (admin panel triggers clearMenuCache on updates)

/**
 * Force clear the cake menu cache (used by admin panel)
 */
export function clearMenuCache() {
  cakeCache = null;
  lastCacheUpdate = 0;
  console.log("[WhatsApp] Menu cache cleared via Admin Panel.");
}

// ─── Conversation State Cache ─────────────────────────────────────────────
// Eliminates the DB read on every incoming message.
// The Map is keyed by phone number and holds the full conversation object.

// Conversation state cache
const convoCache = new Map<string, Conversation>();
const processingLocks = new Map<string, Promise<void>>();

const GREETINGS = ["hi", "hello", "hey", "hii", "hiii", "hey there", "good morning", "good evening"];

const RESET_STATE = {
  selectedCake: null,
  selectedSize: null,
  selectedPrice: null,
  selectedAddress: null,
  selectedNotes: null,
  selectedDeliveryDate: null,
  selectedDeliveryTime: null,
  customImageUrl: null,
};

function updateConvoCache(phone: string, data: Partial<Conversation>) {
  const existing = convoCache.get(phone) ?? { phone, state: "IDLE" } as Conversation;
  convoCache.set(phone, { ...existing, ...data });
}

async function safeGetCakes(): Promise<Cake[]> {
  const now = Date.now();
  if (cakeCache && (now - lastCacheUpdate < CACHE_TTL)) {
    console.log("[WhatsApp] Using cached cake menu.");
    return cakeCache;
  }

  console.log("[WhatsApp] Cache expired or missing. Fetching cakes from DB...");
  try {
    const result = await withTimeout(
      db.cake.findMany({ include: { options: true } }),
      DB_TIMEOUT
    );

    if (result) {
      cakeCache = result as unknown as Cake[];
      lastCacheUpdate = now;
      return cakeCache;
    }
    return products as unknown as Cake[];
  } catch (e) {
    console.warn("[WhatsApp] DB Menu fetch failed, using fallback.", e);
    return cakeCache ?? (products as unknown as Cake[]);
  }
}

async function findCake(query: string | number | null | undefined): Promise<Cake | null> {
  if (!query) return null;
  const queryStr = query.toString().trim().toLowerCase();
  if (!queryStr) return null;
  const cakes = await safeGetCakes();

  // 1. Exact ID match
  const byId = cakes.find(c => c.id.toString() === queryStr);
  if (byId) return byId;

  // 2. Exact Name match
  const byName = cakes.find(c => c.name.toLowerCase() === queryStr);
  if (byName) return byName;

  // 3. Partial Name match
  const byPartial = cakes.find(c => c.name.toLowerCase().includes(queryStr) || queryStr.includes(c.name.toLowerCase()));
  if (byPartial) return byPartial;

  // 4. Fuzzy match (Jaro-Winkler) - Handles typos like "Choclate"
  let bestMatch = null;
  let highestScore = 0;
  for (const cake of cakes) {
    const score = JaroWinklerDistance(queryStr, cake.name.toLowerCase());
    if (score > highestScore && score > 0.8) { // 0.8 is a better balance
      highestScore = score;
      bestMatch = cake;
    }
  }
  if (bestMatch) {
    console.log(`[WhatsApp] Fuzzy match found: "${queryStr}" -> "${bestMatch.name}" (Score: ${highestScore.toFixed(2)})`);
    return bestMatch;
  }

  // 5. DB Fallback for long IDs
  if (queryStr.length > 5) {
    try {
      const dbCake = await withTimeout(
        db.cake.findUnique({ where: { id: queryStr }, include: { options: true } }),
        DB_TIMEOUT
      );
      if (dbCake) return dbCake as unknown as Cake;
    } catch { }
  }

  // 5. Hardcoded products fallback
  const localProduct = products.find(p => p.id.toString() === queryStr || p.name.toLowerCase() === queryStr);
  return localProduct as unknown as Cake ?? null;
}

// ─── DB Resilience ─────────────────────────────────────────────────────────

const DB_TIMEOUT = 5000; // 5 seconds

function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error("DB Timeout")), timeoutMs)
    ),
  ]);
}

// ─── Types ──────────────────────────────────────────────────────────────────

type ConversationState =
  | "IDLE"
  | "BROWSING_MENU"
  | "SELECTING_CATEGORY"
  | "SELECTING_SIZE"
  | "ASKING_ADDRESS"
  | "ASKING_INSTRUCTIONS"
  | "ASKING_DELIVERY_DATE"
  | "ASKING_DELIVERY_TIME"
  | "CONFIRMING"
  | "REQUESTING_CUSTOM"
  | "UPLOADING_REFERENCE_IMAGE";

interface Conversation {
  id: string;
  phone: string;
  name?: string | null;
  state: string;
  selectedCake?: string | null;
  selectedSize?: string | null;
  selectedPrice?: string | null;
  selectedAddress?: string | null;
  selectedNotes?: string | null;
  selectedQuantity?: number | null;
  selectedDeliveryDate?: string | null;
  selectedDeliveryTime?: string | null;
  customImageUrl?: string | null;
  cart?: CartItem[];
}

interface IncomingMessage {
  from: string;
  name?: string;
  type: "text" | "interactive" | "location" | "image";
  text?: string;
  interactiveId?: string;
  interactiveTitle?: string;
  messageId: string;
  location?: {
    latitude: number;
    longitude: number;
    name?: string;
    address?: string;
  };
  image?: {
    id: string;
    caption?: string;
    mimeType: string;
  };
}

// ─── Order number generator ────────────────────────────────────────────────

function generateOrderNumber(): string {
  const prefix = "SPC";
  const timestamp = Date.now().toString(36).toUpperCase().slice(-4);
  const random = Math.random().toString(36).substring(2, 5).toUpperCase();
  return `${prefix}-${timestamp}${random}`;
}

// ─── Get or create conversation ────────────────────────────────────────────

async function getConversation(phone: string, name?: string): Promise<Conversation> {
  // ── Cache hit: skip DB entirely ──────────────────────────────────────────
  const cached = convoCache.get(phone);
  if (cached) {
    // Patch the name if we didn't have it before (fire-and-forget)
    if (name && !cached.name) {
      cached.name = name;
      convoCache.set(phone, cached);
      void db.whatsAppConversation.update({ where: { phone }, data: { name } }).catch(() => null);
    }
    console.log(`[WhatsApp] Conversation cache hit for ${phone} (state: ${cached.state})`);
    return cached;
  }

  // ── Cache miss: load from DB and warm the cache ──────────────────────────
  console.log(`[WhatsApp] Conversation cache miss for ${phone}. Loading from DB...`);
  try {
    let convo = await withTimeout(
      db.whatsAppConversation.findUnique({
        where: { phone },
        include: { cart: true }
      }),
      DB_TIMEOUT
    );

    if (!convo) {
      convo = await withTimeout(
        db.whatsAppConversation.create({
          data: { phone, name },
          include: { cart: true }
        }),
        DB_TIMEOUT
      );
    } else if (name && !convo.name) {
      convo = await withTimeout(
        db.whatsAppConversation.update({
          where: { phone },
          data: { name },
          include: { cart: true }
        }),
        DB_TIMEOUT
      );
    }

    const result = convo as unknown as Conversation;
    convoCache.set(phone, result);
    return result;
  } catch {
    // Return a dummy object to allow the bot to continue with default state
    const fallback = { phone, state: "IDLE", name: name ?? "Customer", cart: [] } as unknown as Conversation;
    convoCache.set(phone, fallback);
    return fallback;
  }
}

// ─── Update conversation state ─────────────────────────────────────────────

async function updateState(
  phone: string,
  state: ConversationState,
  extra: Partial<Conversation> = {}
) {
  // Update in-memory cache immediately
  updateConvoCache(phone, { state, ...extra });

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const { cart, ...otherExtra } = extra;

  void withTimeout(
    db.whatsAppConversation.update({
      where: { phone },
      data: { state, lastMessageAt: new Date(), ...otherExtra },
    }),
    DB_TIMEOUT
  ).catch((e) => console.error("[WhatsApp] updateState DB write failed:", e));
}


// ─── Cart Helpers ─────────────────────────────────────────────────────────

async function addToCart(phone: string, item: { cakeName: string; size: string; price: string; quantity: number }) {
  try {
    const existingItem = await db.whatsAppCartItem.findFirst({
      where: { phone, cakeName: item.cakeName, size: item.size },
    });

    const resultItem = await db.whatsAppCartItem.upsert({
      where: { id: existingItem?.id ?? "new-item" },
      create: { ...item, phone },
      update: { quantity: { increment: item.quantity } },
    });

    console.log(`[WhatsApp] CART_UPDATE: ${phone} added ${item.cakeName} (${item.size}) - Abandoned tracking started.`);

    const cached = convoCache.get(phone);
    if (cached) {
      const currentCart = cached.cart ?? [];
      if (existingItem) {
        cached.cart = currentCart.map(i => i.id === existingItem.id ? (resultItem as unknown as CartItem) : i);
      } else {
        cached.cart = [...currentCart, resultItem as unknown as CartItem];
      }
      convoCache.set(phone, cached);
    }
    return resultItem;
  } catch (e) {
    console.error("[WhatsApp] addToCart failed:", e);
    return null;
  }
}

async function clearCart(phone: string) {
  try {
    await db.whatsAppCartItem.deleteMany({ where: { phone } });
    const cached = convoCache.get(phone);
    if (cached) {
      cached.cart = [];
      convoCache.set(phone, cached);
    }
  } catch (e) {
    console.error("[WhatsApp] clearCart failed:", e);
  }
}

function getCartTotal(cart: CartItem[]): string {
  let total = 0;
  for (const item of cart) {
    // Remove currency symbols, commas, and whitespace
    const priceStr = item.price.replace(/[^\d]/g, "");
    const price = parseInt(priceStr, 10);
    if (!isNaN(price)) {
      total += price * (item.quantity || 1);
    }
  }
  return `₹${total}`;
}

function formatItemTotal(price: string, quantity: number): string {
  const unitPrice = parseInt(price.replace(/[^\d]/g, ""), 10);
  if (isNaN(unitPrice)) return price;
  return `₹${unitPrice * quantity}`;
}

async function reverseGeocode(lat: number, lon: number): Promise<string | undefined> {
  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=18&addressdetails=1`,
      {
        headers: {
          "User-Agent": "SonnasPatisserieBot/1.0",
        },
      }
    );
    const data = await response.json() as { display_name: string };
    return data.display_name ?? undefined;
  } catch (e) {
    console.error("[WhatsApp] reverseGeocode failed:", e);
    return undefined;
  }
}

function getCartSummary(cart: CartItem[]): string {
  if (!cart || cart.length === 0) return "Your cart is empty.";
  let summary = `🛒 *Your Cart*\n\n`;
  cart.forEach((item, idx) => {
    const displayPrice = formatItemTotal(item.price, item.quantity);
    summary += `${idx + 1}. *${item.cakeName}* (${item.size})${item.quantity > 1 ? ` x${item.quantity}` : ""} — ${displayPrice}\n`;
  });
  summary += `\n*Total: ${getCartTotal(cart)}*`;
  return summary;
}

function buildOrderSummary(cart: CartItem[], convo: Conversation): string {
  let summary = `📋 *Order Summary*\n\n`;
  if (cart.length === 0) {
    summary += "_No items in cart._\n";
  } else {
    cart.forEach((item, idx) => {
      const displayPrice = formatItemTotal(item.price, item.quantity);
      summary += `${idx + 1}. *${item.cakeName}* (${item.size})${item.quantity > 1 ? ` x${item.quantity}` : ""} — ${displayPrice}\n`;
    });
  }
  summary += `\n*Total: ${getCartTotal(cart)}*\n`;
  summary += `📍 Address: ${convo.selectedAddress ?? "_Not provided_"}\n`;
  summary += `📝 Notes: ${convo.selectedNotes ?? "_None_"}\n`;
  summary += `📅 Delivery: *${convo.selectedDeliveryDate ?? "Today"}*\n`;
  summary += `🕒 Timing: *${convo.selectedDeliveryTime ?? "Anytime"}*\n\n`;
  summary += `Shall I place this order?`;
  return summary;
}

async function createCustomOrder(
  msg: IncomingMessage,
  convo: Conversation,
  publicUrl: string | null | undefined,
  mediaId: string,
  caption: string
) {
  const orderNumber = generateOrderNumber();
  const notes = (convo.selectedNotes ?? "") + (caption ? `\nTheme: ${caption}` : "");
  const imageUrl = publicUrl ?? `whatsapp://media/${mediaId}`;

  await db.whatsAppOrder.create({
    data: {
      orderNumber,
      phone: msg.from,
      customerName: convo.name ?? msg.name,
      totalPrice: "Pending Quote",
      notes,
      status: "PENDING",
      isCustom: true,
      customImageUrl: imageUrl,
      items: {
        create: [{
          cakeName: "CUSTOM_CAKE",
          size: "Custom Design",
          price: "Pending Quote",
          quantity: 1
        }]
      }
    }
  });

  return updateState(msg.from, "IDLE", {
    ...RESET_STATE,
    customImageUrl: imageUrl,
    selectedNotes: (convo.selectedNotes ?? "") + "\n[Reference Image Attached] " + caption,
  });
}

// ─── Main handler ──────────────────────────────────────────────────────────

export async function handleIncomingMessage(msg: IncomingMessage) {
  const phone = msg.from;

  // ── Optimization 2: Concurrency Lock ─────────────────────────────────────
  const existingLock = processingLocks.get(phone);
  if (existingLock) {
    console.log(`[WhatsApp] ⏳ Queuing message from ${phone}...`);
    await existingLock;
  }

  const processPromise = (async () => {
    try {
      await _internalHandleMessage(msg);
    } finally {
      processingLocks.delete(phone);
    }
  })();

  processingLocks.set(phone, processPromise);
  return processPromise;
}

async function _internalHandleMessage(msg: IncomingMessage) {
  const convo = await getConversation(msg.from, msg.name);
  const state = convo.state as ConversationState;
  const input = msg.text?.trim().toLowerCase() ?? "";
  const interactiveId = msg.interactiveId ?? "";

  console.log(`[WhatsApp] Processing from ${msg.from}: ${input || interactiveId} (State: ${state})`);
  const isGreeting = GREETINGS.includes(input);

  if (isGreeting) {
    if (state === "IDLE") {
      await sendWelcome(msg.from, msg.name);
    } else {
      const greeting = msg.name ? `Hi ${msg.name}! 👋` : "Hi! 👋";
      await Promise.all([
        sendTextMessage(msg.from, `${greeting} Let's continue from where we left off.`),
        rePromptState(msg.from, state, convo)
      ]);
    }
    return;
  }

  if (input === "restart" || input === "start over" || input === "reset") {
    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, "IDLE", RESET_STATE),
      sendTextMessage(msg.from, "❌ Order cancelled."),
      sendWelcome(msg.from, msg.name)
    ]);
    return;
  }

  if (input === "help") {
    await sendWelcome(msg.from, msg.name);
    return;
  }

  // ── Direct order from website ("Hi! I'd like to order: CakeName") ──────
  const orderMatch = /(?:i(?:'|')?d like to order:\s*|order:\s*)(.+)/i.exec(input);
  if (orderMatch) {
    const cakeName = orderMatch[1]!.trim();
    const selectedProduct = await findCake(cakeName);

    if (selectedProduct) {
      const tasks: Promise<unknown>[] = [
        updateState(msg.from, "SELECTING_SIZE", {
          selectedCake: selectedProduct.name,
          selectedSize: null,
          selectedPrice: null,
        })
      ];

      if (selectedProduct.image) {
        tasks.push(sendImageMessage(
          msg.from,
          selectedProduct.image,
          `*${selectedProduct.name}*\n\n${selectedProduct.description ?? ""}`
        ));
      }

      const options = selectedProduct.options ?? [];
      const buttons = options.slice(0, 2).map((opt, idx) => ({
        id: `size_${idx}`,
        title: `${opt.size} — ${opt.price}`,
      }));
      buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });

      tasks.push(sendInteractiveButtons(
        msg.from,
        `Hi ${msg.name ?? "there"}! 👋\n\nGreat choice! Choose your size for *${selectedProduct.name}*:`,
        buttons
      ));

      await Promise.all(tasks);
      return;
    }
    // If cake not found, fall through to welcome
    await sendWelcome(msg.from, msg.name);
    return;
  }

  // ── Design Your Cake Trigger from Website ──────────────────────────────
  if (input.includes("design my own cake")) {
    await Promise.all([
      updateState(msg.from, "UPLOADING_REFERENCE_IMAGE", {
        selectedCake: "CUSTOM_CAKE",
        selectedSize: "Custom Design",
        selectedPrice: "Pending Quote",
      }),
      sendTextMessage(
        msg.from,
        "Hi there! 👋 Welcome to our *Cake Design Flow*.\n\nTo get started, please upload a **Reference Photo** of the cake you have in mind! 📸"
      )
    ]);
    return;
  }

  if (input === "menu" || input === "cakes" || interactiveId === "btn_menu") {
    await Promise.all([
      updateState(msg.from, "BROWSING_MENU", {
        selectedCake: null,
        selectedSize: null,
        selectedPrice: null,
      }),
      sendMenu(msg.from)
    ]);
    return;
  }

  if (interactiveId === "btn_custom") {
    await Promise.all([
      updateState(msg.from, "REQUESTING_CUSTOM", {
        selectedCake: "CUSTOM_CAKE",
        selectedSize: "Custom Design",
        selectedPrice: "Pending Quote",
      }),
      sendTextMessage(
        msg.from,
        "🎨 *Custom Cake Request*\n\nPlease describe the cake you have in mind! (Flavor, Theme, Size, etc.)\n\n📸 You can also send a *Reference Photo* after describing it."
      )
    ]);
    return;
  }

  if (
    input === "status" ||
    input === "my order" ||
    input === "order status" ||
    interactiveId === "btn_status"
  ) {
    await sendOrderStatus(msg.from);
    return;
  }

  if (interactiveId === "btn_add_to_cart" || interactiveId === "btn_checkout" || interactiveId === "btn_checkout_now") {
    await handleCartActions(msg, convo);
    return;
  }

  if (interactiveId === "btn_clear_cart") {
    await Promise.all([
      clearCart(msg.from),
      sendTextMessage(msg.from, "🗑️ *Cart cleared!*"),
      sendMenu(msg.from)
    ]);
    return;
  }

  if (input === "cancel" || input === "cancel order" || interactiveId === "btn_cancel") {
    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, "IDLE", RESET_STATE),
      sendTextMessage(msg.from, "❌ Order cancelled."),
      sendWelcome(msg.from, msg.name)
    ]);
    return;
  }



  // ── Global Interactive ID handling (Resilience for old messages) ───────
  if (interactiveId.startsWith("cake_")) {
    await handleCakeSelection(msg);
    return;
  }
  if (interactiveId.startsWith("size_")) {
    await handleSizeSelection(msg, convo);
    return;
  }
  if (interactiveId.startsWith("date_")) {
    await handleDeliveryDateInput(msg, convo);
    return;
  }
  if (interactiveId.startsWith("time_")) {
    await handleDeliveryTimeInput(msg, convo);
    return;
  }

  // ── State-specific handling ────────────────────────────────────────────

  switch (state) {
    case "IDLE":
      if (input.length > 3) {
        const found = await findCake(input);
        if (found) {
          await handleCakeSelection({ ...msg, interactiveId: `cake_${found.id}` });
          return;
        }
      }
      await sendWelcome(msg.from, msg.name);
      break;

    case "BROWSING_MENU":
      await handleCakeSelection(msg);
      break;

    case "SELECTING_CATEGORY":
      await handleCategorySelection(msg);
      break;

    case "SELECTING_SIZE":
      await handleSizeSelection(msg, convo);
      break;

    case "ASKING_ADDRESS":
      await handleAddressInput(msg, convo);
      break;

    case "ASKING_INSTRUCTIONS":
      await handleInstructionsInput(msg, convo);
      break;

    case "ASKING_DELIVERY_DATE":
      await handleDeliveryDateInput(msg, convo);
      break;

    case "ASKING_DELIVERY_TIME":
      await handleDeliveryTimeInput(msg, convo);
      break;

    case "REQUESTING_CUSTOM":
      await handleCustomRequest(msg, convo);
      break;

    case "UPLOADING_REFERENCE_IMAGE":
      await handleReferenceImageUpload(msg, convo);
      break;

    case "CONFIRMING":
      await handleConfirmation(msg, convo);
      break;

    default:
      await sendWelcome(msg.from, msg.name);
  }
}

// ─── Welcome message ───────────────────────────────────────────────────────

async function sendWelcome(to: string, name?: string) {
  const greeting = name ? `Hi ${name}! 👋` : "Hi there! 👋";
  await sendInteractiveButtons(
    to,
    `${greeting}\n\nWelcome to *Sonna's Patisserie* 🎂\nHandcrafted cakes made with love.\n\n💡 *Quick Commands:*\n• *Menu* — Browse cakes\n• *Status* — Track order\n• *Restart | Cancel* — Cancel all and start over\n• Send 📍 Location for delivery`,
    [
      { id: "btn_menu", title: "📋 View Menu" },
      { id: "btn_custom", title: "🎨 Custom Cake" },
      { id: "btn_status", title: "📦 Order Status" },
    ]
  );
}

// ─── Send interactive menu ─────────────────────────────────────────────────

// ─── Send interactive menu ─────────────────────────────────────────────────

async function sendMenu(to: string) {
  const cakes = await safeGetCakes();

  if (cakes.length <= 10) {
    // If we have 10 or fewer cakes, show the full list in sections
    const chocolateCakes = cakes.filter((p) => p.category === "Chocolate Cakes" || p.category === "Chocolate");
    const vanillaCakes = cakes.filter((p) => p.category === "Vanilla Cakes" || p.category === "Vanilla");
    const teaCakes = cakes.filter((p) => p.category === "Tea Cakes" || p.category === "Tea");
    const seasonalCakes = cakes.filter((p) => p.category === "Seasonal Cakes" || p.category === "Seasonal");

    const sections = [];
    if (chocolateCakes.length > 0) {
      sections.push({
        title: "🍫 Chocolate Based",
        rows: chocolateCakes.map(cakeRow),
      });
    }
    if (vanillaCakes.length > 0) {
      sections.push({
        title: "🍦 Vanilla & Fruit Based",
        rows: vanillaCakes.map(cakeRow),
      });
    }
    if (teaCakes.length > 0) {
      sections.push({
        title: "☕ Tea Time Specials",
        rows: teaCakes.map(cakeRow),
      });
    }
    if (seasonalCakes.length > 0) {
      sections.push({
        title: "🍓 Seasonal Specials",
        rows: seasonalCakes.map(cakeRow),
      });
    }

    await sendInteractiveList(
      to,
      "🧁 Our Menu",
      "Browse our handcrafted signature cakes. Each made fresh with premium ingredients.\n\nTap below to explore:",
      "View Cakes",
      sections
    );
    await updateState(to, "BROWSING_MENU");
  } else {
    // Too many cakes for a single list
    await updateState(to, "SELECTING_CATEGORY");
    await sendInteractiveList(
      to,
      "🧁 Our Categories",
      "We have quite a variety today! Please select a category to browse:",
      "Select Category",
      [
        {
          title: "Filter by Type",
          rows: [
            { id: "cat_chocolate", title: "🍫 Chocolate", description: "Rich & decadent cakes" },
            { id: "cat_vanilla", title: "🍦 Vanilla & Fruit", description: "Light & refreshing flavors" },
            { id: "cat_tea", title: "☕ Tea Time", description: "Perfect with your afternoon tea" },
            { id: "cat_seasonal", title: "🍓 Seasonal", description: "Special treats for this month" },
          ],
        },
      ]
    );
  }
}

// ─── Helpers for Menu ──────────────────────────────────────────────────────


const cakeRow = (c: Cake) => ({
  id: `cake_${c.id}`,
  title: c.name.slice(0, 24),
  description: `From ${c.options?.[0]?.price ?? "₹750"}`,
});

// ─── Handle category selection ─────────────────────────────────────────────

async function handleCategorySelection(msg: IncomingMessage) {
  const category = msg.interactiveId?.replace("cat_", "") as
    | "chocolate"
    | "vanilla"
    | "tea"
    | "seasonal";

  if (!category || !["chocolate", "vanilla", "tea", "seasonal"].includes(category)) {
    await sendMenu(msg.from);
    return;
  }

  const categoryMap: Record<string, string> = {
    chocolate: "Chocolate Cakes",
    vanilla: "Vanilla Cakes",
    tea: "Tea Cakes",
    seasonal: "Seasonal Cakes",
  };

  const titles: Record<string, string> = {
    chocolate: "🍫 Chocolate Based",
    vanilla: "🍦 Vanilla & Fruit Based",
    tea: "☕ Tea Time Specials",
    seasonal: "🍓 Seasonal Specials",
  };

  const title = titles[category] ?? "Cakes";
  const catName = categoryMap[category] ?? "Cakes";

  const allCakes = await safeGetCakes();
  console.log(`[WhatsApp] Category filter: catName="${catName}", category="${category}", total cakes=${allCakes.length}`);
  console.log(`[WhatsApp] Cake categories in DB:`, allCakes.map(c => c.category));
  const filtered = allCakes.filter((p) => {
    const cat = (p.category ?? "").toLowerCase();
    return cat === catName.toLowerCase() || cat.includes(category);
  });
  console.log(`[WhatsApp] Filtered cakes: ${filtered.length}`);

  if (filtered.length === 0) {
    // No cakes in this category — show full menu instead
    await Promise.all([
      updateState(msg.from, "BROWSING_MENU"),
      sendTextMessage(msg.from, "No cakes found in that category. Here's our full menu:"),
      sendMenu(msg.from)
    ]);
    return;
  }

  await Promise.all([
    updateState(msg.from, "BROWSING_MENU"),
    sendInteractiveList(
      msg.from,
      title,
      `Here are our signature ${title.toLowerCase()} cakes:`,
      "Select a Cake",
      [
        {
          title: "Choose your favorite",
          rows: filtered.map(cakeRow),
        },
      ]
    )
  ]);
}

// ─── Handle cake selection ─────────────────────────────────────────────────

async function handleCakeSelection(msg: IncomingMessage) {
  let selectedProduct = null;

  // Check if they selected from the interactive list
  if (msg.interactiveId?.startsWith("cake_")) {
    selectedProduct = await findCake(msg.interactiveId.replace("cake_", ""));
  }

  if (!selectedProduct && msg.text) {
    selectedProduct = await findCake(msg.text);
  }

  if (!selectedProduct) {
    await sendTextMessage(
      msg.from,
      "Couldn't find that cake. 🤔\n\nReply *Menu* to see our full list!"
    );
    return;
  }

  // Store the selection and move to size selection
  const tasks: Promise<unknown>[] = [
    updateState(msg.from, "SELECTING_SIZE", {
      selectedCake: selectedProduct.name,
    })
  ];

  if (selectedProduct.image) {
    tasks.push(sendImageMessage(
      msg.from,
      selectedProduct.image,
      `*${selectedProduct.name}*\n\n${selectedProduct.description ?? ""}`
    ));
  }

  const options = selectedProduct.options ?? [];
  // WhatsApp allows max 3 buttons — use up to 2 sizes + Back to Menu
  const buttons = options.slice(0, 2).map((opt, idx) => ({
    id: `size_${idx}`,
    title: `${opt.size} — ${opt.price}`,
  }));
  buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });

  tasks.push(sendInteractiveButtons(
    msg.from,
    `Choose your size for *${selectedProduct.name}*:`,
    buttons
  ));

  await Promise.all(tasks);
}

// ─── Handle size selection ─────────────────────────────────────────────────

async function handleSizeSelection(
  msg: IncomingMessage,
  convo: Conversation
) {
  const cake = await findCake(convo.selectedCake);
  if (!cake) {
    console.warn(`[WhatsApp] handleSizeSelection: Cake not found for selection "${convo.selectedCake}"`);
    await updateState(msg.from, "IDLE", RESET_STATE);
    await sendTextMessage(msg.from, "Session expired or cake not found. Please select a cake from the menu again. 🎂");
    await sendMenu(msg.from);
    return;
  }

  let selectedOption = null;

  // From interactive button
  if (msg.interactiveId?.startsWith("size_")) {
    const sizeIdx = parseInt(msg.interactiveId.replace("size_", ""), 10);
    selectedOption = cake.options?.[sizeIdx];
  }

  // Or typed size
  if (!selectedOption && msg.text) {
    const input = msg.text.toLowerCase();
    selectedOption = cake.options?.find(
      (opt) =>
        input.includes(opt.size.toLowerCase()) ||
        input.includes(opt.price.toLowerCase())
    );
  }

  if (!selectedOption) {
    await sendTextMessage(
      msg.from,
      "Please select a valid size option, or reply *Cancel* to start over."
    );
    return;
  }

  // Offer to add to cart or checkout immediately
  await Promise.all([
    updateState(msg.from, "SELECTING_SIZE", {
      selectedSize: selectedOption.size,
      selectedPrice: selectedOption.price,
    }),
    sendInteractiveButtons(
      msg.from,
      `Great choice! *${convo.selectedCake}* (${selectedOption.size}) — ${selectedOption.price}.\n\nWhat would you like to do?`,
      [
        { id: "btn_add_to_cart", title: "🛒 Add to Cart" },
        { id: "btn_checkout", title: "💳 Confirm Order" },
        { id: "btn_menu", title: "📋 Back to Menu" },
      ]
    )
  ]);
}

async function handleCartActions(msg: IncomingMessage, convo: Conversation) {
  try {
    const isCheckout = msg.interactiveId === "btn_checkout" || msg.interactiveId === "btn_checkout_now";
    const hasActiveSelection = !!(convo.selectedCake && convo.selectedSize && convo.selectedPrice);

    // Case 1: "Add to Cart" clicked OR "Confirm Order" clicked while selecting a cake
    // In both cases, we show the cart summary first.
    if (msg.interactiveId === "btn_add_to_cart" || (isCheckout && hasActiveSelection)) {
      if (hasActiveSelection) {
        await addToCart(msg.from, {
          cakeName: convo.selectedCake!,
          size: convo.selectedSize!,
          price: convo.selectedPrice!,
          quantity: 1
        });
      } else {
        // Fallback: if somehow active selection is missing but they clicked the button
        console.warn(`[WhatsApp] handleCartActions: Missing active selection for ${msg.interactiveId}`);
        await sendTextMessage(msg.from, "⚠️ Selection lost. Please select your cake again from the menu.");
        await sendMenu(msg.from);
        return;
      }

      // Re-fetch convo to get updated cart
      const updatedConvo = convoCache.get(msg.from) ?? convo;
      const summary = getCartSummary(updatedConvo.cart ?? []);

      await Promise.all([
        sendTextMessage(msg.from, `✅ *${convo.selectedCake}* added to cart!`),
        sendInteractiveButtons(msg.from, summary, [
          { id: "btn_checkout", title: "💳 Confirm Order" },
          { id: "btn_menu", title: "➕ Add More" },
          { id: "btn_clear_cart", title: "🗑️ Clear Cart" },
        ]),
        updateState(msg.from, "IDLE", { selectedCake: null, selectedSize: null, selectedPrice: null })
      ]);
      return;
    }

    // Case 2: "Confirm Order" (btn_checkout) clicked from the cart summary (no active selection)
    if (isCheckout) {
      const updatedConvo = convoCache.get(msg.from) ?? convo;
      const cart = updatedConvo.cart ?? [];

      if (cart.length === 0) {
        await Promise.all([
          sendTextMessage(msg.from, "🛒 *Your cart is empty!*\n\nPlease select a cake from the menu first. 🎂"),
          sendMenu(msg.from)
        ]);
        return;
      }

      await Promise.all([
        updateState(msg.from, "ASKING_ADDRESS"),
        sendTextMessage(
          msg.from,
          "📍 Send your delivery address or share your *GPS Location*."
        )
      ]);
    }
  } catch (err) {
    console.error("[WhatsApp] Error in handleCartActions:", err);
    await sendTextMessage(msg.from, "⚠️ Something went wrong. Please try again or reply *Menu*.");
  }
}

// ─── Handle address input ──────────────────────────────────────────────────

async function handleAddressInput(
  msg: IncomingMessage,
  _convo: Conversation
) {
  let address = msg.text?.trim() ?? "";

  // If user sent a location instead of text
  if (msg.type === "location" && msg.location) {
    const { latitude, longitude, name, address: locAddress } = msg.location;
    // Create a Google Maps link
    const mapsUrl = `https://www.google.com/maps?q=${latitude},${longitude}`;

    // Attempt to reverse geocode if no address provided
    let finalAddress = locAddress;
    if (!finalAddress || finalAddress.length < 5) {
      console.log(`[WhatsApp] No address in location message. Attempting reverse geocode for ${latitude}, ${longitude}...`);
      // Send immediate feedback for better perceived performance
      await sendTextMessage(msg.from, "📍 _Processing your location..._");
      finalAddress = await reverseGeocode(latitude, longitude);
    }

    // Format: "Descriptive Address \n Maps Link"
    address = finalAddress
      ? `${finalAddress}\n🔗 ${mapsUrl}`
      : `📍 GPS Location\n🔗 ${mapsUrl}`;

    if (name) {
      address = `🏛️ ${name}\n${address}`;
    }

    console.log(`[WhatsApp] Received GPS location: ${latitude}, ${longitude} (Address: ${finalAddress})`);
  }

  if (!address || address.length < 5 || GREETINGS.includes(address.toLowerCase())) {
    await sendTextMessage(msg.from, "⚠️ *Invalid Address*\n\nPlease provide a complete delivery address (Street, Building, Landmark) or send your *GPS Location* to continue. 📍");
    return;
  }

  // Move to asking instructions
  await Promise.all([
    updateState(msg.from, "ASKING_INSTRUCTIONS", {
      selectedAddress: address,
    }),
    sendTextMessage(
      msg.from,
      "✅ *Address saved!* 📍\n\n🎂 *Cake Customization*\n\n• What would you like **written on the cake**?\n• Any special message, name, or age to add?\n• Any extra design instructions or customizations?\n\n✍️ Please reply with all your details (or reply *'Skip'* if none)."
    )
  ]);
}

// ─── Handle instructions input ─────────────────────────────────────────────

async function handleInstructionsInput(
  msg: IncomingMessage,
  _convo: Conversation
) {
  const input = msg.text?.trim() ?? "";
  const isSkip =
    input.toLowerCase() === "none" ||
    input.toLowerCase() === "skip" ||
    input.toLowerCase() === "no";

  const notes = isSkip ? null : input;

  if (!isSkip && (input.length < 2 || GREETINGS.includes(input.toLowerCase()))) {
    await sendTextMessage(msg.from, "🎂 Please provide your cake customization details (Text on cake, name, age, or design instructions). Reply *'Skip'* if none.");
    return;
  }

  // Move to asking delivery date
  await Promise.all([
    updateState(msg.from, "ASKING_DELIVERY_DATE", {
      selectedNotes: notes,
    }),
    sendDeliveryDateOptions(msg.from)
  ]);
}

// ─── Send delivery date options ────────────────────────────────────────────

async function sendDeliveryDateOptions(to: string) {
  const rows = [];
  const today = new Date();

  for (let i = 0; i < 10; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);

    const id = `date_${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, "0")}-${d.getDate().toString().padStart(2, "0")}`;
    const label = i === 0 ? "Today" : i === 1 ? "Tomorrow" : d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short" });
    const dateStr = d.toLocaleDateString("en-IN", { day: "numeric", month: "short" });

    rows.push({
      id,
      title: label,
      description: i <= 1 ? dateStr : undefined
    });
  }

  await sendInteractiveList(
    to,
    "📅 Select Delivery Date",
    "Please choose when you'd like your cake delivered:",
    "View Dates",
    [
      {
        title: "Available Dates",
        rows
      }
    ]
  );
}

// ─── Handle delivery date input ────────────────────────────────────────────

async function handleDeliveryDateInput(
  msg: IncomingMessage,
  _convo: Conversation
) {
  let deliveryDate = "";

  if (msg.interactiveId?.startsWith("date_")) {
    const datePart = msg.interactiveId.replace("date_", "");
    const d = new Date(datePart);
    deliveryDate = d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short", year: "numeric" });
  } else if (msg.text?.trim()) {
    // User typed a custom date
    deliveryDate = msg.text.trim();
  } else {
    await sendTextMessage(msg.from, "Please select a delivery date or type your preferred date.");
    return;
  }

  try {
    // Move to asking delivery time
    await Promise.all([
      updateState(msg.from, "ASKING_DELIVERY_TIME", {
        selectedDeliveryDate: deliveryDate,
      }),
      sendDeliveryTimeOptions(msg.from)
    ]);
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error("[WhatsApp] Error in handleDeliveryDateInput:", errorMsg);
    await sendTextMessage(msg.from, `⚠️ Sorry, I encountered an error: *${errorMsg}*\n\nPlease try again by replying *Menu*.`);
  }
}

// ─── Send delivery time options ───────────────────────────────────────────

async function sendDeliveryTimeOptions(to: string) {
  await sendInteractiveButtons(
    to,
    "🕒 Choose a delivery time slot:",
    [
      { id: "time_12pm_3pm", title: "12 pm - 3 pm" },
      { id: "time_3pm_6pm", title: "3 pm - 6 pm" },
      { id: "time_6pm_9pm", title: "6 pm - 9 pm" },
    ]
  );
}

// ─── Handle delivery time input ───────────────────────────────────────────

async function handleDeliveryTimeInput(
  msg: IncomingMessage,
  _convo: Conversation
) {
  let deliveryTime = "";

  if (msg.interactiveId?.startsWith("time_")) {
    const timeId = msg.interactiveId.replace("time_", "");
    deliveryTime = timeId.replace("_", " to ").replace("pm", " PM");
    // Format nicely: "12pm to 3pm" -> "12 PM to 3 PM"
    deliveryTime = deliveryTime.toUpperCase();
  } else if (msg.text?.trim()) {
    deliveryTime = msg.text.trim();
  } else {
    await sendTextMessage(msg.from, "Please select a delivery time slot.");
    return;
  }

  try {
    // Move to confirmation
    await updateState(msg.from, "CONFIRMING", {
      selectedDeliveryTime: deliveryTime,
    });

    // Use cached cart and convo
    const cart = convoCache.get(msg.from)?.cart ?? [];
    const currentConvo = convoCache.get(msg.from) ?? _convo;

    await sendInteractiveButtons(
      msg.from,
      buildOrderSummary(cart, currentConvo),
      [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]
    );
  } catch (err) {
    console.error("[WhatsApp] Error in handleDeliveryTimeInput:", err);
    await sendTextMessage(msg.from, "⚠️ Something went wrong. Please try again or reply *Menu*.");
  }
}

// ─── Handle custom cake request ───────────────────────────────────────────

async function handleCustomRequest(
  msg: IncomingMessage,
  convo: Conversation
) {
  // If user sends an image
  if (msg.type === "image" && msg.image) {
    const { downloadAndUploadImage } = await import("./media");
    const publicUrl = await downloadAndUploadImage(msg.image.id);

    await createCustomOrder(msg, convo, publicUrl ?? undefined, msg.image.id, msg.image.caption ?? "");

    await sendTextMessage(
      msg.from,
      "📸 Photo received! 🍰\n\nWe'll call you shortly to confirm details and provide a quote. 📞"
    );
    return;
  }

  // If user sends text (description)
  if (msg.type === "text" && msg.text) {
    await Promise.all([
      updateState(msg.from, "REQUESTING_CUSTOM", {
        selectedNotes: msg.text
      }),
      sendTextMessage(
        msg.from,
        "✅ Description received! 📝\n\nSend a **Reference Photo** 📸 or reply with your **Delivery Address** to proceed."
      )
    ]);
    return;
  }
}

// ─── Handle reference image upload (Design Your Cake Flow) ────────────────

async function handleReferenceImageUpload(
  msg: IncomingMessage,
  convo: Conversation
) {
  // If user sends an image
  if (msg.type === "image" && msg.image) {
    const { downloadAndUploadImage } = await import("./media");
    const publicUrl = await downloadAndUploadImage(msg.image.id);

    await createCustomOrder(msg, convo, publicUrl ?? undefined, msg.image.id, msg.image.caption ?? "");

    await sendTextMessage(
      msg.from,
      "📸 Photo received! 🍰\n\nWe'll call you shortly to confirm details and provide a quote. 📞"
    );
  } else {
    await sendTextMessage(
      msg.from,
      "Please upload a **Reference Photo** 📸 to proceed.\n\n(We need an image to understand your design! ✨)"
    );
  }
}

// ─── Order status lookup ───────────────────────────────────────────────────

async function sendOrderStatus(to: string) {
  const orders = await db.whatsAppOrder.findMany({
    where: { phone: to },
    orderBy: { createdAt: "desc" },
    include: { items: true },
    take: 3,
  });

  if (orders.length === 0) {
    await sendTextMessage(
      to,
      "You don't have any orders yet! 🛒\n\nReply *Menu* to see our cakes and place your first order! 🎂"
    );
    return;
  }

  const statusEmoji: Record<string, string> = {
    PENDING: "⏳",
    CONFIRMED: "✨",
    PREPARING: "👨‍🍳",
    READY: "🚗",
    DELIVERED: "✅",
    CANCELLED: "✕",
  };

  const statusFriendly: Record<string, string> = {
    PENDING: "Awaiting Confirmation",
    CONFIRMED: "Confirmed",
    PREPARING: "Preparing",
    READY: "Out for Delivery",
    DELIVERED: "Delivered",
    CANCELLED: "Cancelled",
  };

  let statusText = "📦 *Your Recent Orders*\n\n";

  for (const order of orders) {
    const emoji = statusEmoji[order.status] ?? "📋";
    const label = statusFriendly[order.status] ?? order.status;
    statusText += `${emoji} *#${order.orderNumber}*\n`;

    // Display items
    order.items.forEach(item => {
      const qtyStr = item.quantity > 1 ? ` (x${item.quantity})` : "";
      const displayPrice = formatItemTotal(item.price, item.quantity);
      statusText += `   🎂 ${item.cakeName} (${item.size})${qtyStr} — ${displayPrice}\n`;
    });

    statusText += `   💰 Total: ${order.totalPrice}\n`;
    statusText += `   Status: *${label}*\n`;
    statusText += `   Placed: ${order.createdAt.toLocaleDateString("en-IN")}\n\n`;
  }

  statusText += "Reply *Menu* to order more! 🧁";

  await sendTextMessage(to, statusText);
}

// ─── Handle confirmation ───────────────────────────────────────────────────

async function handleConfirmation(
  msg: IncomingMessage,
  convo: Conversation
) {
  try {
    const isConfirm =
      msg.interactiveId === "btn_confirm" ||
      msg.text?.toLowerCase() === "yes" ||
      msg.text?.toLowerCase() === "confirm";

    const isCancel =
      msg.interactiveId === "btn_cancel" ||
      msg.text?.toLowerCase() === "no" ||
      msg.text?.toLowerCase() === "cancel";

    if (!isConfirm && !isCancel) {
      // Unrelated input — acknowledge and re-prompt
      await sendTextMessage(msg.from, "Please confirm your order or cancel it to start over. 👇");
      await rePromptState(msg.from, "CONFIRMING", convo);
      return;
    }

    if (isCancel) {
      await Promise.all([
        clearCart(msg.from),
        updateState(msg.from, "IDLE", RESET_STATE),
        sendTextMessage(msg.from, "❌ Order cancelled."),
        sendWelcome(msg.from, convo.name ?? msg.name)
      ]);
      return;
    }

    // Use cached cart instead of DB fetch
    const cart = convoCache.get(msg.from)?.cart ?? [];

    if (cart.length === 0) {
      await updateState(msg.from, "IDLE");
      await sendTextMessage(
        msg.from,
        "Your cart is empty. Let's start over — reply *Menu*."
      );
      return;
    }

    // Create the order
    const orderNumber = generateOrderNumber();
    const totalPriceStr = getCartTotal(cart);
    const totalAmount = parseInt(totalPriceStr.replace(/[^\d]/g, ""), 10);
    const existingConvo = convoCache.get(msg.from) ?? (await getConversation(msg.from));

    console.log(`[WhatsApp] Confirming order ${orderNumber}...`);

    // Parallelize Razorpay call and DB creation
    const [rzpLinkResult, dbOrder] = await Promise.all([
      createPaymentLink({
        orderNumber,
        amount: totalAmount,
        phone: msg.from,
        name: existingConvo?.name ?? msg.name ?? "Customer",
      }).catch(err => {
        console.error("[WhatsApp] Razorpay failed:", err);
        return null;
      }),
      db.whatsAppOrder.create({
        data: {
          orderNumber,
          phone: msg.from,
          customerName: existingConvo?.name ?? msg.name,
          totalPrice: totalPriceStr,
          address: convo.selectedAddress,
          notes: convo.selectedNotes,
          deliveryDate: existingConvo?.selectedDeliveryDate,
          deliveryTime: existingConvo?.selectedDeliveryTime,
          status: "PENDING",
          paymentStatus: "PENDING",
          razorpayOrderId: "", // Will update if RZP succeeds
          paymentLink: "",
          isCustom: cart.some((item) => item.cakeName === "CUSTOM_CAKE"),
          customImageUrl: convo.customImageUrl,
          items: {
            create: cart.map((item) => ({
              cakeName: item.cakeName,
              size: item.size,
              price: item.price,
              quantity: item.quantity,
            })),
          },
        },
      })
    ]);

    let paymentLink = "";
    if (rzpLinkResult) {
      paymentLink = rzpLinkResult.short_url;
      // Update DB with RZP info in background
      void db.whatsAppOrder.update({
        where: { id: dbOrder.id },
        data: {
          paymentLink: rzpLinkResult.short_url,
          razorpayOrderId: rzpLinkResult.id
        },
      });
    }

    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, "IDLE", RESET_STATE)
    ]);

    let message = `🎉 *Order #${orderNumber} Placed!*\n\n`;
    message += `📅 *${existingConvo?.selectedDeliveryDate}* | 🕒 *${existingConvo?.selectedDeliveryTime}*\n`;
    message += `📍 ${convo.selectedAddress}\n\n`;

    if (paymentLink) {
      message += `💳 Pay *${totalPriceStr}* to confirm:\n${paymentLink}\n\n_Order auto-confirms on payment._`;
    } else {
      message += `💰 Total: *${totalPriceStr}*\n\nWe'll contact you shortly to confirm. 💕`;
    }

    await sendTextMessage(msg.from, message);
  } catch (error) {
    console.error("[WhatsApp] handleConfirmation CRASH:", error);
    await sendTextMessage(msg.from, "⚠️ Something went wrong. Please try again or contact us directly. 🙏");
  }
}

// ─── Re-prompt current state ─────────────────────────────────────────────

async function rePromptState(phone: string, state: ConversationState, convo: Conversation) {
  switch (state) {
    case "BROWSING_MENU":
      await sendMenu(phone);
      break;
    case "SELECTING_CATEGORY":
      await sendMenu(phone); // Go back to category list
      break;
    case "SELECTING_SIZE":
      if (convo.selectedCake) {
        const cake = await findCake(convo.selectedCake);
        if (cake) {
          const options = cake.options ?? [];
          const buttons = options.slice(0, 2).map((opt, idx) => ({
            id: `size_${idx}`,
            title: `${opt.size} — ${opt.price}`,
          }));
          buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });
          await sendInteractiveButtons(phone, `Choose your size for *${cake.name}*:`, buttons);
        } else {
          await sendMenu(phone);
        }
      } else {
        await sendMenu(phone);
      }
      break;
    case "ASKING_ADDRESS":
      await sendTextMessage(phone, "📍 Send your delivery address or share your *GPS Location*.");
      break;
    case "ASKING_INSTRUCTIONS":
      await sendTextMessage(phone, "🎂 *Cake Customization*\n\n• What would you like written on the cake?\n• Any special message, name, or age to add?\n• Any extra design instructions?\n\n✍️ Reply with your details or *'Skip'*.");
      break;
    case "ASKING_DELIVERY_DATE":
      await sendDeliveryDateOptions(phone);
      break;
    case "ASKING_DELIVERY_TIME":
      await sendDeliveryTimeOptions(phone);
      break;
    case "CONFIRMING":
      // Use cached cart
      const cart = convoCache.get(phone)?.cart ?? [];
      await sendInteractiveButtons(phone, buildOrderSummary(cart, convo), [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]);
      break;
    case "REQUESTING_CUSTOM":
      await sendTextMessage(phone, "🎨 *Custom Cake Request*\n\nPlease describe the cake or send a **Reference Photo**. 📸");
      break;
    case "UPLOADING_REFERENCE_IMAGE":
      await sendTextMessage(phone, "📸 *Reference Photo Needed*\n\nPlease upload a photo of the design you'd like us to create for you! ✨");
      break;
    default:
      await sendWelcome(phone, convo.name ?? undefined);
  }
}
