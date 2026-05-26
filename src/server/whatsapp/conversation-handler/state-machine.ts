import type { IncomingMessage, WhatsAppConversation } from "./types";
import { ConversationState } from "../../../../generated/prisma";
import { GREETINGS, RESET_STATE } from "./constants";
import { sendWelcome, sendMenu, findCake, handleCakeSelection, handleCategorySelection } from "./menu";
import { updateState, getConversation, getSessionTimeoutMins } from "./session";
import { sendTextMessage, sendInteractiveButtons, sendInteractiveList } from "~/server/whatsapp";
import { formatPrice } from "~/lib/format";
import { handleCartActions, getCartSummary, removeLastItem, clearCart, buildOrderSummary } from "./cart";
import { sendOrderStatus, handleConfirmation } from "./orders";
import { handleDeliverySlotSelection, handleAddressInput, handleInstructionsInput } from "./delivery";
import { handleCustomRequest, handleReferenceImageUpload } from "./custom-orders";
import { convoCache } from "./cache";
import { db } from "./prisma";

export async function rePromptState(phone: string, state: ConversationState, convo: WhatsAppConversation) {
  switch (state) {
    case ConversationState.BROWSING_MENU:
      await sendMenu(phone);
      break;
    case ConversationState.SELECTING_CATEGORY:
      await sendMenu(phone);
      break;
    case ConversationState.SELECTING_SIZE:
      if (convo.selectedCakeId) {
        const cake = await findCake(convo.selectedCakeId);
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
    case ConversationState.INPUTTING_ADDRESS:
      await sendInteractiveButtons(
        phone,
        "🏠 *How would you like to receive your order?*",
        [
          { id: "btn_delivery", title: "🚚 Delivery" },
          { id: "btn_pickup", title: "🏪 Store Pickup" },
          { id: "btn_back", title: "⬅️ Back" },
        ]
      );
      break;
    case ConversationState.ADDING_NOTES:
      await sendInteractiveButtons(
        phone,
        "✍️ *Personalize Your Cake*\n\nWhat message would you like on your cake?\n\nReply *Skip* if none.",
        [{ id: "btn_back", title: "⬅️ Back" }]
      );
      break;
    case ConversationState.CONFIRMING_ORDER: {
      const cart = convoCache.get(phone)?.cart ?? [];
      await sendInteractiveButtons(phone, buildOrderSummary(cart, convo), [
        { id: "btn_confirm", title: "✅ Confirm Order" },
        { id: "btn_back", title: "⬅️ Back" },
        { id: "btn_cancel", title: "❌ Cancel" },
      ]);
      break;
    }
    case ConversationState.CUSTOM_ORDER_DETAILS:
      await sendTextMessage(phone, "🎨 *Custom Cake Request*\n\nPlease describe the cake or send a **Reference Photo**. 📸");
      break;
    case ConversationState.CUSTOM_ORDER_IMAGE:
      await sendTextMessage(phone, "📸 *Reference Photo Needed*\n\nPlease upload a photo of the design you'd like us to create for you! ✨");
      break;
    default:
      await sendWelcome(phone, convo.name ?? undefined);
  }
}

export async function _internalHandleMessage(msg: IncomingMessage) {
  let convo = await getConversation(msg.from, msg.name);
  let state = convo.state;

  // ── Session Timeout Check ────────────────────────────────────────────────
  if (state !== ConversationState.IDLE && convo.lastActivityAt) {
    const lastActivity = new Date(convo.lastActivityAt).getTime();
    const timeoutMins = await getSessionTimeoutMins();

    if (Date.now() - lastActivity > timeoutMins * 60 * 1000) {
      console.log(`[WhatsApp] Session timeout for ${msg.from}. Resetting.`);
      await Promise.all([
        clearCart(msg.from),
        updateState(msg.from, ConversationState.IDLE, RESET_STATE),
      ]);
      await sendTextMessage(msg.from, "Your previous session timed out due to inactivity. Starting fresh for you! ✨");
      convo = await getConversation(msg.from, msg.name, true);
      state = convo.state;
    }
  }

  // ── Integrity Check: Catch "Zombie" States ──────────────────────────────
  const statesRequiringCake: ConversationState[] = [ConversationState.SELECTING_SIZE, ConversationState.SELECTING_QUANTITY];
  if (statesRequiringCake.includes(state) && !convo.selectedCakeId) {
    console.warn(`[WhatsApp] Integrity Check Failed: ${msg.from} in ${state} with no cake selected.`);
    await updateState(msg.from, ConversationState.IDLE, RESET_STATE);
    state = ConversationState.IDLE;
    convo = await getConversation(msg.from, msg.name, true);
  }

  const input = msg.text?.trim().toLowerCase() ?? "";
  const interactiveId = msg.interactiveId ?? "";

  console.log(`[WhatsApp] Processing from ${msg.from}: ${input || interactiveId} (State: ${state})`);

  const dbGreetingsRaw = await import("./session").then(m => m.getWhatsAppSetting("GREETINGS", ""));
  const dbGreetings = dbGreetingsRaw.split(",").map(g => g.trim().toLowerCase()).filter(g => g.length > 0);
  const effectiveGreetings = dbGreetings.length > 0 ? dbGreetings : GREETINGS.map(g => g.toLowerCase());

  if (effectiveGreetings.includes(input)) {
    if (state === ConversationState.IDLE) {
      await sendWelcome(msg.from, msg.name);
    } else {
      await rePromptState(msg.from, state, convo);
    }
    return;
  }

  if (["restart", "start over", "reset", "cancel"].includes(input)) {
    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, ConversationState.IDLE, RESET_STATE),
    ]);
    await sendTextMessage(msg.from, "No worries! Everything's been cleared. ✨\n\nWhenever you're ready, I'm here to help you find the perfect cake. 🌸");
    await sendWelcome(msg.from, msg.name);
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
      await updateState(msg.from, ConversationState.SELECTING_SIZE, {
        selectedCakeId: selectedProduct.id as string,
        selectedSize: null,
        selectedPrice: null,
      });
      await handleCakeSelection({ ...msg, interactiveId: `cake_${selectedProduct.id}` });
      return;
    }
    await sendWelcome(msg.from, msg.name);
    return;
  }

  // ── Design Your Cake Trigger from Website ──────────────────────────────
  if (input.includes("design my own cake")) {
    await Promise.all([
      updateState(msg.from, ConversationState.CUSTOM_ORDER_IMAGE, {
        selectedSize: "Custom Design",
        selectedPrice: 0,
      }),
      sendTextMessage(msg.from, "Hi there! 👋 Welcome to our *Cake Design Flow*.\n\nTo get started, please upload a **Reference Photo** of the cake you have in mind! 📸")
    ]);
    return;
  }

  if (input === "menu" || input === "cakes" || interactiveId === "btn_menu") {
    await Promise.all([
      updateState(msg.from, ConversationState.BROWSING_MENU, {
        selectedCakeId: null,
        selectedSize: null,
        selectedPrice: null,
      }),
      sendMenu(msg.from),
    ]);
    return;
  }

  if (interactiveId === "btn_custom") {
    await Promise.all([
      updateState(msg.from, ConversationState.CUSTOM_ORDER_DETAILS, {
        selectedSize: "Custom Design",
        selectedPrice: 0,
      }),
      sendTextMessage(msg.from, "🎨 *Custom Cake Request*\n\nPlease describe the cake you have in mind! (Flavor, Theme, Size, etc.)\n\n📸 You can also send a *Reference Photo* after describing it.")
    ]);
    return;
  }

  if (["status", "my order", "order status"].includes(input) || interactiveId === "btn_status") {
    await sendOrderStatus(msg.from);
    return;
  }

  if (["btn_add_to_cart", "btn_checkout", "btn_checkout_now"].includes(interactiveId)) {
    await handleCartActions(msg, convo);
    return;
  }

  if (interactiveId === "btn_clear_cart") {
    await sendInteractiveButtons(
      msg.from,
      "⚠️ *Are you sure you want to clear your cart?*\n\nThis will remove all your selected cakes.",
      [
        { id: "btn_confirm_clear", title: "🗑️ Yes, Clear All" },
        { id: "btn_cancel_clear", title: "🧁 No, Keep Items" }
      ]
    );
    return;
  }

  if (interactiveId === "btn_confirm_clear") {
    await clearCart(msg.from);
    await updateState(msg.from, ConversationState.IDLE, RESET_STATE);
    await sendTextMessage(msg.from, "✨ *Cart selection cleared!*");
    await sendMenu(msg.from);
    return;
  }

  if (interactiveId === "btn_cancel_clear") {
    await sendTextMessage(msg.from, "Cart preserved! 🍰");
    await handleCartActions(msg, convo);
    return;
  }

  if (interactiveId === "btn_back") {
    if (state === ConversationState.SELECTING_SIZE && convo.lastCategoryId) {
      const fakeMsg = {
        ...msg,
        interactiveId: `cat_${convo.lastCategoryId}`
      };
      await updateState(msg.from, ConversationState.SELECTING_CATEGORY);
      await handleCategorySelection(fakeMsg);
      return;
    }
    let targetState: ConversationState = ConversationState.IDLE;
    switch (state) {
      case ConversationState.SELECTING_SIZE: targetState = ConversationState.BROWSING_MENU; break;
      case ConversationState.SELECTING_QUANTITY: targetState = ConversationState.SELECTING_SIZE; break;
      case ConversationState.INPUTTING_ADDRESS:
        await updateState(msg.from, ConversationState.IDLE);
        const updatedConvo = convoCache.get(msg.from) ?? convo;
        const summary = getCartSummary(updatedConvo.cart ?? []);
        await sendInteractiveButtons(msg.from, summary, [
          { id: "btn_checkout", title: "💳 Place My Order" },
          { id: "btn_menu", title: "➕ Add More" },
          { id: "btn_clear_cart", title: "🔄 Start Fresh" },
        ]);
        return;
      case ConversationState.ADDING_NOTES:
        if (convo.selectedAddress === "🏪 Store Pickup") {
          await updateState(msg.from, ConversationState.INPUTTING_ADDRESS);
          await sendInteractiveButtons(msg.from, "🏠 *How would you like to receive your order?*", [
            { id: "btn_delivery", title: "🚚 Delivery" },
            { id: "btn_pickup", title: "🏪 Store Pickup" },
          ]);
        } else {
          targetState = ConversationState.INPUTTING_ADDRESS;
        }
        break;
      case ConversationState.ASKING_DELIVERY_DATE: targetState = ConversationState.ADDING_NOTES; break;
      case ConversationState.CONFIRMING_ORDER: targetState = ConversationState.ASKING_DELIVERY_DATE; break;
      default: targetState = ConversationState.IDLE;
    }

    if (targetState === ConversationState.IDLE) {
      await sendWelcome(msg.from, msg.name);
    } else {
      await updateState(msg.from, targetState);
      await rePromptState(msg.from, targetState, convo);
    }
    return;
  }

  if (interactiveId === "btn_remove_last") {
    const removedName = await removeLastItem(msg.from);
    if (removedName) await sendTextMessage(msg.from, `✨ *${removedName}* has been removed from your selection.`);
    const updatedConvo = convoCache.get(msg.from) ?? convo;
    const summary = getCartSummary(updatedConvo.cart ?? []);
    await sendInteractiveButtons(msg.from, summary, [
      { id: "btn_checkout", title: "💳 Place My Order" },
      { id: "btn_menu", title: "➕ Add More" },
      { id: "btn_clear_cart", title: "🔄 Start Fresh" },
    ]);
    return;
  }

  if (interactiveId === "btn_pickup") {
    await Promise.all([
      updateState(msg.from, ConversationState.ADDING_NOTES, { selectedAddress: "🏪 Store Pickup" }),
      sendInteractiveButtons(msg.from, "✨ *Store Pickup Selected*\n\nWhat message would you like on your cake?\n\nReply *Skip* if none.", [{ id: "btn_back", title: "⬅️ Back" }])
    ]);
    return;
  }

  if (interactiveId === "saved_addr_yes") {
    const activeAddress = convo.selectedAddress;
    if (activeAddress && !activeAddress.includes("Store Pickup")) {
      await updateState(msg.from, ConversationState.ADDING_NOTES, { selectedAddress: activeAddress });
      await sendInteractiveButtons(msg.from, `✅ *Address set!*\n\n✍️ *Personalize Your Cake*\n\nWhat message would you like on your cake?\n_(e.g., \"Happy Birthday Priya! 🎉\")_\n\nReply *Skip* if no message needed.`, [{ id: "btn_back", title: "⬅️ Back" }]);
      return;
    }

    const lastOrder = await db.order.findFirst({
      where: { OR: [{ whatsappPhone: msg.from }, { customerPhone: msg.from }], status: { not: "CANCELLED" }, address: { not: "" } },
      orderBy: { createdAt: "desc" },
      select: { address: true }
    });
    if (lastOrder?.address) {
      await updateState(msg.from, ConversationState.ADDING_NOTES, { selectedAddress: lastOrder.address });
      await sendInteractiveButtons(msg.from, `✅ *Address set!* (📍 Previously used)\n\n✍️ *Personalize Your Cake*\n\nWhat message would you like on your cake?\n_(e.g., \"Happy Birthday Priya! 🎉\")_\n\nReply *Skip* if no message needed.`, [{ id: "btn_back", title: "⬅️ Back" }]);
      return;
    }
  }

  if (interactiveId === "btn_delivery") {
    await Promise.all([
      updateState(msg.from, ConversationState.INPUTTING_ADDRESS),
      sendTextMessage(msg.from, "📍 *Delivery Address*\n\nPlease share your delivery address or tap the 📎 icon to send your *GPS Location*.")
    ]);
    return;
  }

  if (interactiveId.startsWith("morecat_") || interactiveId.startsWith("prevcat_")) {
    const offset = parseInt(interactiveId.split("_")[1] ?? "0") || 0;
    await sendMenu(msg.from, offset);
    return;
  }

  if (interactiveId.startsWith("more_") || interactiveId.startsWith("prev_")) {
    await handleCategorySelection(msg);
    return;
  }

  if (interactiveId.startsWith("cat_")) { await handleCategorySelection(msg); return; }
  if (interactiveId.startsWith("cake_")) { await handleCakeSelection(msg); return; }
  if (interactiveId.startsWith("size_")) {
    const { handleSizeSelection } = await import("./menu");
    await handleSizeSelection(msg, convo);
    return;
  }
  if (interactiveId.startsWith("slot_")) { await handleDeliverySlotSelection(msg, convo); return; }

  // ── Global: Image/Location sent outside flow ──────────────────────────
  const customOrderStates: ConversationState[] = [ConversationState.CUSTOM_ORDER_DETAILS, ConversationState.CUSTOM_ORDER_IMAGE];
  if (msg.type === "image" && !customOrderStates.includes(state)) {
    await sendInteractiveButtons(msg.from, "📸 Beautiful photo! If you'd like us to create a custom cake based on this design, tap below:", [
      { id: "btn_custom", title: "🎨 Start Custom Order" },
      { id: "btn_menu", title: "📋 Browse Menu" },
    ]);
    return;
  }

  if (msg.type === "location" && state !== ConversationState.INPUTTING_ADDRESS) {
    if (msg.location) {
      await sendTextMessage(msg.from, "📍 _Processing your location..._");
      const { reverseGeocode } = await import("./delivery");
      const mapsUrl = `https://www.google.com/maps?q=${msg.location.latitude},${msg.location.longitude}`;
      let addr = msg.location.address ?? msg.location.name;

      if (!addr || addr.length < 5) {
        const geocoded = await reverseGeocode(msg.location.latitude, msg.location.longitude);
        if (geocoded) addr = geocoded;
      }

      addr ??= `GPS: ${msg.location.latitude}, ${msg.location.longitude}`;

      await updateState(msg.from, state, { selectedAddress: `${addr}\n🔗 ${mapsUrl}` });
    }
    await sendTextMessage(msg.from, "📍 Location saved! I'll use this when you're ready to place an order. ✨\n\nReply *Menu* to browse our cakes!");
    return;
  }

  switch (state) {
    case ConversationState.IDLE:
      if (input.length > 3) {
        const found = await findCake(input);
        if (found) { await handleCakeSelection({ ...msg, interactiveId: `cake_${found.id}` }); return; }
      }
      await sendWelcome(msg.from, msg.name);
      break;
    case ConversationState.BROWSING_MENU: await handleCakeSelection(msg); break;
    case ConversationState.SELECTING_CATEGORY: await handleCategorySelection(msg); break;
    case ConversationState.SELECTING_SIZE: {
      const { handleSizeSelection } = await import("./menu");
      await handleSizeSelection(msg, convo);
      break;
    }
    case ConversationState.SELECTING_QUANTITY: {
      const { handleQuantitySelection } = await import("./menu");
      await handleQuantitySelection(msg, convo);
      break;
    }
    case ConversationState.INPUTTING_ADDRESS: await handleAddressInput(msg, convo); break;
    case ConversationState.ADDING_NOTES: await handleInstructionsInput(msg, convo); break;
    case ConversationState.ASKING_DELIVERY_DATE: await handleDeliverySlotSelection(msg, convo); break;
    case ConversationState.CUSTOM_ORDER_DETAILS: await handleCustomRequest(msg, convo); break;
    case ConversationState.CUSTOM_ORDER_IMAGE: await handleReferenceImageUpload(msg, convo); break;
    case ConversationState.CONFIRMING_ORDER: await handleConfirmation(msg, convo); break;
    default: await sendWelcome(msg.from, msg.name);
  }
}
