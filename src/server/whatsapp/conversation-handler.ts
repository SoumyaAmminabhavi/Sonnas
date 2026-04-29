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

// ─── DB Helpers ─────────────────────────────────────────────────────────────

async function safeGetCakes(): Promise<Cake[]> {
  console.log("[WhatsApp] Attempting to fetch cakes from DB...");
  try {
    const result = await withTimeout(
      db.cake.findMany({ include: { options: true } }),
      DB_TIMEOUT
    );
    return (result as unknown as Cake[]) ?? (products as unknown as Cake[]);
  } catch {
    console.warn("[WhatsApp] DB Menu fetch failed, using fallback.");
    return products as unknown as Cake[];
  }
}

async function safeGetCakeByName(name: string): Promise<Cake | null> {
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
    
    // Try local products as fallback
    const localId = parseInt(id, 10);
    const found = products.find((p) => p.id === localId || p.id.toString() === id);
    if (found) return found as unknown as Cake;
    
    // Try fuzzy match by name if id is a name? No, safeGetCakeByName handles that.
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
  try {
    let convo = await withTimeout(
      db.whatsAppConversation.findUnique({
        where: { phone },
      }),
      DB_TIMEOUT
    );

    if (!convo) {
      convo = await withTimeout(
        db.whatsAppConversation.create({
          data: { phone, name },
        }),
        DB_TIMEOUT
      );
    } else if (name && !convo.name) {
      convo = await withTimeout(
        db.whatsAppConversation.update({
          where: { phone },
          data: { name },
        }),
        DB_TIMEOUT
      );
    }

    return convo as unknown as Conversation;
  } catch {
    // Return a dummy object to allow the bot to continue with default state
    return { phone, state: "IDLE", name: name ?? "Customer" } as unknown as Conversation;
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
  } = {}
) {
  try {
    await withTimeout(
      db.whatsAppConversation.update({
        where: { phone },
        data: {
          state,
          lastMessageAt: new Date(),
          ...extra,
        },
      }),
      DB_TIMEOUT
    );
  } catch (e) {
    console.error("[WhatsApp] updateState failed:", e);
  }
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
      const updated = await db.whatsAppConversation.findUnique({ where: { phone: msg.from } });
      
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

  // Move to asking address
  await updateState(msg.from, "ASKING_ADDRESS", {
    selectedSize: selectedOption.size,
    selectedPrice: selectedOption.price,
  });

  await sendTextMessage(
    msg.from,
    "📍 *Delivery Address*\n\nPlease provide your full delivery address (e.g., House No, Building, Area)."
  );
}

// ─── Handle address input ──────────────────────────────────────────────────

