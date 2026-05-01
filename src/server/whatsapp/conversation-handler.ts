/**
 * WhatsApp Conversation State Machine (Custom Flow Enabled)
 * WhatsApp Conversation State Machine
 * Handles the full ordering flow: IDLE → BROWSING → SELECTING_SIZE → CONFIRMING → COMPLETE
 */
import { db } from "~/server/db";
import { products } from "~/data/landing";
import { classifyMessage } from "./local-classifier";
import {
  sendTextMessage,
  sendInteractiveList,
  sendInteractiveButtons,
  sendImageMessage,
} from "~/server/whatsapp";

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
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

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

async function safeGetCakeByName(name: string): Promise<Cake | null> {
  const cakes = await safeGetCakes();
  const found = cakes.find(c => c.name === name);
  if (found) return found;

  try {
    const result = await withTimeout(
      db.cake.findFirst({
        where: { name },
        include: { options: true },
      }),
      DB_TIMEOUT
    );
    return (result as unknown as Cake) ?? (products.find((p) => p.name === name) as unknown as Cake) ?? null;
  } catch {
    return (products.find((p) => p.name === name) as unknown as Cake) ?? null;
  }
}

async function safeGetCakeById(id: string): Promise<Cake | null> {
  console.log(`[WhatsApp] safeGetCakeById: looking for ID "${id}"`);
  
  const cakes = await safeGetCakes();
  const cached = cakes.find(c => c.id === id || c.id.toString() === id);
  if (cached) return cached;

  try {
    if (id.length > 5) {
      const result = await withTimeout(
        db.cake.findUnique({
          where: { id },
          include: { options: true },
        }),
        DB_TIMEOUT
      );
      if (result) return result as unknown as Cake;
      console.warn(`[WhatsApp] Cake ID "${id}" not found in DB, trying local products...`);
    }
    
    const localId = parseInt(id, 10);
    const found = products.find((p) => p.id === localId || p.id.toString() === id);
    if (found) return found as unknown as Cake;
    
    return null;
  } catch (e) {
    console.error(`[WhatsApp] safeGetCakeById error for "${id}":`, e);
    const localId = parseInt(id, 10);
    return (products.find((p) => p.id === localId || p.id.toString() === id) as unknown as Cake) ?? null;
  }
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
  | "CONFIRMING"
  | "REQUESTING_CUSTOM";

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
  extra: {
    selectedCake?: string | null;
    selectedSize?: string | null;
    selectedPrice?: string | null;
    selectedAddress?: string | null;
    selectedNotes?: string | null;
    selectedQuantity?: number | null;
    selectedDeliveryDate?: string | null;
    customImageUrl?: string | null;
    cart?: CartItem[];
  } = {}
) {
  // Update in-memory cache immediately (instant read for next message)
  updateConvoCache(phone, { state, ...extra });

  // We extract cart relation to avoid Prisma update errors
  const { cart: _cart, ...otherExtra } = extra;

  // Persist to DB in the background — don't block the reply
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
    const newItem = await db.whatsAppCartItem.create({
      data: {
        phone,
        cakeName: item.cakeName,
        size: item.size,
        price: item.price,
        quantity: item.quantity,
      },
    });

    const cached = convoCache.get(phone);
    if (cached) {
      cached.cart = [...(cached.cart ?? []), newItem as unknown as CartItem];
      convoCache.set(phone, cached);
    }
    return newItem;
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

function getCartSummary(cart: CartItem[]): string {
  if (!cart || cart.length === 0) return "Your cart is empty.";
  
  let summary = `🛒 *Your Cart*\n\n`;
  cart.forEach((item, idx) => {
    summary += `${idx + 1}. *${item.cakeName}* (${item.size}) — ${item.price}\n`;
  });
  summary += `\n*Total: ${getCartTotal(cart)}*`;
  return summary;
}

// ─── Main handler ──────────────────────────────────────────────────────────

export async function handleIncomingMessage(msg: IncomingMessage) {
  const convo = await getConversation(msg.from, msg.name);
  const state = convo.state as ConversationState;
  const input = msg.text?.trim().toLowerCase() ?? "";
  const interactiveId = msg.interactiveId ?? "";

  console.log(`[WhatsApp] Processing from ${msg.from}: ${input || interactiveId} (State: ${state})`);

  // ── Global commands (work from any state) ──────────────────────────────

  if (input === "help" || input === "hi" || input === "hello" || input === "hey") {
    await updateState(msg.from, "IDLE", {
      selectedCake: null,
      selectedSize: null,
      selectedPrice: null,
    });
    await sendWelcome(msg.from, msg.name);
    return;
  }

  // ── Direct order from website ("Hi! I'd like to order: CakeName") ──────
  const orderMatch = /(?:i(?:'|')?d like to order:\s*|order:\s*)(.+)/i.exec(input);
  if (orderMatch) {
    const cakeName = orderMatch[1]!.trim();
    const cakes = await safeGetCakes();
    const selectedProduct = cakes.find(
      (p) =>
        p.name.toLowerCase() === cakeName.toLowerCase() ||
        p.name.toLowerCase().includes(cakeName.toLowerCase()) ||
        cakeName.toLowerCase().includes(p.name.toLowerCase())
    ) ?? null;

    if (selectedProduct) {
      await updateState(msg.from, "SELECTING_SIZE", {
        selectedCake: selectedProduct.name,
        selectedSize: null,
        selectedPrice: null,
      });

      // Send product image
      if (selectedProduct.image) {
        await sendImageMessage(
          msg.from,
          selectedProduct.image,
          `*${selectedProduct.name}*\n\n${selectedProduct.description ?? ""}`
        );
      }

      const options = selectedProduct.options ?? [];
      const buttons = options.slice(0, 2).map((opt, idx) => ({
        id: `size_${idx}`,
        title: `${opt.size} — ${opt.price}`,
      }));
      buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });

      await sendInteractiveButtons(
        msg.from,
        `Hi ${msg.name ?? "there"}! 👋\n\nGreat choice! Choose your size for *${selectedProduct.name}*:`,
        buttons
      );
      return;
    }
    // If cake not found, fall through to welcome
    await sendWelcome(msg.from, msg.name);
    return;
  }

  if (input === "menu" || input === "cakes" || interactiveId === "btn_menu") {
    await updateState(msg.from, "BROWSING_MENU", {
      selectedCake: null,
      selectedSize: null,
      selectedPrice: null,
    });
    await sendMenu(msg.from);
    return;
  }

  if (interactiveId === "btn_custom") {
    await updateState(msg.from, "REQUESTING_CUSTOM", {
      selectedCake: "CUSTOM_CAKE",
      selectedSize: "Custom Design",
      selectedPrice: "Pending Quote",
    });
    await sendTextMessage(
      msg.from,
      "🎨 *Custom Cake Request*\n\nPlease describe the cake you have in mind! (Flavor, Theme, Size, etc.)\n\n📸 You can also send a *Reference Photo* after describing it."
    );
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

  if (input === "cancel" || interactiveId === "btn_cancel") {
    await updateState(msg.from, "IDLE", {
      selectedCake: null,
      selectedSize: null,
      selectedPrice: null,
    });
    await sendTextMessage(
      msg.from,
      "❌ Order cancelled.\n\nReply *Menu* to browse our cakes anytime! 🧁"
    );
    return;
  }

  // ── Handle Location Message ───────────────────────────────────────────

  if (msg.type === "location" && msg.location) {
    const { latitude, longitude } = msg.location;
    const address = msg.location.address ?? `Location: ${latitude}, ${longitude}`;
    
    if (state === "ASKING_ADDRESS") {
      await updateState(msg.from, "ASKING_INSTRUCTIONS", { selectedAddress: address });
      await sendTextMessage(msg.from, "✅ Location received! 📍\n\nAny *Special Instructions* or *Writings* for the cake?\n\n(Reply *None* to skip)");
      return;
    }
  }

  // ── Local NLP Classification (Make it faster) ──────────────────────────
  
  if (msg.type === "text" && input.length > 5 && state !== "CONFIRMING" && state !== "IDLE") {
    const category = classifyMessage(input);
    
    if (category === "ADDRESS" && state !== "ASKING_ADDRESS") {
      await updateState(msg.from, "ASKING_INSTRUCTIONS", { selectedAddress: msg.text ?? "" });
      await sendTextMessage(msg.from, "✅ Address saved! 📍\n\nAny *Special Instructions* or *Writings* for the cake?\n\n(Reply *None* to skip)");
      return;
    }
    
    if (category === "INSTRUCTIONS" && state !== "ASKING_INSTRUCTIONS") {
      await updateState(msg.from, "ASKING_DELIVERY_DATE", { selectedNotes: msg.text });
      // Read from cache — no extra DB round-trip needed
      const updated = convoCache.get(msg.from);
      
      // If we already have cake/size/address, go to delivery date selection
      if (updated?.selectedCake && updated?.selectedSize && updated?.selectedAddress) {
        await sendDeliveryDateOptions(msg.from);
        return;
      }
    }
  }

  // ── State-specific handling ────────────────────────────────────────────

  switch (state) {
    case "IDLE":
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

    case "REQUESTING_CUSTOM":
      await handleCustomRequest(msg, convo);
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
    `${greeting}\n\nWelcome to *Sonna's Patisserie & Cafe* 🎂\n\nEvery cake is handcrafted with love using the finest ingredients.\n\nWhat would you like to do?`,
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
    await updateState(msg.from, "BROWSING_MENU");
    await sendTextMessage(msg.from, "No cakes found in that category. Here's our full menu:");
    await sendMenu(msg.from);
    return;
  }

  await updateState(msg.from, "BROWSING_MENU");
  await sendInteractiveList(
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
  );
}

