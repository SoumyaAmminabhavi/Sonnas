import { db } from "./prisma";
import { convoCache } from "./cache";
import type { CartItem, WhatsAppConversation, IncomingMessage } from "./types";
import { formatPrice } from "~/lib/format";
import { formatItemTotal } from "./helpers";
import { sendTextMessage, sendInteractiveButtons } from "~/server/whatsapp";
import { updateState, getConversation } from "./session";
import { ConversationState } from "../../../../generated/prisma";
import { findCake, sendMenu } from "./menu";

export async function addToCart(phone: string, item: { cakeName: string; size: string; price: number; quantity: number }) {
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

    console.log(`[WhatsApp] CART_UPDATE: ${phone} added ${item.cakeName} (${item.size})`);

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

export async function clearCart(phone: string) {
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

export async function removeLastItem(phone: string) {
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

export function getCartTotal(cart: CartItem[]): number {
  let total = 0;
  for (const item of cart) {
    total += item.price * (item.quantity || 1);
  }
  return total;
}

export function getCartSummary(cart: CartItem[]): string {
  if (!cart || cart.length === 0) return "Your cart is empty.";
  let summary = `✨ *Your Selection*\n\n`;
  cart.forEach((item, idx) => {
    const displayPrice = formatItemTotal(item.price, item.quantity);
    summary += `${idx + 1}. *${item.cakeName}* (${item.size})${item.quantity > 1 ? ` x${item.quantity}` : ""} — ${displayPrice}\n`;
  });
  summary += `\n*Total: ${formatPrice(getCartTotal(cart))}*`;

  return summary;
}

export function buildOrderSummary(cart: CartItem[], convo: WhatsAppConversation): string {
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

  const deliveryDate = convo.selectedDeliveryDate;
  const dateStr = deliveryDate
    ? (typeof deliveryDate === 'string' ? new Date(deliveryDate) : deliveryDate).toLocaleDateString("en-IN")
    : "Today";

  const slotStr = convo.selectedDeliverySlot?.trim() ?? "Anytime";
  const formattedSlot = slotStr === "Morning" ? "Morning (10 AM - 1 PM)" :
    slotStr === "Afternoon" ? "Afternoon (2 PM - 5 PM)" :
      slotStr === "Evening" ? "Evening (6 PM - 9 PM)" :
        slotStr;
  summary += `📅 Delivery: *${dateStr}*\n`;
  summary += `🕒 Timing: *${formattedSlot}*\n\n`;
  summary += `\n\nShall we prepare this for you?`;
  return summary;
}

export async function handleCartActions(msg: IncomingMessage, convo: WhatsAppConversation) {
  try {
    const isCheckout = msg.interactiveId === "btn_checkout" || msg.interactiveId === "btn_checkout_now";
    const hasActiveSelection = !!(convo.selectedCakeId && convo.selectedSize && convo.selectedPrice);

    const isAdding = !!(
      (msg.interactiveId?.startsWith("qty_") ?? false) ||
      (msg.interactiveId?.startsWith("size_") ?? false) ||
      (msg.text ?? false) ||
      (msg.interactiveId === "btn_add_to_cart")
    );

    if (isAdding && hasActiveSelection) {
      const selectedCake = await findCake(convo.selectedCakeId);
      const cakeName = selectedCake?.name ?? "Cake";
      const quantity = convo.selectedQuantity ?? 1;

      await addToCart(msg.from, {
        cakeName: cakeName,
        size: convo.selectedSize!,
        price: convo.selectedPrice!,
        quantity: quantity
      });

      const updatedConvo = convoCache.get(msg.from) ?? (await getConversation(msg.from));
      const summary = getCartSummary(updatedConvo.cart ?? []);

      const cartButtons = [
        { id: "btn_checkout", title: "💳 Confirm Order" },
        { id: "btn_menu", title: "➕ Add More" },
      ];

      if (updatedConvo.cart && updatedConvo.cart.length > 1) {
        cartButtons.push({ id: "btn_remove_last", title: "❌ Remove Last" });
      } else {
        cartButtons.push({ id: "btn_clear_cart", title: "🔄 Clear Cart" });
      }

      await Promise.all([
        sendTextMessage(msg.from, `✨ *${cakeName}* added to your order!`),
        sendInteractiveButtons(msg.from, summary, cartButtons),
        updateState(msg.from, ConversationState.IDLE, {
          selectedCakeId: null,
          selectedSize: null,
          selectedPrice: null,
          selectedQuantity: null
        })
      ]);
      return;
    }

    if (isCheckout) {
      console.log(`[WhatsApp] CHECKOUT_START: ${msg.from}`);
      const updatedConvo = await getConversation(msg.from, undefined, true);
      const cart = updatedConvo.cart ?? [];

      if (cart.length === 0) {
        await sendTextMessage(msg.from, "Your selection is empty! Let me show you our cakes 🧁");
        await sendMenu(msg.from);
        return;
      }

      try {
        const lastOrder = await db.order.findFirst({
          where: { OR: [{ whatsappPhone: msg.from }, { customerPhone: msg.from }], status: { not: "CANCELLED" }, address: { not: "" } },
          orderBy: { createdAt: "desc" },
          select: { address: true }
        });

        if (lastOrder?.address && !lastOrder.address.includes("Store Pickup")) {
          await sendInteractiveButtons(
            msg.from,
            `\ud83d\udccd *Would you like to use your previous address?*\n\n_${lastOrder.address.split('\n')[0]}_`,
            [
              { id: `saved_addr_yes`, title: "✅ Use Previous" },
              { id: "btn_delivery", title: "🚚 New Address" },
              { id: "btn_pickup", title: "🏪 Store Pickup" },
            ]
          );
          await updateState(msg.from, ConversationState.INPUTTING_ADDRESS);
          return;
        }
      } catch (err) {
        console.error("[WhatsApp] Error fetching saved address:", err);
      }

      await Promise.all([
        updateState(msg.from, ConversationState.INPUTTING_ADDRESS),
        sendInteractiveButtons(
          msg.from,
          "🏠 *How would you like to receive your order?*",
          [
            { id: "btn_delivery", title: "🚚 Delivery" },
            { id: "btn_pickup", title: "🏪 Store Pickup" },
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
