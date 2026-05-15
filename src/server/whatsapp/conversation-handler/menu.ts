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
      orderBy: { createdAt: "asc" }
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

    if (result && result.length > 0) {
      const dbCakes = result as unknown as DBCake[];
      const cakes = dbCakes.map(dbCake => {
        const effectiveCategory = dbCake.category?.name ?? dbCake.categoryName ?? "General";
        return {
          ...dbCake,
          category: effectiveCategory,
          // Ensure image is a valid URL or placeholder
          image: (dbCake.image && String(dbCake.image).startsWith('http')) 
                 ? dbCake.image 
                 : "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/placeholder.png"
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

export async function sendMenu(to: string, offset = 0) {
  const cakes = await safeGetCakes();

  if (cakes.length <= 10) {
    // ... existing dynamic grouping logic ...
    const categoriesMap = new Map<string, Cake[]>();
    for (const cake of cakes) {
      const cat = cake.category || "Our Selection";
      if (!categoriesMap.has(cat)) categoriesMap.set(cat, []);
      categoriesMap.get(cat)!.push(cake);
    }

    const sections = Array.from(categoriesMap.entries()).map(([title, items]) => ({
      title: title.length > 24 ? title.substring(0, 21) + "..." : title,
      rows: items.map(cakeRow)
    }));

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
    const totalCats = dbCategories.length;
    const PAGE_SIZE = 10;
    
    const isFirstPage = offset === 0;
    const catsRemaining = totalCats - offset;
    
    let displayCount = 0;
    let hasNext = false;
    let hasPrev = !isFirstPage;

    if (isFirstPage) {
      if (totalCats > PAGE_SIZE) {
        displayCount = 9;
        hasNext = true;
      } else {
        displayCount = totalCats;
        hasNext = false;
      }
    } else {
      if (catsRemaining > 9) {
        displayCount = 8;
        hasNext = true;
      } else {
        displayCount = catsRemaining;
        hasNext = false;
      }
    }

    const currentBatch = dbCategories.slice(offset, offset + displayCount);
    const rows: Array<{ id: string; title: string; description?: string }> = currentBatch.map(cat => ({
      id: `cat_${cat.id}`,
      title: cat.name.slice(0, 24)
    }));

    if (hasNext) {
      const nextOffset = offset + displayCount;
      rows.push({
        id: `morecat_${nextOffset}`,
        title: "➡️ Next Categories",
        description: `Show categories ${nextOffset + 1} - ${Math.min(nextOffset + 9, totalCats)}`
      });
    }

    if (hasPrev) {
      const prevOffset = offset > 9 ? offset - 8 : 0;
      rows.unshift({
        id: `prevcat_${prevOffset}`,
        title: "⬅️ Previous Categories",
        description: `Return to categories ${prevOffset + 1} - ${prevOffset + (prevOffset === 0 ? 9 : 8)}`
      });
    }

    await updateState(to, ConversationState.SELECTING_CATEGORY, { menuOffset: offset });
    await sendInteractiveList(
      to,
      "🧁 Our Categories",
      offset > 0 
        ? `Continuing our selection (${offset + 1}-${offset + currentBatch.length} of ${totalCats}):`
        : "We have quite a variety today! Please select a category to browse:",
      "Select Category",
      [
        {
          title: offset > 0 ? `Categories ${offset + 1} - ${offset + currentBatch.length}` : "Filter by Type",
          rows,
        },
      ]
    );
  }
}

export async function handleCategorySelection(msg: IncomingMessage) {
  let categoryId = msg.interactiveId?.replace("cat_", "");
  let offset = 0;

  if (msg.interactiveId?.startsWith("more_") || msg.interactiveId?.startsWith("prev_")) {
    const parts = msg.interactiveId.split("_");
    // ID format: more_{categoryId}_{newOffset} or prev_{categoryId}_{newOffset}
    categoryId = parts[1];
    offset = parseInt(parts[2] ?? "0") || 0;
  }

  if (!categoryId) {
    await sendMenu(msg.from);
    return;
  }

  const phone = msg.from;
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
  const totalItems = filtered.length;
  
  const isFirstPage = offset === 0;
  const itemsRemainingAfterStart = totalItems - offset;
  
  let displayCount = 0;
  let hasNext = false;
  let hasPrev = !isFirstPage;

  if (isFirstPage) {
    if (totalItems > PAGE_SIZE) {
      displayCount = 9;
      hasNext = true;
    } else {
      displayCount = totalItems;
      hasNext = false;
    }
  } else {
    // We are on page 2 or further. 
    // We definitely have a Prev button.
    if (itemsRemainingAfterStart > 9) {
      // We have more than 9 items left, so we need a Next button too.
      // Prev (1) + Next (1) = 2 slots taken. 8 items left for cakes.
      displayCount = 8;
      hasNext = true;
    } else {
      // Last page.
      // Prev (1) + remaining items.
      displayCount = itemsRemainingAfterStart;
      hasNext = false;
    }
  }

  const currentBatch = filtered.slice(offset, offset + displayCount);
  const rows = currentBatch.map(cakeRow);

  // Add Pagination Buttons
  if (hasNext) {
    const nextOffset = offset + displayCount;
    rows.push({
      id: `more_${categoryId}_${nextOffset}`,
      title: "➡️ Next Page",
      description: `Show items ${nextOffset + 1} - ${Math.min(nextOffset + 9, totalItems)}`
    });
  }
  
  if (hasPrev) {
    // To go back, we need to know the offset of the previous page.
    // Page 1 ends at 9. Page 2 starts at 9.
    // If we are at offset 9 (Page 2), previous offset was 0.
    // If we are at offset 17 (Page 3), previous offset was 9.
    // The formula for previous offset is slightly tricky because page 1 is different.
    let prevOffset = 0;
    if (offset > 9) {
      prevOffset = offset - 8;
    }
    
    rows.unshift({
      id: `prev_${categoryId}_${prevOffset}`,
      title: "⬅️ Previous Page",
      description: `Return to items ${prevOffset + 1} - ${prevOffset + (prevOffset === 0 ? 9 : 8)}`
    });
  }

  await updateState(msg.from, ConversationState.BROWSING_MENU, { menuOffset: offset });

  await sendInteractiveList(
    msg.from,
    title,
    !isFirstPage
      ? `Continuing our ${catName.toLowerCase()} selection (${offset + 1}-${offset + currentBatch.length} of ${totalItems}):`
      : `Here are our signature ${catName.toLowerCase()} selections:`,
    !isFirstPage ? "Browse Page" : "Select a Cake",
    [
      {
        title: !isFirstPage ? `Results ${offset + 1} - ${offset + currentBatch.length}` : "Available Delights",
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

  // Only send image if it's a publicly accessible HTTPS URL.
  // WhatsApp Cloud API cannot fetch localhost, relative paths, or blank URLs.
  const isPublicImageUrl = (url: string | null | undefined): boolean => {
    if (!url || url.trim().length < 10) return false;
    const cleaned = url.trim();
    return cleaned.startsWith("https://") && !cleaned.includes("localhost");
  };

  if (isPublicImageUrl(selectedProduct.image)) {
    tasks.push(sendImageMessage(
      msg.from,
      selectedProduct.image,
      `*${selectedProduct.name}*\n\n${selectedProduct.description ?? ""}`
    ));
  } else {
    console.log(`[WhatsApp] Skipping image for "${selectedProduct.name}" — not a public URL: ${selectedProduct.image}`);
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