// ─── Handle cake selection ─────────────────────────────────────────────────

async function handleCakeSelection(msg: IncomingMessage) {
  let selectedProduct = null;

  // Check if they selected from the interactive list
  if (msg.interactiveId?.startsWith("cake_")) {
    const cakeId = msg.interactiveId.replace("cake_", "");
    selectedProduct = await safeGetCakeById(cakeId);
  }

  // Or if they typed a cake name
  if (!selectedProduct && msg.text) {
    const input = msg.text.toLowerCase();
    const cakes = await safeGetCakes();
    selectedProduct = cakes.find(
      (p) =>
        p.name.toLowerCase().includes(input) ||
        input.includes(p.name.toLowerCase())
    ) ?? null;
  }

  if (!selectedProduct) {
    console.warn(`[WhatsApp] handleCakeSelection: Failed to find cake. interactiveId="${msg.interactiveId}", text="${msg.text}"`);
    await sendTextMessage(
      msg.from,
      `I couldn't find that cake. 🤔 (ID: ${msg.interactiveId?.replace("cake_", "") ?? "none"})\n\nReply *Menu* to see our full list, or type the name of a cake!`
    );
    return;
  }

  // Store the selection and move to size selection
  await updateState(msg.from, "SELECTING_SIZE", {
    selectedCake: selectedProduct.name,
  });

  // 📸 Send Product Image
  if (selectedProduct.image) {
    await sendImageMessage(
      msg.from,
      selectedProduct.image,
      `*${selectedProduct.name}*\n\n${selectedProduct.description ?? ""}`
    );
  }

  const options = selectedProduct.options ?? [];
  // WhatsApp allows max 3 buttons — use up to 2 sizes + Back to Menu
  const buttons = options.slice(0, 2).map((opt, idx) => ({
    id: `size_${idx}`,
    title: `${opt.size} — ${opt.price}`,
  }));
  buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });

  await sendInteractiveButtons(
    msg.from,
    `Choose your size for *${selectedProduct.name}*:`,
    buttons
  );
}