async function handleAddressInput(
  msg: IncomingMessage,
  _convo: Conversation
) {
  const address = msg.text?.trim() ?? "";

  if (!address) {
    await sendTextMessage(msg.from, "Please provide a valid address to continue.");
    return;
  }

  // Move to asking instructions
  await updateState(msg.from, "ASKING_INSTRUCTIONS", {
    selectedAddress: address,
  });

  await sendTextMessage(
    msg.from,
    "📝 *Special Instructions*\n\nAny landmarks or special notes for our delivery partner? (e.g., Gate code, call on arrival)\n\nReply *'None'* or *'Skip'* if you have none."
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
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const dayAfter = new Date(today);
  dayAfter.setDate(dayAfter.getDate() + 2);

  const formatDate = (d: Date) =>
    d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short" });

  await sendInteractiveButtons(
    to,
    `📅 *When do you need the cake?*\n\nPlease select a delivery date:`,
    [
      { id: "date_today", title: `Today (${formatDate(today)})` },
      { id: "date_tomorrow", title: `Tmrw (${formatDate(tomorrow)})` },
      { id: "date_dayafter", title: formatDate(dayAfter) },
    ]
  );
}

// ─── Handle delivery date input ────────────────────────────────────────────

async function handleDeliveryDateInput(
  msg: IncomingMessage,
  _convo: Conversation
) {
  let deliveryDate = "";

  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const dayAfter = new Date(today);
  dayAfter.setDate(dayAfter.getDate() + 2);

  const formatDate = (d: Date) =>
    d.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short" });

  if (msg.interactiveId === "date_today") {
    deliveryDate = `Today (${formatDate(today)})`;
  } else if (msg.interactiveId === "date_tomorrow") {
    deliveryDate = `Tomorrow (${formatDate(tomorrow)})`;
  } else if (msg.interactiveId === "date_dayafter") {
    deliveryDate = formatDate(dayAfter);
  } else if (msg.text?.trim()) {
    // User typed a custom date
    deliveryDate = msg.text.trim();
  } else {
    await sendTextMessage(msg.from, "Please select a delivery date or type your preferred date.");
    return;
  }

  // Move to confirmation
  await updateState(msg.from, "CONFIRMING", {
    selectedDeliveryDate: deliveryDate,
  });

  const updatedConvo = await db.whatsAppConversation.findUnique({
    where: { phone: msg.from },
  });

  const cake = await safeGetCakeByName(updatedConvo?.selectedCake ?? "");

  await sendInteractiveButtons(
    msg.from,
    `📋 *Order Summary*\n\n🎂 *${cake?.name}*\n📏 Size: ${updatedConvo?.selectedSize}\n💰 Price: ${updatedConvo?.selectedPrice}\n📍 Address: ${updatedConvo?.selectedAddress}\n📝 Notes: ${updatedConvo?.selectedNotes ?? "_None_"}\n📅 Delivery: *${deliveryDate}*\n\nShall I place this order?`,
    [
      { id: "btn_confirm", title: "✅ Confirm Order" },
      { id: "btn_cancel", title: "❌ Cancel" },
    ]
  );
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
    
    await updateState(msg.from, "ASKING_ADDRESS", {
      customImageUrl: publicUrl ?? `whatsapp://media/${mediaId}`,
      selectedNotes: (convo.selectedNotes ?? "") + "\n[Reference Image Attached] " + caption
    });
    
    await sendTextMessage(
      msg.from,
      "📸 Reference photo received! 📍\n\nWhere should we deliver this custom creation once it's ready?\n\n(Please provide your full address)"
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

  if (!convo.selectedCake || !convo.selectedSize || !convo.selectedPrice) {
    await updateState(msg.from, "IDLE");
    await sendTextMessage(
      msg.from,
      "Something went wrong. Let's start over — reply *Menu*."
    );
    return;
  }

  // Create the order
  const orderNumber = generateOrderNumber();

  const existingConvo = await db.whatsAppConversation.findUnique({
    where: { phone: msg.from },
  });

  await db.whatsAppOrder.create({
    data: {
      orderNumber,
      phone: msg.from,
      customerName: existingConvo?.name ?? msg.name,
      cakeName: convo.selectedCake,
      size: convo.selectedSize,
      price: convo.selectedPrice,
      address: convo.selectedAddress,
      notes: convo.selectedNotes,
      deliveryDate: existingConvo?.selectedDeliveryDate,
      status: "PENDING",
      isCustom: convo.selectedCake === "CUSTOM_CAKE",
      customImageUrl: convo.customImageUrl,
    },
  });

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
    `✅ *Order Placed Successfully!*\n\n🧾 Order #: *${orderNumber}*\n🎂 ${convo.selectedCake}\n📏 ${convo.selectedSize}\n💰 ${convo.selectedPrice}\n📅 Delivery: *${deliveryInfo}*\n\n📞 We'll reach out shortly to confirm.\nYou'll receive updates as your order progresses! 🔔\n\nReply *Status* anytime to check your order.\nReply *Menu* to order more!\n\n_Thank you for choosing Sonna's!_ 💕`
  );
}

// ─── Order status lookup ───────────────────────────────────────────────────

async function sendOrderStatus(to: string) {
  const orders = await db.whatsAppOrder.findMany({
    where: { phone: to },
    orderBy: { createdAt: "desc" },
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
    statusText += `   🎂 ${order.cakeName} (${order.size})\n`;
    statusText += `   💰 ${order.price}\n`;
    statusText += `   Status: *${order.status}*\n`;
    statusText += `   Placed: ${order.createdAt.toLocaleDateString("en-IN")}\n\n`;
  }

  statusText += "Reply *Menu* to order more! 🧁";

  await sendTextMessage(to, statusText);
}
