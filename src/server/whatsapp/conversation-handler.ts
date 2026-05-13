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
  sendCTAUrlButton,
  sendDocumentMessage,
} from "~/server/whatsapp";

import { createPaymentLink } from "~/server/razorpay";
import { formatPrice } from "~/lib/format";
import natural from "natural";
import { validateAndSanitize } from "~/lib/validators";


const { JaroWinklerDistance } = natural;

// ─── Types & Interfaces ──────────────────────────────────────────────────────

interface CakeOption {
  id?: string;
  size: string;
  serves: string;
  price: number;
}


interface Cake {
  id: string | number;
  name: string;
  slug?: string;
  description?: string | null;
  image: string;
  category?: string;
  isAvailable?: boolean;
  sortOrder?: number;
  options: CakeOption[];
}

interface CartItem {
  id: string;
  cakeName: string;
  size: string;
  price: number;
  quantity: number;
  createdAt: Date | string;
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

// ─── Message Deduplication (HIGH-07) ──────────────────────────────────────
// Prevents duplicate processing when WhatsApp retries webhook delivery
const processedMessages = new Set<string>();
const MAX_PROCESSED_IDS = 2000;

const inFlightMessages = new Set<string>();

function beginMessageProcessing(messageId: string): boolean {
  if (processedMessages.has(messageId) || inFlightMessages.has(messageId)) return false;
  inFlightMessages.add(messageId);
  return true;
}

function markMessageProcessed(messageId: string) {
  processedMessages.add(messageId);
  // Evict oldest entries when set grows too large
  if (processedMessages.size > MAX_PROCESSED_IDS) {
    const first = processedMessages.values().next().value;
    if (first) processedMessages.delete(first);
  }
}


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
      cakeCache = (result as unknown as Cake[])
        .filter(c => c.isAvailable !== false)
        .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));
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

const DB_TIMEOUT = 15000; // 15 seconds

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
  | "SELECTING_QUANTITY"
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
  selectedPrice?: number | null;
  selectedAddress?: string | null;
  selectedNotes?: string | null;
  selectedQuantity?: number | null;
  selectedDeliveryDate?: string | null;
  selectedDeliveryTime?: string | null;
  customImageUrl?: string | null;
  cart?: CartItem[];
  lastActivityAt?: Date | string;
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
  const now = new Date();
  const dateStr = `${now.getFullYear().toString().slice(-2)}${(now.getMonth() + 1).toString().padStart(2, "0")}${now.getDate().toString().padStart(2, "0")}`;
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
  return `${prefix}-${dateStr}-${random}`;
}

// ─── Send Menu PDF Helper ──────────────────────────────────────────────────

async function sendMenuPDF(to: string) {
  try {
    // Small delay to ensure the previous message (greeting/confirmation) is processed first
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    await sendDocumentMessage(
      to,
      "/menu.pdf",
      "Sonnas_Patisserie_Menu.pdf",
      "Here is our official menu for your reference. 🧁"
    );
  } catch (e) {
    console.error("[WhatsApp] Failed to send menu PDF:", e);
  }
}

// ─── Get or create conversation ────────────────────────────────────────────

async function getConversation(phone: string, name?: string, force = false): Promise<Conversation> {
  // ── Cache hit: skip DB entirely ──────────────────────────────────────────
  const cached = convoCache.get(phone);
  if (cached && !force) {
    // Patch the name if we didn't have it before (fire-and-forget)
    if (name && !cached.name) {
      cached.name = name;
      convoCache.set(phone, cached);
      void db.whatsAppConversation.update({ where: { phone }, data: { name } }).catch(() => null);
    }
    console.log(`[WhatsApp] Conversation cache hit for ${phone} (state: ${cached.state})`);
    return cached;
  }

  // ── Cache miss or Forced: load from DB and warm the cache ──────────────────────────
  console.log(`[WhatsApp] Conversation ${force ? "FORCED" : "cache miss"} for ${phone}. Loading from DB...`);
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

    // HIGH-05: Clear stale cart items selectively (older than 24 hours)
    if (result.cart && Array.isArray(result.cart) && result.cart.length > 0) {
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const hasStaleItems = result.cart.some((item) => {
        if (!item.createdAt) return false;
        return new Date(item.createdAt) < oneDayAgo;
      });

      if (hasStaleItems) {
        console.log(`[WhatsApp] Clearing stale items for ${phone} (older than 24h)`);
        void db.whatsAppCartItem.deleteMany({ 
          where: { 
            phone, 
            createdAt: { lt: oneDayAgo } 
          } 
        }).catch(() => null);

        // Keep fresh items in memory
        result.cart = result.cart.filter((item) => {
          if (!item.createdAt) return true;
          return new Date(item.createdAt) >= oneDayAgo;
        });
      }
    }


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
  const { cart, lastActivityAt: _, ...otherExtra } = extra;

  // Return the promise so it can be awaited by the caller
  return withTimeout(
    db.whatsAppConversation.update({
      where: { phone },
      data: { state, lastMessageAt: new Date(), lastActivityAt: new Date(), ...otherExtra },
    }),
    DB_TIMEOUT
  ).catch((e) => {
    console.error(`[WhatsApp] updateState DB write failed for ${phone}:`, e);
    // Don't throw here to avoid crashing the whole flow, but log clearly
  });
}


// ─── Cart Helpers ─────────────────────────────────────────────────────────

