import { db } from "./prisma";
import { 
  cakeCache, 
  categoryCache, 
  lastCacheUpdate, 
  setCaches,
  convoCache
} from "./cache";
import { CACHE_TTL, DB_TIMEOUT } from "./constants";
import { withTimeout } from "./helpers";
import type { Cake, DBCake, DBCategory, IncomingMessage, WhatsAppConversation } from "./types";
import { products } from "~/data/landing";
import { formatPrice } from "~/lib/format";
import natural from "natural";
import { 
  sendInteractiveList, 
  sendInteractiveButtons, 
  sendImageMessage,
  sendDocumentMessage,
  sendTextMessage
} from "~/server/whatsapp";
import { ConversationState } from "../../../../generated/prisma";
import { updateState, getConversation } from "./session";
import { RESET_STATE } from "./constants";

const { JaroWinklerDistance } = natural;

export async function safeGetCategories(): Promise<DBCategory[]> {
  const now = Date.now();
  if (categoryCache && (now - lastCacheUpdate < CACHE_TTL)) {
    return categoryCache;
  }

  try {
    const result = await db.category.findMany({
      orderBy: { sortOrder: "asc" }
    });
    const categories = result as unknown as DBCategory[];
    setCaches(cakeCache, categories, now);
    return categories;
  } catch (e) {
    console.error("[WhatsApp] Failed to fetch categories:", e);
    return [];
  }
}

export async function safeGetCakes(): Promise<Cake[]> {
  const now = Date.now();
  if (cakeCache && (now - lastCacheUpdate < CACHE_TTL)) {
    return cakeCache;
  }

  try {
    const result = await withTimeout(
      db.cake.findMany({ include: { options: true, category: true } }),
      DB_TIMEOUT
    );

    if (result) {
      const dbCakes = result as unknown as DBCake[];
      const fallbackCakes = products as unknown as Cake[];

      const cakes = dbCakes.map(dbCake => {
        const effectiveCategory = dbCake.category?.name ?? dbCake.categoryName ?? "General";
        
        const fallback = fallbackCakes.find(f => 
          f.name.toLowerCase() === dbCake.name.toLowerCase() || 
          f.id.toString() === dbCake.id.toString()
        );
        
        if (fallback) {
          return {
            ...fallback,
            ...dbCake,
            category: effectiveCategory,
            image: (dbCake.image && String(dbCake.image).startsWith('http') && String(dbCake.image).length > 15) 
                   ? dbCake.image 
                   : fallback.image,
            description: dbCake.description ?? fallback.description,
          } as unknown as Cake;
        }
        return {
          ...dbCake,
          category: effectiveCategory
        } as unknown as Cake;
      })
      .filter(c => c.isAvailable !== false)
      .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0));

      setCaches(cakes, categoryCache, now);
      return cakes;
    }
    return products as unknown as Cake[];
  } catch (e) {
    console.warn("[WhatsApp] DB Menu fetch failed, using fallback.", e);
    return cakeCache ?? (products as unknown as Cake[]);
  }
}

export async function findCake(query: string | number | null | undefined): Promise<Cake | null> {
  if (!query) return null;
  const queryStr = query.toString().trim().toLowerCase();
  if (!queryStr) return null;
  const cakes = await safeGetCakes();

  const byId = cakes.find(c => c.id.toString() === queryStr);
  if (byId) return byId;

  const byName = cakes.find(c => c.name.toLowerCase() === queryStr);
  if (byName) return byName;

  const byPartial = cakes.find(c => c.name.toLowerCase().includes(queryStr) || queryStr.includes(c.name.toLowerCase()));
  if (byPartial) return byPartial;

  let bestMatch = null;
  let highestScore = 0;
  for (const cake of cakes) {
    const score = JaroWinklerDistance(queryStr, cake.name.toLowerCase());
    if (score > highestScore && score > 0.8) {
      highestScore = score;
      bestMatch = cake;
    }
  }
  if (bestMatch) return bestMatch;

  if (queryStr.length > 5) {
    try {
      const dbCake = await withTimeout(
        db.cake.findUnique({ where: { id: queryStr }, include: { options: true } }),
        DB_TIMEOUT
      );
      if (dbCake) return dbCake as unknown as Cake;
    } catch { }
  }

  const localProduct = products.find(p => p.id.toString() === queryStr || p.name.toLowerCase() === queryStr);
  return localProduct as unknown as Cake ?? null;
}

export async function sendMenuPDF(to: string) {
  try {
    await new Promise(resolve => setTimeout(resolve, 1000));
    await sendDocumentMessage(
      to,
      "/menu_compressed.pdf",
      "Sonnas_Patisserie_Menu.pdf",
      "Here is our official menu for your reference. 🧁"
    );
  } catch (e) {
    console.error("[WhatsApp] Failed to send menu PDF:", e);
  }
}