// ─── Handle size selection ─────────────────────────────────────────────────

async function handleSizeSelection(
  msg: IncomingMessage,
  convo: Conversation
) {
  if (!convo.selectedCake) {
    await updateState(msg.from, "IDLE");
    await sendWelcome(msg.from);
    return;
  }

  const cake = await safeGetCakeByName(convo.selectedCake || "");
  if (!cake) {
    await updateState(msg.from, "IDLE");
    await sendWelcome(msg.from);
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
  await updateState(msg.from, "SELECTING_SIZE", {
    selectedSize: selectedOption.size,
    selectedPrice: selectedOption.price,
  });

  await sendInteractiveButtons(
    msg.from,
    `Great choice! *${convo.selectedCake}* (${selectedOption.size}) — ${selectedOption.price}.\n\nWhat would you like to do?`,
    [
      { id: "btn_add_to_cart", title: "🛒 Add to Cart" },
      { id: "btn_checkout", title: "💳 Checkout Now" },
      { id: "btn_menu", title: "📋 Back to Menu" },
    ]
  );
}

async function handleCartActions(msg: IncomingMessage, convo: Conversation) {
  try {
    if (msg.interactiveId === "btn_add_to_cart") {
      if (convo.selectedCake && convo.selectedSize && convo.selectedPrice) {
        await addToCart(msg.from, {
          cakeName: convo.selectedCake,
          size: convo.selectedSize,
          price: convo.selectedPrice,
          quantity: 1
        });
        
        await sendTextMessage(msg.from, `✅ Added *${convo.selectedCake}* to your cart!`);
        
        // Fetch fresh cart from DB to ensure UI is in sync
        const freshCart = await db.whatsAppCartItem.findMany({ where: { phone: msg.from } });
        const summary = getCartSummary(freshCart as unknown as CartItem[]);
        
        await sendInteractiveButtons(msg.from, summary, [
          { id: "btn_menu", title: "➕ Add More Cakes" },
          { id: "btn_checkout", title: "💳 Checkout" },
        ]);
        await updateState(msg.from, "IDLE", { selectedCake: null, selectedSize: null, selectedPrice: null });
      }
    } else if (msg.interactiveId === "btn_checkout" || msg.interactiveId === "btn_checkout_now") {
      // Add current selection if any and proceed to checkout
      if (convo.selectedCake && convo.selectedSize && convo.selectedPrice) {
        await addToCart(msg.from, {
          cakeName: convo.selectedCake,
          size: convo.selectedSize,
          price: convo.selectedPrice,
          quantity: 1
        });
      }
      
      await updateState(msg.from, "ASKING_ADDRESS");
      await sendTextMessage(
        msg.from,
        "📍 *Delivery Address*\n\nPlease provide your full delivery address.\n\n💡 *Tip:* You can also send your *GPS Location*!"
      );
    }
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error("[WhatsApp] Error in handleCartActions:", errorMsg);
    // Include the specific error for easier debugging
    await sendTextMessage(msg.from, `⚠️ Error: *${errorMsg}*\n\nPlease try again or reply *Menu*.`);
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
    address = locAddress ? `${locAddress}\n📍 ${mapsUrl}` : `📍 GPS Location: ${mapsUrl}`;
    
    if (name) {
      address = `📍 ${name}\n${address}`;
    }
    
    console.log(`[WhatsApp] Received GPS location: ${latitude}, ${longitude}`);
  }

  if (!address) {
    await sendTextMessage(msg.from, "Please provide a valid address or send your location to continue.");
    return;
  }

  // Move to asking instructions
  await updateState(msg.from, "ASKING_INSTRUCTIONS", {
    selectedAddress: address,
  });

  await sendTextMessage(
    msg.from,
    "✅ Address saved!\n\n📝 *Special Instructions*\n\nAny landmarks or special notes? (e.g., Gate code, call on arrival)\n\nReply *'None'* or *'Skip'* if you have none."
  );
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

  // Move to asking delivery date
  await updateState(msg.from, "ASKING_DELIVERY_DATE", {
    selectedNotes: notes,
  });

  await sendDeliveryDateOptions(msg.from);
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
    // Move to confirmation
    await updateState(msg.from, "CONFIRMING", {
      selectedDeliveryDate: deliveryDate,
    });

    // Fetch fresh cart and conversation to be 100% sure we have the latest data
    const cart = await withTimeout(
      db.whatsAppCartItem.findMany({ where: { phone: msg.from } }),
      DB_TIMEOUT
    ) as unknown as CartItem[];
    let updatedConvo = convoCache.get(msg.from);
    
    // If cache was lost, reload from DB
    updatedConvo ??= await getConversation(msg.from);

    let summary = `📋 *Order Summary*\n\n`;
    if (cart.length === 0) {
      summary += "_No items in cart._\n";
    } else {
      cart.forEach((item, idx) => {
        summary += `${idx + 1}. *${item.cakeName}* (${item.size}) — ${item.price}\n`;
      });
    }
    
    summary += `\n*Total: ${getCartTotal(cart)}*\n`;
    summary += `📍 Address: ${updatedConvo?.selectedAddress ?? "_Not provided_"}\n`;
    summary += `📝 Notes: ${updatedConvo?.selectedNotes ?? "_None_"}\n`;
    summary += `📅 Delivery: *${deliveryDate}*\n\n`;
    summary += `Shall I place this order?`;

    await sendInteractiveButtons(
      msg.from,
      summary,
      [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]
    );
  } catch (err) {
    const errorMsg = err instanceof Error ? err.message : String(err);
    console.error("[WhatsApp] Error in handleDeliveryDateInput:", errorMsg);
    await sendTextMessage(msg.from, `⚠️ Sorry, I encountered an error: *${errorMsg}*\n\nPlease try again by replying *Menu*.`);
  }
}