async function addToCart(phone: string, item: { cakeName: string; size: string; price: number; quantity: number }) {

  try {
    const existingItem = await db.whatsAppCartItem.findFirst({
      where: { phone, cakeName: item.cakeName, size: item.size },
    });

    let resultItem;
    if (existingItem) {
      resultItem = await db.whatsAppCartItem.update({
        where: { id: existingItem.id },
        data: { quantity: { increment: item.quantity } },
      });
    } else {
      resultItem = await db.whatsAppCartItem.create({
        data: { ...item, phone },
      });
    }


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

async function removeLastItem(phone: string) {
  try {
    const cached = convoCache.get(phone);
    const cart = cached?.cart ?? [];
    if (cart.length === 0) return;

    const lastItem = cart[cart.length - 1];
    if (!lastItem) return;

    await db.whatsAppCartItem.delete({ where: { id: lastItem.id } });
    
    if (cached) {
      cached.cart = cart.slice(0, -1);
      convoCache.set(phone, cached);
    }
    return lastItem.cakeName;
  } catch (e) {
    console.error("[WhatsApp] removeLastItem failed:", e);
    return null;
  }
}

function getCartTotal(cart: CartItem[]): number {
  let total = 0;
  for (const item of cart) {
    total += item.price * (item.quantity || 1);
  }
  return total;
}


function formatItemTotal(price: number, quantity: number): string {
  if (price === 0) return "Pending Quote";
  return formatPrice(price * quantity);
}


async function reverseGeocode(lat: number, lon: number): Promise<string | undefined> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 5000); // Enforce 5s timeout

  try {
    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lon}&zoom=18&addressdetails=1`,
      {
        signal: controller.signal,
        headers: {
          "User-Agent": "SonnasPatisserieBot/1.0",
        },
      }
    );
    const data = await response.json() as { display_name: string };
    return data.display_name ?? undefined;
  } catch (e) {
    if (e instanceof Error && e.name === "AbortError") {
      console.warn(`[WhatsApp] reverseGeocode timed out for ${lat},${lon}`);
    } else {
      console.error("[WhatsApp] reverseGeocode failed:", e);
    }
    return undefined;
  } finally {
    clearTimeout(timeoutId);
  }
}


function getCartSummary(cart: CartItem[]): string {
  if (!cart || cart.length === 0) return "Your cart is empty.";
  let summary = `\u2728 *Your Selection*\n\n`;
  cart.forEach((item, idx) => {
    const displayPrice = formatItemTotal(item.price, item.quantity);
    summary += `${idx + 1}. *${item.cakeName}* (${item.size})${item.quantity > 1 ? ` x${item.quantity}` : ""} \u2014 ${displayPrice}\n`;
  });
  summary += `\n*Total: ${formatPrice(getCartTotal(cart))}*`;

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
  summary += `\n*Total: ${formatPrice(getCartTotal(cart))}*\n`;

  summary += `📍 Address: ${convo.selectedAddress ?? "_Not provided_"}\n`;
  summary += `📝 Notes: ${convo.selectedNotes ?? "_None_"}\n`;
  summary += `📅 Delivery: *${convo.selectedDeliveryDate ?? "Today"}*\n`;
  summary += `🕒 Timing: *${convo.selectedDeliveryTime ?? "Anytime"}*\n\n`;
  summary += `\n\nShall we prepare this for you?`;
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
      totalPrice: null,
      notes,
      status: "PENDING",
      isCustom: true,
      customImageUrl: imageUrl,
      items: {
        create: [{
          cakeName: "CUSTOM_CAKE",
          size: "Custom Design",
          price: 0,
          quantity: 1
        }]
      }

    }
  });

  await updateState(msg.from, "IDLE", {
    ...RESET_STATE,
    selectedNotes: (convo.selectedNotes ?? "") + "\n[Reference Image Attached] " + caption,
  });

  return orderNumber;
}

async function isBotPaused(): Promise<boolean> {
  try {
    const setting = await db.whatsAppSetting.findUnique({
      where: { key: "MAINTENANCE_MODE" }
    });
    return setting?.value === "true";
  } catch {
    return false;
  }
}

// ─── Main handler ──────────────────────────────────────────────────────────

export async function handleIncomingMessage(msg: IncomingMessage) {
  const phone = msg.from;

  // ── Message Deduplication (HIGH-07) ──────────────────────────────────────
  if (!beginMessageProcessing(msg.messageId)) {
    console.log(`[WhatsApp] ⚡ Duplicate or In-Flight message ${msg.messageId} skipped.`);
    return;
  }

  // ── Concurrency Lock — properly chained (HIGH-02) ───────────────────────
  const existingLock = processingLocks.get(phone) ?? Promise.resolve();

  const processPromise = existingLock.then(async () => {
    try {
      // Check Maintenance Mode (allow status requests)
      const normalizedText = msg.text?.trim().toLowerCase();
      const isStatusRequest =
        normalizedText === "status" ||
        normalizedText === "my order" ||
        normalizedText === "order status" ||
        msg.interactiveId === "btn_status";

      if (await isBotPaused() && !isStatusRequest) {
        await sendTextMessage(
          msg.from, 
          "\ud83c\udf38 *Sonna's Patisserie is currently resting.*\n\nOur artisan kitchen is taking a short break to prepare for upcoming collections. We'll be back shortly to delight you! \u2728\n\n_If you have an existing order, don't worry \u2014 our team is still working on it!_"
        );
        return;
      }

      await refreshActivity(phone);
      await _internalHandleMessage(msg);
      
      // Only mark as processed after successful handling
      markMessageProcessed(msg.messageId);
    } catch (err) {
      console.error(`[WhatsApp] Processing error for ${phone}:`, err);
      // We DON'T mark as processed here, so WhatsApp can retry
    } finally {
      // Always clear in-flight tracking
      inFlightMessages.delete(msg.messageId);
    }
  });


  processingLocks.set(phone, processPromise);

  // Clean up lock after processing completes
  void processPromise.then(() => {
    // Only delete if this is still the latest promise in the chain
    if (processingLocks.get(phone) === processPromise) {
      processingLocks.delete(phone);
    }
  });

  return processPromise;
}

async function refreshActivity(phone: string) {
  void db.whatsAppConversation.update({
    where: { phone },
    data: { lastActivityAt: new Date() }
  }).catch(() => null);
  
  const cached = convoCache.get(phone);
  if (cached) {
    cached.lastActivityAt = new Date();
    convoCache.set(phone, cached);
  }
}

async function getSessionTimeoutMins(): Promise<number> {
  try {
    const setting = await db.whatsAppSetting.findUnique({
      where: { key: "SESSION_TIMEOUT_MINS" }
    });
    return setting ? parseInt(setting.value) : 60;
  } catch {
    return 60;
  }
}

async function _internalHandleMessage(msg: IncomingMessage) {
  let convo = await getConversation(msg.from, msg.name);
  let state = convo.state as ConversationState;

  // ── Session Timeout Check ────────────────────────────────────────────────
  if (state !== "IDLE" && convo.lastActivityAt) {
    const lastActivity = new Date(convo.lastActivityAt).getTime();
    const timeoutMins = await getSessionTimeoutMins();
    
    if (Date.now() - lastActivity > timeoutMins * 60 * 1000) {
      console.log(`[WhatsApp] Session timeout for ${msg.from} (${timeoutMins}m). Resetting.`);
      await Promise.all([
        clearCart(msg.from),
        updateState(msg.from, "IDLE", RESET_STATE),
      ]);
      await sendTextMessage(msg.from, "Your previous session timed out due to inactivity. Starting fresh for you! ✨");
      
      // Reload conversation with fresh state
      convo = await getConversation(msg.from, msg.name, true);
      state = convo.state as ConversationState;
    }
  }

  // ── Integrity Check: Catch "Zombie" States ──────────────────────────────
  const statesRequiringCake: ConversationState[] = ["SELECTING_SIZE", "SELECTING_QUANTITY"];
  if (statesRequiringCake.includes(state) && !convo.selectedCake) {
    console.warn(`[WhatsApp] Integrity Check Failed: ${msg.from} is in ${state} but no cake is selected. Healing...`);
    await updateState(msg.from, "IDLE", RESET_STATE);
    state = "IDLE";
    convo = await getConversation(msg.from, msg.name, true);
  }

  const input = msg.text?.trim().toLowerCase() ?? "";
  const interactiveId = msg.interactiveId ?? "";

  console.log(`[WhatsApp] Processing from ${msg.from}: ${input || interactiveId} (State: ${state})`);
  const isGreeting = GREETINGS.includes(input);

  if (isGreeting) {
    if (state === "IDLE") {
      await sendWelcome(msg.from, msg.name);
    } else {
      // MED-12: Single combined message instead of greeting + re-prompt
      await rePromptState(msg.from, state, convo);
    }
    return;
  }

  if (input === "restart" || input === "start over" || input === "reset") {
    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, "IDLE", RESET_STATE),
    ]);
    await sendTextMessage(msg.from, "No worries! Everything's been cleared. \u2728\n\nWhenever you're ready, I'm here to help you find the perfect cake. \ud83c\udf38");
    await sendWelcome(msg.from, msg.name);
    await sendMenuPDF(msg.from);
    return;
  }

  if (input === "help") {
    await sendWelcome(msg.from, msg.name);
    await sendMenuPDF(msg.from);
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

      const options = selectedProduct.options ?? [];
      if (options.length > 2) {
        // Use List Message for better UX when there are many sizes
        tasks.push(sendInteractiveList(
          msg.from,
          "Size Selection",
          `Hi ${msg.name ?? "there"}! 👋\n\nGreat choice! Choose your size for *${selectedProduct.name}*:`,
          "Select Size",
          [{
            title: "Available Sizes",
            rows: options.map((opt, idx) => ({
              id: `size_${idx}`,
              title: opt.size,
              description: formatPrice(opt.price)
            }))
          }]
        ));
      } else {
        // Use Buttons
        const buttons = options.map((opt, idx) => ({
          id: `size_${idx}`,
          title: `${opt.size} — ${formatPrice(opt.price)}`,
        }));
        buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });

        tasks.push(sendInteractiveButtons(
          msg.from,
          `Hi ${msg.name ?? "there"}! 👋\n\nGreat choice! Choose your size for *${selectedProduct.name}*:`,
          buttons
        ));
      }

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
        selectedPrice: 0,
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
        selectedPrice: 0,
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
      sendTextMessage(msg.from, "✨ *Selection cleared!*"),
    ]);
    await sendMenu(msg.from);
    await sendMenuPDF(msg.from);
    return;
  }

  if (input === "cancel" || input === "cancel order" || interactiveId === "btn_cancel") {
    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, "IDLE", RESET_STATE),
    ]);
    await sendTextMessage(msg.from, "Got it! Your order has been cleared. ✅\n\nWhenever you're craving something special, just say *HI* or *Menu* to see what's baking today! 🍰");
    return;
  }



  // ── Global Interactive ID handling (Resilience for old messages) ───────
  if (interactiveId === "btn_back") {
    // Smart Back Navigation
    let targetState: ConversationState = "IDLE";

    switch (state) {
      case "SELECTING_SIZE": {
        targetState = "BROWSING_MENU";
        break;
      }
      case "SELECTING_QUANTITY": {
        targetState = "SELECTING_SIZE";
        break;
      }
      case "ASKING_ADDRESS": {
        // Back from address selection goes to Cart View
        await updateState(msg.from, "IDLE");
        const updatedConvo = convoCache.get(msg.from) ?? convo;
        const summary = getCartSummary(updatedConvo.cart ?? []);
        await sendInteractiveButtons(msg.from, summary, [
          { id: "btn_checkout", title: "\ud83d\udcb3 Place My Order" },
          { id: "btn_menu", title: "\u2795 Add More" },
          { id: "btn_clear_cart", title: "\ud83d\udd04 Start Fresh" },
        ]);
        return;
      }
      case "ASKING_INSTRUCTIONS": {
        // If pickup, go back to pickup/delivery choice. If delivery, go back to address.
        if (convo.selectedAddress === "🏪 Store Pickup") {
          await updateState(msg.from, "ASKING_ADDRESS");
          await sendInteractiveButtons(
            msg.from,
            "\ud83c\udfe0 *How would you like to receive your order?*",
            [
              { id: "btn_delivery", title: "\ud83d\ude9a Delivery" },
              { id: "btn_pickup", title: "\ud83c\udfea Store Pickup" },
            ]
          );
        } else {
          targetState = "ASKING_ADDRESS";
        }
        break;
      }
      case "ASKING_DELIVERY_DATE": {
        targetState = "ASKING_INSTRUCTIONS";
        break;
      }
      case "ASKING_DELIVERY_TIME": {
        targetState = "ASKING_DELIVERY_DATE";
        break;
      }
      case "CONFIRMING": {
        targetState = "ASKING_DELIVERY_TIME";
        break;
      }
      default: {
        targetState = "IDLE";
      }
    }


    if (targetState === "IDLE") {
      await sendWelcome(msg.from, msg.name);
    } else {
      await updateState(msg.from, targetState);
      await rePromptState(msg.from, targetState, convo);
    }
    return;
  }

  if (interactiveId === "btn_remove_last") {
    const removedName = await removeLastItem(msg.from);
    if (removedName) {
      await sendTextMessage(msg.from, `\u2728 *${removedName}* has been removed from your selection.`);
    }
    const updatedConvo = convoCache.get(msg.from) ?? convo;
    const summary = getCartSummary(updatedConvo.cart ?? []);
    await sendInteractiveButtons(msg.from, summary, [
      { id: "btn_checkout", title: "\ud83d\udcb3 Place My Order" },
      { id: "btn_menu", title: "\u2795 Add More" },
      { id: "btn_clear_cart", title: "\ud83d\udd04 Start Fresh" },
    ]);
    return;
  }

  if (interactiveId === "btn_pickup") {
    await Promise.all([
      updateState(msg.from, "ASKING_INSTRUCTIONS", { selectedAddress: "🏪 Store Pickup" }),
      sendInteractiveButtons(
        msg.from,
        "\u2728 *Store Pickup Selected*\n\nWhat message would you like on your cake?\n\nReply *Skip* if none.",
        [{ id: "btn_back", title: "⬅️ Back" }]
      )
    ]);
    return;
  }

  if (interactiveId === "saved_addr_yes") {
    try {
      const lastOrder = await db.whatsAppOrder.findFirst({
        where: { phone: msg.from, status: { not: "CANCELLED" }, address: { not: null } },
        orderBy: { createdAt: "desc" },
        select: { address: true }
      });
      if (lastOrder?.address) {
        await Promise.all([
          updateState(msg.from, "ASKING_INSTRUCTIONS", { selectedAddress: lastOrder.address }),
          sendInteractiveButtons(
            msg.from,
            `\u2705 *Address set!* (\ud83d\udccd Previous used)\n\n\u270d\ufe0f *Personalize Your Cake*\n\nWhat message would you like on your cake?`,
            [{ id: "btn_back", title: "⬅️ Back" }]
          )
        ]);
        return;
      }
    } catch (err) {
      console.error("[WhatsApp] Error applying saved address:", err);
    }
  }

  if (interactiveId === "btn_delivery") {
    await Promise.all([
      updateState(msg.from, "ASKING_ADDRESS"),
      sendTextMessage(msg.from, "\ud83d\udccd *Delivery Address*\n\nPlease share your delivery address or tap the \ud83d\udcce icon to send your *GPS Location*.")
    ]);
    return;
  }

  if (interactiveId.startsWith("cake_")) {
    await handleCakeSelection(msg);
    return;
  }
  if (interactiveId.startsWith("size_")) {
    await handleSizeSelection(msg, convo);
    return;
  }
  if (interactiveId.startsWith("slot_")) {
    await handleDeliverySlotSelection(msg, convo);
    return;
  }

  // ── Global: Image sent outside custom flow (MED-11) ───────────────────
  if (msg.type === "image" && state !== "REQUESTING_CUSTOM" && state !== "UPLOADING_REFERENCE_IMAGE") {
    await sendInteractiveButtons(
      msg.from,
      "\ud83d\udcf8 Beautiful photo! If you'd like us to create a custom cake based on this design, tap below:",
      [
        { id: "btn_custom", title: "\ud83c\udfa8 Start Custom Order" },
        { id: "btn_menu", title: "\ud83d\udccb Browse Menu" },
      ]
    );
    return;
  }

  // ── Global: Location sent outside address flow (HIGH-09) ─────────────
  if (msg.type === "location" && state !== "ASKING_ADDRESS") {
    // Save location for later use
    if (msg.location) {
      const mapsUrl = `https://www.google.com/maps?q=${msg.location.latitude},${msg.location.longitude}`;
      const addr = msg.location.address ?? msg.location.name ?? `GPS: ${msg.location.latitude}, ${msg.location.longitude}`;
      await updateState(msg.from, state as ConversationState, { selectedAddress: `${addr}\n\ud83d\udd17 ${mapsUrl}` });
    }
    await sendTextMessage(msg.from, "\ud83d\udccd Location saved! I'll use this when you're ready to place an order. \u2728\n\nReply *Menu* to browse our cakes!");
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

    case "SELECTING_QUANTITY":
      await handleQuantitySelection(msg, convo);
      break;

    case "ASKING_ADDRESS":
      await handleAddressInput(msg, convo);
      break;

    case "ASKING_INSTRUCTIONS":
      await handleInstructionsInput(msg, convo);
      break;

    case "ASKING_DELIVERY_DATE":
      await handleDeliverySlotSelection(msg, convo);
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
  // CVR-04: Check for returning customers
  try {
    const lastOrder = await db.whatsAppOrder.findFirst({
      where: { phone: to, status: { not: "CANCELLED" } },
      orderBy: { createdAt: "desc" },
      select: {
        items: { select: { cakeName: true }, take: 1 },
        createdAt: true,
      },
    });

    if (lastOrder?.items[0]) {
      const cakeName = lastOrder.items[0].cakeName;
      const greeting = name ? `Welcome back, ${name}! ✨` : "Welcome back! ✨";
      await sendInteractiveButtons(
        to,
        `${greeting}\n\nSo lovely to see you again at *Sonna's Patisserie*! 🌸\n\nWould you like to reorder your *${cakeName}*, or explore something new?\n\n💡 *Quick Tips:*\n• Reply *Menu* to browse all cakes\n• Reply *Status* to see order history\n• Reply *Cancel* to start over`,
        [
          { id: `cake_${cakeName}`, title: "🔄 Reorder Last" },
          { id: "btn_menu", title: "📋 Browse Cakes" },
          { id: "btn_custom", title: "🎨 Custom Creation" },
        ]
      );
      await sendMenuPDF(to);
      return;
    }
  } catch {
    // Fall through to default welcome if DB query fails
  }

  const greeting = name ? `Hi ${name}! ✨` : "Welcome! ✨";
  const cakes = await safeGetCakes();
  const topCakes = cakes.slice(0, 3);
  
  // Get unique categories for the browse section
  const categories = Array.from(new Set(cakes.map(c => c.category).filter(Boolean))) as string[];

  await sendInteractiveList(
    to,
    "Sonna's Patisserie",
    `${greeting}\n\nWelcome to *Sonna's Patisserie*\n_Where every dessert is a handcrafted masterpiece._\n\nHow can we delight you today? \ud83c\udf38`,
    "View Menu",
    [
      {
        title: "⭐ Top Favorites",
        rows: topCakes.map(c => ({
          id: `cake_${c.name}`,
          title: c.name.length > 24 ? c.name.substring(0, 21) + "..." : c.name,
          description: `Signature Selection`
        }))
      },
      {
        title: "📋 Browse by Category",
        rows: categories.slice(0, 5).map(cat => ({
          id: `cat_${cat}`,
          title: cat.length > 24 ? cat.substring(0, 21) + "..." : cat
        }))
      },
      {
        title: "✨ Other Services",
        rows: [
          { id: "btn_custom", title: "🎨 Custom Creation", description: "Design your own cake" },
          { id: "btn_status", title: "📦 Track My Order", description: "Check your history" }
        ]
      }
    ]
  );
  await sendMenuPDF(to);
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
    const cheesecakes = cakes.filter((p) => p.category === "Mini Cheesecakes");
    const slices = cakes.filter((p) => p.category === "Slices");

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
    if (cheesecakes.length > 0) {
      sections.push({
        title: "🧁 Mini Cheesecakes",
        rows: cheesecakes.map(cakeRow),
      });
    }
    if (slices.length > 0) {
      sections.push({
        title: "🍰 Slices",
        rows: slices.map(cakeRow),
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
            { id: "cat_cheesecakes", title: "🧁 Mini Cheesecakes", description: "Bite-sized delights" },
            { id: "cat_slices", title: "🍰 Slices", description: "Perfect cake portions" },
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
  description: `From ${formatPrice(c.options?.[0]?.price ?? 75000)}`,
});

// ─── Handle category selection ─────────────────────────────────────────────

async function handleCategorySelection(msg: IncomingMessage) {
  const category = msg.interactiveId?.replace("cat_", "") as
    | "chocolate"
    | "vanilla"
    | "cheesecakes"
    | "slices"
    | "tea"
    | "seasonal";

  if (!category || !["chocolate", "vanilla", "cheesecakes", "slices", "tea", "seasonal"].includes(category)) {
    await sendMenu(msg.from);
    return;
  }

  const categoryMap: Record<string, string> = {
    chocolate: "Chocolate Cakes",
    vanilla: "Vanilla Cakes",
    cheesecakes: "Mini Cheesecakes",
    slices: "Slices",
    tea: "Tea Cakes",
    seasonal: "Seasonal Cakes",
  };

  const titles: Record<string, string> = {
    chocolate: "🍫 Chocolate Based",
    vanilla: "🍦 Vanilla & Fruit Based",
    cheesecakes: "🧁 Mini Cheesecakes",
    slices: "🍰 Slices",
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
    selectedProduct = await findCake(msg.interactiveId.replace("cake_", ""));
  }

  if (!selectedProduct && msg.text) {
    selectedProduct = await findCake(msg.text);
  }

  if (!selectedProduct) {
    await sendInteractiveButtons(
      msg.from,
      "Hmm, I couldn't quite match that to our menu. \ud83e\uddc1\n\nLet me show you our full collection \u2014 you might find something even more tempting!",
      [
        { id: "btn_menu", title: "\ud83d\udccb View Our Menu" },
        { id: "btn_custom", title: "\ud83c\udfa8 Custom Creation" },
      ]
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
  if (options.length > 2) {
    tasks.push(sendInteractiveList(
      msg.from,
      "Size Selection",
      `Choose your size for *${selectedProduct.name}*:`,
      "Select Size",
      [{
        title: "Available Sizes",
        rows: options.map((opt, idx) => ({
          id: `size_${idx}`,
          title: opt.size,
          description: formatPrice(opt.price)
        }))
      }]
    ));
  } else {
    const buttons = options.map((opt, idx) => {
      const title = `${opt.size} — ${formatPrice(opt.price)}`;
      return {
        id: `size_${idx}`,
        title: title.length > 20 ? title.substring(0, 17) + "..." : title,
      };
    });
    buttons.push({ id: "btn_menu", title: "📋 Back to Menu" });

    tasks.push(sendInteractiveButtons(
      msg.from,
      `Choose your size for *${selectedProduct.name}*:`,
      buttons
    ));
  }

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
    await sendTextMessage(msg.from, "Oops! I seem to have lost track of which cake you were looking at. 🧁\n\nStarting fresh for you! Please select a cake from the menu below.");
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
        input.includes(formatPrice(opt.price).toLowerCase())
    );
  }

  if (!selectedOption) {
    await sendTextMessage(
      msg.from,
      "Please select a valid size option, or reply *Cancel* to start over."
    );
    return;
  }

  // Skip quantity selection and default to 1 for speed
  const updatedConvo = {
    ...convo,
    selectedSize: selectedOption.size,
    selectedPrice: selectedOption.price,
    selectedQuantity: 1,
  };

  await updateState(msg.from, "SELECTING_QUANTITY", {
    selectedSize: selectedOption.size,
    selectedPrice: selectedOption.price,
    selectedQuantity: 1,
  });

  await handleCartActions(msg, updatedConvo as Conversation);
}

// ─── Handle quantity selection ─────────────────────────────────────────────

async function handleQuantitySelection(
  msg: IncomingMessage,
  convo: Conversation
) {
  let quantity = 1;

  if (msg.interactiveId?.startsWith("qty_")) {
    quantity = parseInt(msg.interactiveId.replace("qty_", ""), 10);
  } else if (msg.text) {
    const validation = validateAndSanitize("quantity", msg.text);
    if (!validation.success) {
      if (GREETINGS.includes(msg.text.toLowerCase())) return;
      await sendTextMessage(msg.from, `⚠️ ${validation.error}. Please enter a number between 1 and 20.`);
      return;
    }
    quantity = validation.data as number;
  }

  await updateState(msg.from, "SELECTING_QUANTITY", { selectedQuantity: quantity });
  
  // Transition to Cart Actions
  await handleCartActions(msg, { ...convo, selectedQuantity: quantity } as Conversation);
}

async function handleCartActions(msg: IncomingMessage, convo: Conversation) {
  try {
    const isCheckout = msg.interactiveId === "btn_checkout" || msg.interactiveId === "btn_checkout_now";
    const hasActiveSelection = !!(convo.selectedCake && convo.selectedSize && convo.selectedPrice);

    // Case 1: Transitioning from Quantity selection, Size selection (Shortcut), OR "Add to Order" clicked
    const isAdding = !!(
      (msg.interactiveId?.startsWith("qty_") ?? false) || 
      (msg.interactiveId?.startsWith("size_") ?? false) || 
      (msg.text ?? false) || 
      (msg.interactiveId === "btn_add_to_cart")
    );

    if (isAdding && hasActiveSelection) {
      const quantity = convo.selectedQuantity ?? 1;
      await addToCart(msg.from, {
        cakeName: convo.selectedCake!,
        size: convo.selectedSize!,
        price: convo.selectedPrice!,
        quantity: quantity
      });

      // Use cache instead of forced refresh to avoid race conditions
      const updatedConvo = convoCache.get(msg.from) ?? (await getConversation(msg.from));
      const summary = getCartSummary(updatedConvo.cart ?? []);


      const cartButtons = [
        { id: "btn_checkout", title: "💳 Place My Order" },
        { id: "btn_menu", title: "➕ Add More" },
      ];
      
      if (updatedConvo.cart && updatedConvo.cart.length > 1) {
        cartButtons.push({ id: "btn_remove_last", title: "❌ Remove Last" });
      } else {
        cartButtons.push({ id: "btn_clear_cart", title: "🔄 Start Fresh" });
      }

      await Promise.all([
        sendTextMessage(msg.from, `✨ *${convo.selectedCake}* added to your order!`),
        sendInteractiveButtons(msg.from, summary, cartButtons),
        updateState(msg.from, "IDLE", { 
          selectedCake: null, 
          selectedSize: null, 
          selectedPrice: null, 
          selectedQuantity: null 
        })
      ]);
      return;
    }

    // Case 2: "Confirm Order" (btn_checkout) clicked from the cart summary (no active selection)
    if (isCheckout) {
      console.log(`[WhatsApp] CHECKOUT_START: ${msg.from}`);
      const updatedConvo = await getConversation(msg.from, undefined, true);
      const cart = updatedConvo.cart ?? [];

      if (cart.length === 0) {
        console.warn(`[WhatsApp] CHECKOUT_FAIL: Empty cart for ${msg.from}`);
        await sendTextMessage(msg.from, "Your selection is empty! Let me show you our cakes 🧁");
        await sendMenu(msg.from);
        return;
      }

      // Check for saved address
      try {
        const lastOrder = await db.whatsAppOrder.findFirst({
          where: { phone: msg.from, status: { not: "CANCELLED" }, address: { not: null } },
          orderBy: { createdAt: "desc" },
          select: { address: true }
        });

        if (lastOrder?.address && !lastOrder.address.includes("Store Pickup")) {
          await sendInteractiveButtons(
            msg.from,
            `\ud83d\udccd *Would you like to use your previous address?*\n\n_${lastOrder.address.split('\n')[0]}_`,
            [
              { id: `saved_addr_yes`, title: "\u2705 Use Previous" },
              { id: "btn_delivery", title: "\ud83d\ude9a New Address" },
              { id: "btn_pickup", title: "\ud83c\udfea Store Pickup" },
            ]
          );
          await updateState(msg.from, "ASKING_ADDRESS");
          return;
        }
      } catch (err) {
        console.error("[WhatsApp] Error fetching saved address:", err);
      }

      // Default: Offer pickup or delivery choice
      await Promise.all([
        updateState(msg.from, "ASKING_ADDRESS"),
        sendInteractiveButtons(
          msg.from,
          "\ud83c\udfe0 *How would you like to receive your order?*",
          [
            { id: "btn_delivery", title: "\ud83d\ude9a Delivery" },
            { id: "btn_pickup", title: "\ud83c\udfea Store Pickup" },
            { id: "btn_back", title: "⬅️ Back" },
          ]
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
    await sendTextMessage(msg.from, "Could you share a bit more detail? \ud83d\udccd\n\nA full address with building name and landmark helps our delivery team find you perfectly! \ud83c\udfe0");
    return;
  }

  // Validate and Sanitize address
  const validation = validateAndSanitize("address", address);
  if (!validation.success) {
    await sendTextMessage(msg.from, `⚠️ ${validation.error}`);
    return;
  }
  address = validation.data as string;

  // Move to asking instructions
  await Promise.all([
    updateState(msg.from, "ASKING_INSTRUCTIONS", {
      selectedAddress: address,
    }),
    sendInteractiveButtons(
      msg.from,
      "\u2728 *Address saved!*\n\n\u270d\ufe0f *Personalize Your Cake*\n\nWhat message would you like on your cake?\n_(e.g., \"Happy Birthday Priya! \ud83c\udf89\")_\n\nReply *Skip* if no message needed.",
      [
        { id: "btn_back", title: "⬅️ Back" },
      ]
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

  if (!isSkip && (input.length < 2 || GREETINGS.includes(input.toLowerCase()))) {
    await sendTextMessage(msg.from, "What message would you like on your cake? \u270d\ufe0f\n\n_(e.g., \"Happy Birthday Priya!\")_\n\nReply *Skip* if none.");
    return;
  }

  // Validate and Sanitize notes
  let notes = isSkip ? null : input;
  if (notes) {
    const validation = validateAndSanitize("notes", notes);
    if (!validation.success) {
      await sendTextMessage(msg.from, `⚠️ ${validation.error}`);
      return;
    }
    notes = (validation.data as string) ?? null;
  }

  // Move to asking delivery slot
  await Promise.all([
    updateState(msg.from, "ASKING_DELIVERY_DATE", {
      selectedNotes: notes,
    }),
    sendDeliverySlotOptions(msg.from)
  ]);
  
  // Send a separate Back button since the list doesn't have one
  await sendInteractiveButtons(msg.from, "_Need to change something?_", [
    { id: "btn_back", title: "⬅️ Back" },
  ]);
}

// ─── Send delivery date options ────────────────────────────────────────────

function getAvailableSlots() {
  const slots: Array<{ id: string; title: string; description: string }> = [];
  // Convert current UTC time to IST (UTC + 5.5 hours)
  const now = new Date();
  const today = new Date(now.getTime() + (5.5 * 60 * 60 * 1000));
  
  // Define standard time windows
  const windows = [
    { id: "morning", title: "Morning", time: "10 AM - 1 PM", startHour: 10 },
    { id: "afternoon", title: "Afternoon", time: "2 PM - 5 PM", startHour: 14 },
    { id: "evening", title: "Evening", time: "6 PM - 9 PM", startHour: 18 },
  ];

  // Look ahead 4 days
  for (let i = 0; i < 4; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() + i);
    const dayLabel = i === 0 ? "Today" : i === 1 ? "Tomorrow" : d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric" });
    const dateKey = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, "0")}-${d.getDate().toString().padStart(2, "0")}`;

    for (const win of windows) {
      // If it's today, only show future slots (with a 2-hour buffer for baking)
      if (i === 0 && today.getHours() + 2 >= win.startHour) continue;

      slots.push({
        id: `slot_${dateKey}_${win.id}`,
        title: `${dayLabel} (${win.title})`,
        description: win.time
      });
    }
  }

  return slots.slice(0, 10); // Max 10 rows for WhatsApp List
}

async function sendDeliverySlotOptions(to: string) {
  const slots = getAvailableSlots();
  
  await sendInteractiveList(
    to,
    "🕒 Delivery Timing",
    "When should we bring your treats? 🧁\n\nPlease select a convenient delivery slot:",
    "View Slots",
    [{
      title: "Available Slots",
      rows: slots
    }]
  );
}

// ─── Handle combined delivery slot selection ────────────────────────────────

async function handleDeliverySlotSelection(
  msg: IncomingMessage,
  convo: Conversation
) {
  let deliveryDate = "";
  let deliveryTime = "";

  if (msg.interactiveId?.startsWith("slot_")) {
    const parts = msg.interactiveId.split("_"); // slot, 2024-05-13, morning
    const datePart = parts[1];
    const timePart = parts[2];

    if (!datePart || !timePart) return;

    const dateNumbers = datePart.split("-").map(Number);
    const [year, month, day] = dateNumbers;

    if (year === undefined || month === undefined || day === undefined || isNaN(year) || isNaN(month) || isNaN(day)) {
      return;
    }

    const d = new Date(year, month - 1, day);
    
    deliveryDate = d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short", year: "numeric" });
    deliveryTime = timePart.charAt(0).toUpperCase() + timePart.slice(1); // "Morning", etc.
  } else if (msg.text?.trim()) {
    deliveryDate = "As specified";
    deliveryTime = msg.text.trim();
  } else {
    await sendTextMessage(msg.from, "Please select a delivery slot from the list.");
    return;
  }

  try {
    // Move to confirmation
    await updateState(msg.from, "CONFIRMING", {
      selectedDeliveryDate: deliveryDate,
      selectedDeliveryTime: deliveryTime,
    });

    const cart = convoCache.get(msg.from)?.cart ?? [];
    const currentConvo = convoCache.get(msg.from) ?? convo;

    await sendInteractiveButtons(
      msg.from,
      buildOrderSummary(cart, currentConvo),
      [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_back", title: "⬅️ Back" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]
    );
  } catch (err) {
    console.error("[WhatsApp] Error in handleDeliverySlotSelection:", err);
    await sendTextMessage(msg.from, "⚠️ Sorry, I encountered an error. Please try again.");
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

    const orderNumber = await createCustomOrder(msg, convo, publicUrl ?? undefined, msg.image.id, msg.image.caption ?? "");

    await sendInteractiveButtons(
      msg.from,
      `📸 *Reference Photo Received!* 🍰\n\nYour request has been logged as *#${orderNumber}*.\n\nOur team will review your design and call you shortly to provide a quote and confirm details. 📞\n\nWould you like to explore our signature cakes while you wait?`,
      [
        { id: "btn_menu", title: "📋 View Menu" },
        { id: "btn_status", title: "📦 My Orders" },
      ]
    );
    return;
  }

  // If user sends text (description)
  if (msg.type === "text" && msg.text) {
    const text = msg.text.trim();

    // Sanitize and validate
    const validation = validateAndSanitize("notes", text);
    if (!validation.success) {
      await sendTextMessage(msg.from, `⚠️ ${validation.error}`);
      return;
    }
    const sanitizedText = (validation.data as string) ?? "";

    // If text looks like an address (has numbers and multiple words), or we already have notes, move to address collection
    const looksLikeAddress = /\d+/.test(sanitizedText) && sanitizedText.split(/\s+/).length > 3;
    
    if (looksLikeAddress || convo.selectedNotes) {
      await Promise.all([
        updateState(msg.from, "ASKING_ADDRESS", {
          selectedAddress: sanitizedText
        }),
        sendTextMessage(
          msg.from,
          "📍 *Address received!* \n\nPlease share a **Reference Photo** 📸 to help us understand your design better."
        )
      ]);
    } else {
      await Promise.all([
        updateState(msg.from, "REQUESTING_CUSTOM", {
          selectedNotes: sanitizedText
        }),
        sendTextMessage(
          msg.from,
          "✅ Description received! 📝\n\nSend a **Reference Photo** 📸 or reply with your **Delivery Address** to proceed."
        )
      ]);
    }
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

    const orderNumber = await createCustomOrder(msg, convo, publicUrl ?? undefined, msg.image.id, msg.image.caption ?? "");

    await sendInteractiveButtons(
      msg.from,
      `📸 *Reference Photo Received!* 🍰\n\nYour request has been logged as *#${orderNumber}*.\n\nOur team will review your design and call you shortly to provide a quote and confirm details. 📞\n\nWould you like to explore our signature cakes while you wait?`,
      [
        { id: "btn_menu", title: "📋 View Menu" },
        { id: "btn_status", title: "📦 My Orders" },
      ]
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
    await sendInteractiveButtons(
      to,
      "You haven't placed an order yet \u2014 let's change that! \ud83e\uddc1\n\nBrowse our handcrafted collection and treat yourself to something special.",
      [
        { id: "btn_menu", title: "\ud83d\udccb Browse Our Cakes" },
        { id: "btn_custom", title: "\ud83c\udfa8 Custom Creation" },
      ]
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
      const qtyStr = item.quantity > 1 ? ` (x${item.quantity})` : "";
      const displayPrice = formatItemTotal(item.price, item.quantity);
      statusText += `   🎂 ${item.cakeName} (${item.size})${qtyStr} — ${displayPrice}\n`;
    });

    statusText += `   💰 Total: ${formatPrice(order.totalPrice ?? 0)}\n`;


    statusText += `   Status: *${order.status}*\n`;
    statusText += `   Placed: ${order.createdAt.toLocaleDateString("en-IN")}\n\n`;
  }

  statusText += "Reply *Menu* to order more! 🧁";

  await sendTextMessage(to, statusText);
}

// ─── Handle confirmation (Robust Version v2) ───────────────────────────────

async function handleConfirmation(
  msg: IncomingMessage,
  convo: Conversation
) {
  try {
    console.log(`[WhatsApp] handleConfirmation: Start for ${msg.from}`);
    const isConfirm =
      msg.interactiveId === "btn_confirm" ||
      msg.text?.toLowerCase() === "yes" ||
      msg.text?.toLowerCase() === "confirm";

    const isCancel =
      msg.interactiveId === "btn_cancel" ||
      msg.text?.toLowerCase() === "no" ||
      msg.text?.toLowerCase() === "cancel";

    if (!isConfirm && !isCancel) {
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

    // Use cached cart
    const cart = convoCache.get(msg.from)?.cart ?? convo.cart ?? [];
    if (cart.length === 0) {
      console.warn(`[WhatsApp] handleConfirmation: Cart empty for ${msg.from}`);
      await updateState(msg.from, "IDLE");
      await sendTextMessage(msg.from, "Your cart is empty. Let's start over — reply *Menu*.");
      return;
    }

    const orderNumber = generateOrderNumber();
    const totalAmount = getCartTotal(cart);


    console.log(`[WhatsApp] handleConfirmation: Creating order ${orderNumber} (₹${totalAmount})`);

    // Fetch fresh convo to ensure address/notes are latest
    const freshConvo = convoCache.get(msg.from) ?? (await getConversation(msg.from));

    // 1. Create DB Order first (Durable Storage)
    const dbOrder = await db.whatsAppOrder.create({
      data: {
        orderNumber,
        phone: msg.from,
        customerName: freshConvo?.name ?? msg.name ?? "Customer",
        totalPrice: totalAmount,
        address: freshConvo.selectedAddress ?? null,
        notes: freshConvo.selectedNotes ?? null,
        deliveryDate: freshConvo.selectedDeliveryDate ?? null,
        deliveryTime: freshConvo.selectedDeliveryTime ?? null,
        status: "PENDING",
        paymentStatus: "PENDING",
        razorpayOrderId: "", 
        paymentLink: "",
        isCustom: cart.some((item) => item.cakeName === "CUSTOM_CAKE"),
        customImageUrl: freshConvo.customImageUrl ?? null,
        items: {
          create: cart.map((item) => ({
            cakeName: item.cakeName,
            size: item.size,
            price: item.price,
            quantity: item.quantity,
          })),
        },
      },
    });

    console.log(`[WhatsApp] handleConfirmation: DB Order created: ${dbOrder.id}`);

    // 2. Create Payment Link sequentially
    let rzpLinkResult = null;
    try {
      rzpLinkResult = await createPaymentLink({
        orderNumber,
        amount: totalAmount,
        phone: msg.from,
        name: freshConvo?.name ?? msg.name ?? "Customer",
      });
    } catch (err) {
      console.error("[WhatsApp] Razorpay Link Error:", err);
    }


    let paymentLink = "";
    if (rzpLinkResult?.short_url) {
      paymentLink = rzpLinkResult.short_url;
      // Update order with payment details
      await db.whatsAppOrder.update({
        where: { id: dbOrder.id },
        data: {
          paymentLink: rzpLinkResult.short_url,
          razorpayOrderId: rzpLinkResult.id
        },
      }).catch(e => console.error("[WhatsApp] Failed to save payment link to DB:", e));
    }

    // Cleanup
    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, "IDLE", RESET_STATE)
    ]);

    let successMessage = `🎉 *Order #${orderNumber} Placed!*\n\n`;
    successMessage += `📅 *${freshConvo.selectedDeliveryDate ?? "Today"}* | 🕒 *${freshConvo.selectedDeliveryTime ?? "Anytime"}*\n`;
    successMessage += `📍 ${freshConvo.selectedAddress ?? "Store Pickup"}\n\n`;

    if (paymentLink) {
      const bodyText = successMessage + `💳 Pay *${formatPrice(totalAmount)}* to confirm your order. ✅`;
      await sendCTAUrlButton(msg.from, bodyText, "💳 Pay Now", paymentLink);
    } else {
      successMessage += `💰 Total: *${formatPrice(totalAmount)}*\n\nWe'll contact you shortly to confirm details. 💕`;
      await sendTextMessage(msg.from, successMessage);
    }
    console.log(`[WhatsApp] handleConfirmation: Success for ${msg.from}`);


  } catch (error) {
    console.error("[WhatsApp] handleConfirmation CRASH:", error);
    await sendTextMessage(msg.from, "⚠️ Something went wrong while placing your order. Please try again or contact us directly. 🙏");
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
          if (options.length > 2) {
            await sendInteractiveList(
              phone,
              "Size Selection",
              `Choose your size for *${cake.name}*:`,
              "Select Size",
              [{
                title: "Available Sizes",
                rows: options.map((opt, idx) => ({
                  id: `size_${idx}`,
                  title: opt.size,
                  description: formatPrice(opt.price)
                }))
              }]
            );
          } else {
            const buttons = options.map((opt, idx) => ({
              id: `size_${idx}`,
              title: `${opt.size} — ${formatPrice(opt.price)}`,
            }));
            buttons.push({ id: "btn_back", title: "⬅️ Back to Menu" });
            await sendInteractiveButtons(phone, `Choose your size for *${cake.name}*:`, buttons);
          }

        } else {
          await sendMenu(phone);
        }
      } else {
        await sendMenu(phone);
      }
      break;
    case "SELECTING_QUANTITY":
      await sendInteractiveButtons(
        phone,
        `*${convo.selectedCake}* (${convo.selectedSize})\n\nHow many would you like to order? \ud83e\udde1`,
        [
          { id: "qty_1", title: "1" },
          { id: "qty_2", title: "2" },
          { id: "btn_back", title: "⬅️ Back" },
        ]
      );
      break;
    case "ASKING_ADDRESS":
      await sendInteractiveButtons(
        phone,
        "\ud83c\udfe0 *How would you like to receive your order?*",
        [
          { id: "btn_delivery", title: "\ud83d\ude9a Delivery" },
          { id: "btn_pickup", title: "\ud83c\udfea Store Pickup" },
          { id: "btn_back", title: "⬅️ Back" },
        ]
      );
      break;
    case "ASKING_INSTRUCTIONS":
      await sendInteractiveButtons(
        phone,
        "\u270d\ufe0f *Personalize Your Cake*\n\nWhat message would you like on your cake?\n\nReply *Skip* if none.",
        [
          { id: "btn_back", title: "⬅️ Back" },
         ]
      );
      break;
    case "ASKING_DELIVERY_DATE":
      await sendDeliverySlotOptions(phone);
      await sendInteractiveButtons(phone, "_Need to change something?_", [
        { id: "btn_back", title: "⬅️ Back" },
      ]);
      break;
    case "CONFIRMING": {
      // Use cached cart
      const cart = convoCache.get(phone)?.cart ?? [];
      await sendInteractiveButtons(phone, buildOrderSummary(cart, convo), [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_back", title: "⬅️ Back" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]);
      break;
    }

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