export async function sendWelcome(to: string, name?: string) {
  const greeting = name ? `Hi ${name}! ✨` : "Welcome! ✨";
  const cakes = await safeGetCakes();
  const topCakes = cakes.slice(0, 2);
  const dbCategories = await safeGetCategories();

  await sendInteractiveList(
    to,
    "Sonna's Patisserie",
    `${greeting}\n\nWelcome to *Sonna's Patisserie*\n_Where every dessert is a handcrafted masterpiece._\n\nHow can we delight you today? 🌸\n\n💡 *Quick Tips:*\n• Send *Menu* to browse all cakes\n• Send *Status* to see order history\n• Send *Cancel* to clear your cart`,
    "View Menu",
    [
      {
        title: "⭐ Top Favorites",
        rows: topCakes.map(c => ({
          id: `cake_${c.id}`,
          title: c.name.length > 24 ? c.name.substring(0, 21) + "..." : c.name,
          description: `Signature Selection`
        }))
      },
      {
        title: "📋 Browse by Category",
        rows: dbCategories.length > 0 
          ? dbCategories.slice(0, 6).map(cat => ({
              id: `cat_${cat.id}`,
              title: cat.name.slice(0, 24)
            }))
          : [{ id: "none", title: "Coming Soon...", description: "Fresh categories arriving soon!" }]
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

const cakeRow = (c: Cake) => ({
  id: `cake_${c.id}`,
  title: c.name.slice(0, 24),
  description: `From ${formatPrice(c.options?.[0]?.price ?? 75000)}`,
});

export async function sendMenu(to: string) {
  const cakes = await safeGetCakes();

  if (cakes.length <= 10) {
    const chocolateCakes = cakes.filter((p) => p.category === "Chocolate Cakes" || p.category === "Chocolate");
    const vanillaCakes = cakes.filter((p) => p.category === "Vanilla Cakes" || p.category === "Vanilla");
    const teaCakes = cakes.filter((p) => p.category === "Tea Cakes" || p.category === "Tea");
    const seasonalCakes = cakes.filter((p) => p.category === "Seasonal Cakes" || p.category === "Seasonal");
    const cheesecakes = cakes.filter((p) => p.category === "Mini Cheesecakes");
    const slices = cakes.filter((p) => p.category === "Slices");

    const sections = [];
    if (chocolateCakes.length > 0) sections.push({ title: "🍫 Chocolate Based", rows: chocolateCakes.map(cakeRow) });
    if (vanillaCakes.length > 0) sections.push({ title: "🍦 Vanilla & Fruit Based", rows: vanillaCakes.map(cakeRow) });
    if (cheesecakes.length > 0) sections.push({ title: "🧁 Mini Cheesecakes", rows: cheesecakes.map(cakeRow) });
    if (slices.length > 0) sections.push({ title: "🍰 Slices", rows: slices.map(cakeRow) });
    if (teaCakes.length > 0) sections.push({ title: "☕ Tea Time Specials", rows: teaCakes.map(cakeRow) });
    if (seasonalCakes.length > 0) sections.push({ title: "🍓 Seasonal Specials", rows: seasonalCakes.map(cakeRow) });

    await sendInteractiveList(
      to,
      "🧁 Our Menu",
      "Browse our handcrafted signature cakes. Each made fresh with premium ingredients.\n\nTap below to explore:",
      "View Cakes",
      sections
    );
    await updateState(to, ConversationState.BROWSING_MENU);
  } else {
    const dbCategories = await safeGetCategories();
    await updateState(to, ConversationState.SELECTING_CATEGORY);
    await sendInteractiveList(
      to,
      "🧁 Our Categories",
      "We have quite a variety today! Please select a category to browse:",
      "Select Category",
      [
        {
          title: "Filter by Type",
          rows: dbCategories.length > 0 
            ? dbCategories.slice(0, 10).map((cat) => ({
                id: `cat_${cat.id}`,
                title: cat.name.slice(0, 24),
              }))
            : [{ id: "none", title: "Coming Soon...", description: "Fresh categories arriving soon!" }],
        },
      ]
    );
  }
}

export async function handleCategorySelection(msg: IncomingMessage) {
  const categoryId = msg.interactiveId?.replace("cat_", "");
  if (!categoryId) {
    await sendMenu(msg.from);
    return;
  }

  const phone = msg.from;
  const convo = convoCache.get(phone) ?? (await getConversation(phone));
  const isPagination = msg.interactiveId?.startsWith("more_");
  const offset = isPagination ? (convo.menuOffset ?? 0) : 0;

  const dbCategories = await safeGetCategories();
  const category = dbCategories.find(c => c.id === categoryId);
  const catName = category?.name ?? categoryId;
  const title = category ? category.name : categoryId;

  const allCakes = await safeGetCakes();
  const filtered = allCakes.filter((p) => {
    return p.categoryId === categoryId || p.category?.toLowerCase() === catName.toLowerCase();
  });

  if (filtered.length === 0) {
    await Promise.all([
      updateState(msg.from, ConversationState.BROWSING_MENU),
      sendTextMessage(msg.from, `No cakes found in *${catName}* at the moment.`),
      sendMenu(msg.from),
    ]);
    return;
  }

  const PAGE_SIZE = 10;
  const hasMore = filtered.length > offset + PAGE_SIZE;
  const currentBatch = filtered.slice(offset, offset + (hasMore ? PAGE_SIZE - 1 : PAGE_SIZE));

  const rows = currentBatch.map(cakeRow);

  if (hasMore) {
    rows.push({
      id: `more_${categoryId}_${offset + (PAGE_SIZE - 1)}`,
      title: "➡️ See More...",
      description: `Showing ${offset + 1}-${offset + (PAGE_SIZE - 1)} of ${filtered.length}`,
    });
  }

  await updateState(msg.from, ConversationState.BROWSING_MENU, { menuOffset: offset });

  await sendInteractiveList(
    msg.from,
    title,
    isPagination
      ? `Continuing our ${catName.toLowerCase()} selection:`
      : `Here are our signature ${catName.toLowerCase()} selections:`,
    isPagination ? "Next Items" : "Select a Cake",
    [
      {
        title: isPagination ? `Page ${Math.floor(offset / (PAGE_SIZE - 1)) + 1}` : "Choose your favorite",
        rows,
      },
    ]
  );
}

export async function handleCakeSelection(msg: IncomingMessage) {
  let selectedProduct = null;

  if (msg.interactiveId?.startsWith("cake_")) {
    selectedProduct = await findCake(msg.interactiveId.replace("cake_", ""));
  }

  if (!selectedProduct && msg.text) {
    selectedProduct = await findCake(msg.text);
  }

  if (!selectedProduct) {
    await sendInteractiveButtons(
      msg.from,
      "Hmm, I couldn't quite match that to our menu. 🧁\n\nLet me show you our full collection — you might find something even more tempting!",
      [
        { id: "btn_menu", title: "📋 View Our Menu" },
        { id: "btn_custom", title: "🎨 Custom Creation" },
      ]
    );
    return;
  }

  const tasks: Promise<unknown>[] = [
    updateState(msg.from, ConversationState.SELECTING_SIZE, {
      selectedCakeId: selectedProduct.id as string,
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

export async function handleSizeSelection(
  msg: IncomingMessage,
  convo: WhatsAppConversation
) {
  const cake = await findCake(convo.selectedCakeId);
  if (!cake) {
    await updateState(msg.from, ConversationState.IDLE, RESET_STATE);
    await sendTextMessage(msg.from, "Oops! I seem to have lost track of which cake you were looking at. 🧁\n\nStarting fresh for you! Please select a cake from the menu below.");
    await sendMenu(msg.from);
    return;
  }

  let selectedOption = null;
  if (msg.interactiveId?.startsWith("size_")) {
    const sizeIdx = parseInt(msg.interactiveId.replace("size_", ""), 10);
    selectedOption = cake.options?.[sizeIdx];
  }

  if (!selectedOption && msg.text) {
    const input = msg.text.toLowerCase();
    selectedOption = cake.options?.find(
      (opt) =>
        input.includes(opt.size.toLowerCase()) ||
        input.includes(formatPrice(opt.price).toLowerCase())
    );
  }

  if (!selectedOption) {
    await sendTextMessage(msg.from, "Please select a valid size option, or reply *Cancel* to start over.");
    return;
  }

  const updatedConvo = {
    ...convo,
    selectedSize: selectedOption.size,
    selectedPrice: selectedOption.price,
    selectedQuantity: 1,
  };

  await updateState(msg.from, ConversationState.SELECTING_QUANTITY, {
    selectedSize: selectedOption.size,
    selectedPrice: selectedOption.price,
    selectedQuantity: 1,
  });

  const { handleCartActions } = await import("./cart");
  await handleCartActions(msg, updatedConvo as unknown as WhatsAppConversation);
}

export async function handleQuantitySelection(
  msg: IncomingMessage,
  convo: WhatsAppConversation
) {
  let quantity = 1;
  if (msg.interactiveId?.startsWith("qty_")) {
    quantity = parseInt(msg.interactiveId.replace("qty_", ""), 10);
  } else if (msg.text) {
    const { validateAndSanitize } = await import("./validation");
    const validation = validateAndSanitize("quantity", msg.text);
    if (!validation.success) {
      const { GREETINGS } = await import("./constants");
      if (GREETINGS.includes(msg.text.toLowerCase())) return;
      await sendTextMessage(msg.from, `⚠️ ${validation.error}. Please enter a number between 1 and 20.`);
      return;
    }
    quantity = validation.data as number;
  }

  await updateState(msg.from, ConversationState.SELECTING_QUANTITY, { selectedQuantity: quantity });
  const { handleCartActions } = await import("./cart");
  await handleCartActions(msg, { ...convo, selectedQuantity: quantity } as WhatsAppConversation);
}