// ─── Handle custom cake request ───────────────────────────────────────────

async function handleCustomRequest(
  msg: IncomingMessage,
  convo: Conversation
) {
  // If user sends an image
  if (msg.type === "image" && msg.image) {
    const mediaId = msg.image.id;
    const caption = msg.image.caption ?? "";
    
    // Download from WhatsApp and upload to Supabase for permanent storage
    const { downloadAndUploadImage } = await import("./media");
    const publicUrl = await downloadAndUploadImage(mediaId);
    
    await updateState(msg.from, "IDLE", {
      customImageUrl: publicUrl ?? `whatsapp://media/${mediaId}`,
      selectedNotes: (convo.selectedNotes ?? "") + "\n[Reference Image Attached] " + caption,
      selectedCake: null,
      selectedSize: null,
      selectedPrice: null,
      selectedAddress: null,
      selectedDeliveryDate: null,
    });
    
    await sendTextMessage(
      msg.from,
      "📸 Reference photo received! 🍰\n\nThank you for sharing the design. You will receive a call from our cafe shortly to discuss the details and confirm your custom order. 📞"
    );
    return;
  }

  // If user sends text (description)
  if (msg.type === "text" && msg.text) {
    await updateState(msg.from, "REQUESTING_CUSTOM", {
      selectedNotes: msg.text
    });
    
    await sendTextMessage(
      msg.from,
      "✅ Got the description! 📝\n\nIf you have a **Reference Photo**, please send it now. 📸\n\nOtherwise, just reply with your **Delivery Address** to proceed."
    );
    return;
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
    PENDING: "🕐",
    CONFIRMED: "✅",
    PREPARING: "👩‍🍳",
    READY: "📦",
    DELIVERED: "🎉",
    CANCELLED: "❌",
  };

  let statusText = "📦 *Your Recent Orders*\n\n";

  for (const order of orders) {
    const emoji = statusEmoji[order.status] ?? "📋";
    statusText += `${emoji} *#${order.orderNumber}*\n`;
    
    // Display items
    order.items.forEach(item => {
      statusText += `   🎂 ${item.cakeName} (${item.size})\n`;
    });
    
    statusText += `   💰 Total: ${order.totalPrice}\n`;
    statusText += `   Status: *${order.status}*\n`;
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
  const isConfirm =
    msg.interactiveId === "btn_confirm" ||
    msg.text?.toLowerCase() === "yes" ||
    msg.text?.toLowerCase() === "confirm";

  if (!isConfirm) {
    await updateState(msg.from, "IDLE", {
      selectedCake: null,
      selectedSize: null,
      selectedPrice: null,
    });
    await sendTextMessage(
      msg.from,
      "❌ Order cancelled.\n\nReply *Menu* to browse our cakes anytime! 🧁"
    );
    return;
  }

  // Fetch fresh cart from DB for the order creation
  const cart = await db.whatsAppCartItem.findMany({ where: { phone: msg.from } }) as unknown as CartItem[];
  
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

  // Read from cache — no extra DB round-trip needed
  const existingConvo = convoCache.get(msg.from);

  await db.whatsAppOrder.create({
    data: {
      orderNumber,
      phone: msg.from,
      customerName: existingConvo?.name ?? msg.name,
      totalPrice: getCartTotal(cart),
      address: convo.selectedAddress,
      notes: convo.selectedNotes,
      deliveryDate: existingConvo?.selectedDeliveryDate,
      status: "PENDING",
      isCustom: cart.some(item => item.cakeName === "CUSTOM_CAKE"),
      customImageUrl: convo.customImageUrl,
      items: {
        create: cart.map(item => ({
          cakeName: item.cakeName,
          size: item.size,
          price: item.price,
          quantity: item.quantity
        }))
      }
    },
  });

  // Clear cart in DB
  await clearCart(msg.from);

  const deliveryInfo = existingConvo?.selectedDeliveryDate ?? "To be confirmed";

  // Reset conversation state
  await updateState(msg.from, "IDLE", {
    selectedCake: null,
    selectedSize: null,
    selectedPrice: null,
    selectedAddress: null,
    selectedNotes: null,
    selectedDeliveryDate: null,
    customImageUrl: null,
  });

  await sendTextMessage(
    msg.from,
    `🎉 *Order Placed Successfully!*\n\nYour order number is *#${orderNumber}*.\n\n📅 Delivery: *${deliveryInfo}*\n📍 Address: ${convo.selectedAddress}\n\nWe will notify you once your order is confirmed and out for delivery! 💕`
  );
}
