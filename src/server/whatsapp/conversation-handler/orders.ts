import { randomBytes } from "crypto";
import { db } from "./prisma";
import type { IncomingMessage, WhatsAppConversation } from "./types";
import { convoCache } from "./cache";
import { getCartTotal, clearCart } from "./cart";
import { formatPrice } from "~/lib/format";
import { 
  sendTextMessage, 
  sendInteractiveButtons, 
  sendCTAUrlButton,
  sendInteractiveList
} from "~/server/whatsapp";
import { createPaymentLink } from "~/server/razorpay";
import { updateState, getConversation } from "./session";
import { OrderStatus, PaymentStatus, OrderSource, ConversationState } from "../../../../generated/prisma";
import { RESET_STATE } from "./constants";
import { formatItemTotal } from "./helpers";

export function generateOrderNumber(): string {
  const prefix = "SPC";
  const now = new Date();
  const dateStr = `${now.getFullYear().toString().slice(-2)}${(now.getMonth() + 1).toString().padStart(2, "0")}${now.getDate().toString().padStart(2, "0")}`;
  const random = randomBytes(3).toString("hex").toUpperCase();
  return `${prefix}-${dateStr}-${random}`;
}

export async function createCustomOrder(
  msg: IncomingMessage,
  convo: WhatsAppConversation,
  publicUrl: string | null | undefined,
  mediaId: string,
  caption: string
) {
  const orderNumber = generateOrderNumber();
  const notes = (convo.selectedNotes ?? "") + (caption ? `\nTheme: ${caption}` : "");
  const imageUrl = publicUrl ?? `whatsapp://media/${mediaId}`;

  await db.order.create({
    data: {
      orderNumber,
      source: OrderSource.WHATSAPP,
      whatsappPhone: msg.from,
      customerPhone: msg.from,
      customerName: convo.name ?? msg.name ?? "Customer",
      totalPrice: 0,
      address: convo.selectedAddress ?? "Store Pickup",
      notes,
      status: OrderStatus.PENDING,
      paymentStatus: PaymentStatus.PENDING,
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

  return orderNumber;
}

export async function sendOrderStatus(to: string, offset = 0) {
  const allOrders = await db.order.findMany({
    where: { OR: [{ whatsappPhone: to }, { customerPhone: to }] },
    orderBy: { createdAt: "desc" },
    include: { items: true },
  });

  const totalOrders = allOrders.length;

  if (totalOrders === 0) {
    await sendInteractiveButtons(
      to,
      "You haven't placed an order yet — let's change that! 🧁\n\nBrowse our handcrafted collection and treat yourself to something special.",
      [
        { id: "btn_menu", title: "📋 Browse Our Cakes" },
        { id: "btn_custom", title: "🎨 Custom Creation" },
      ]
    );
    return;
  }

  const PAGE_SIZE = 10;
  const isFirstPage = offset === 0;
  const ordersRemaining = totalOrders - offset;

  let displayCount = 0;
  let hasNext = false;
  const hasPrev = !isFirstPage;

  if (isFirstPage) {
    if (totalOrders > PAGE_SIZE) {
      displayCount = 9;
      hasNext = true;
    } else {
      displayCount = totalOrders;
      hasNext = false;
    }
  } else {
    if (ordersRemaining > 9) {
      displayCount = 8;
      hasNext = true;
    } else {
      displayCount = ordersRemaining;
      hasNext = false;
    }
  }

  const currentBatch = allOrders.slice(offset, offset + displayCount);
  const rows = currentBatch.map((order) => {
    const emoji = order.status === "PENDING" ? "🕐" :
                  order.status === "CONFIRMED" ? "✅" :
                  order.status === "OUT_FOR_DELIVERY" ? "🚚" :
                  order.status === "DELIVERED" ? "🎉" :
                  order.status === "COMPLETED" ? "🍰" :
                  order.status === "CANCELLED" ? "❌" : "📋";

    return {
      id: `hist_order_${order.id}`,
      title: `Order #${order.orderNumber.replace("SPC-", "")}`.slice(0, 24),
      description: `Total: ${formatPrice(order.totalPrice)} | ${emoji} ${order.status}`.slice(0, 72),
    };
  });

  if (hasNext) {
    const nextOffset = offset + displayCount;
    rows.push({
      id: `morehist_${nextOffset}`,
      title: "➡️ Next Page",
      description: `Show older orders ${nextOffset + 1} - ${Math.min(nextOffset + 9, totalOrders)}`
    });
  }

  if (hasPrev) {
    const prevOffset = offset > 9 ? offset - 8 : 0;
    rows.unshift({
      id: `prevhist_${prevOffset}`,
      title: "⬅️ Previous Page",
      description: `Return to orders ${prevOffset + 1} - ${prevOffset + (prevOffset === 0 ? 9 : 8)}`
    });
  }

  await sendInteractiveList(
    to,
    "📦 Order History",
    totalOrders > PAGE_SIZE
      ? `Showing orders ${offset + 1} - ${offset + currentBatch.length} of ${totalOrders}. Select an order to view full details:`
      : `You have placed ${totalOrders} order${totalOrders > 1 ? "s" : ""} with us! Tap an order below to view its details:`,
    "View Orders",
    [
      {
        title: totalOrders > PAGE_SIZE ? `Orders ${offset + 1} - ${offset + currentBatch.length}` : "Your Orders",
        rows,
      }
    ]
  );
}

export async function sendOrderDetails(to: string, orderId: string) {
  const order = await db.order.findUnique({
    where: { id: orderId },
    include: { items: true },
  });

  if (!order) {
    await sendTextMessage(to, "⚠️ Sorry, I couldn't find the details for that order.");
    return;
  }

  const statusEmoji: Record<OrderStatus, string> = {
    PENDING: "🕐",
    CONFIRMED: "✅",
    OUT_FOR_DELIVERY: "🚚",
    DELIVERED: "🎉",
    COMPLETED: "🍰",
    CANCELLED: "❌",
  };

  const emoji = statusEmoji[order.status] ?? "📋";
  let detailsText = `${emoji} *Order Details: #${order.orderNumber}*\n\n`;

  order.items.forEach(item => {
    const qtyStr = item.quantity > 1 ? ` (x${item.quantity})` : "";
    const displayPrice = formatItemTotal(item.price, item.quantity);
    detailsText += `🎂 *${item.cakeName}* (${item.size})${qtyStr}\n   Price: ${displayPrice}\n`;
  });

  detailsText += `\n💰 *Total Price:* ${formatPrice(order.totalPrice ?? 0)}\n`;
  detailsText += `📍 *Delivery Address:* ${order.address || "Store Pickup"}\n`;
  
  if (order.notes) {
    detailsText += `✍️ *Personalization/Notes:* ${order.notes}\n`;
  }

  const dateStr = order.deliveryDate
    ? new Date(order.deliveryDate).toLocaleDateString("en-IN")
    : "Not specified";
  const slotStr = order.deliverySlot ?? "Not specified";
  detailsText += `📅 *Delivery Date:* ${dateStr}\n`;
  detailsText += `🕒 *Time Slot:* ${slotStr}\n`;
  detailsText += `💳 *Payment Status:* *${order.paymentStatus}*\n`;
  detailsText += `✨ *Order Status:* *${order.status}*\n`;
  detailsText += `Placed: ${order.createdAt.toLocaleDateString("en-IN")}\n\n`;

  if (order.paymentStatus === "PENDING" && order.status !== "CANCELLED" && order.paymentLink) {
    await sendCTAUrlButton(
      to,
      detailsText + "💳 Your payment is pending. Tap below to complete payment:",
      "💳 Pay Now",
      order.paymentLink
    );
  } else {
    detailsText += "Reply *Menu* to order more! 🧁";
    await sendTextMessage(to, detailsText);
  }
}

export async function handleConfirmation(
  msg: IncomingMessage,
  convo: WhatsAppConversation
) {
  try {
    const isConfirm = msg.interactiveId === "btn_confirm" || ["yes", "confirm"].includes(msg.text?.toLowerCase() ?? "");
    const isCancel = msg.interactiveId === "btn_cancel" || ["no", "cancel"].includes(msg.text?.toLowerCase() ?? "");

    if (!isConfirm && !isCancel) {
      await sendTextMessage(msg.from, "Please confirm your order or cancel it to start over. 👇");
      const { rePromptState } = await import("./state-machine");
      await rePromptState(msg.from, ConversationState.CONFIRMING_ORDER, convo);
      return;
    }

    if (isCancel) {
      await Promise.all([
        clearCart(msg.from),
        updateState(msg.from, ConversationState.IDLE, RESET_STATE),
        sendTextMessage(msg.from, "❌ Order cancelled."),
      ]);
      const { sendWelcome } = await import("./menu");
      await sendWelcome(msg.from, convo.name ?? msg.name);
      return;
    }

    const cart = convoCache.get(msg.from)?.cart ?? convo.cart ?? [];
    if (cart.length === 0) {
      await updateState(msg.from, ConversationState.IDLE);
      await sendTextMessage(msg.from, "Your cart is empty. Let's start over — reply *Menu*.");
      return;
    }

    const orderNumber = generateOrderNumber();
    const totalAmount = getCartTotal(cart);
    const freshConvo = convoCache.get(msg.from) ?? (await getConversation(msg.from));

    const dbOrder = await db.order.create({
      data: {
        orderNumber,
        source: OrderSource.WHATSAPP,
        whatsappPhone: msg.from,
        customerPhone: msg.from,
        customerName: freshConvo?.name ?? msg.name ?? "Customer",
        totalPrice: totalAmount,
        address: freshConvo.selectedAddress ?? "Store Pickup",
        notes: freshConvo.selectedNotes ?? null,
        deliveryDate: freshConvo.selectedDeliveryDate ? new Date(freshConvo.selectedDeliveryDate) : null,
        deliverySlot: freshConvo.selectedDeliverySlot ?? null,
        status: OrderStatus.PENDING,
        paymentStatus: PaymentStatus.PENDING,
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
      await db.order.update({
        where: { id: dbOrder.id },
        data: {
          paymentLink: rzpLinkResult.short_url,
          razorpayOrderId: rzpLinkResult.id
        },
      }).catch(e => console.error("[WhatsApp] Failed to save payment link to DB:", e));
    }

    await Promise.all([
      clearCart(msg.from),
      updateState(msg.from, ConversationState.IDLE, RESET_STATE)
    ]);

    let successMessage = `🎉 *Order #${orderNumber} Placed!*\n\n`;
    const deliveryDate = freshConvo.selectedDeliveryDate;
    const dateStr = deliveryDate 
      ? (typeof deliveryDate === 'string' ? new Date(deliveryDate) : deliveryDate).toLocaleDateString("en-IN") 
      : "Today";
    const slotStr = freshConvo.selectedDeliverySlot?.trim() ?? "Anytime";
    const formattedSlot = slotStr === "Morning" ? "Morning (10 AM - 1 PM)" :
                          slotStr === "Afternoon" ? "Afternoon (2 PM - 5 PM)" :
                          slotStr === "Evening" ? "Evening (6 PM - 9 PM)" :
                          slotStr;
    successMessage += `📅 *${dateStr}* | 🕒 *${formattedSlot}*\n`;
    successMessage += `📍 ${freshConvo.selectedAddress ?? "Store Pickup"}\n\n`;

    if (paymentLink) {
      const bodyText = successMessage + `💳 Pay *${formatPrice(totalAmount)}* to confirm your order. ✅`;
      await sendCTAUrlButton(msg.from, bodyText, "💳 Pay Now", paymentLink);
    } else {
      successMessage += `💰 Total: *${formatPrice(totalAmount)}*\n\nWe'll contact you shortly to confirm details. 💕`;
      await sendTextMessage(msg.from, successMessage);
    }
  } catch (error) {
    console.error("[WhatsApp] handleConfirmation CRASH:", error);
    await sendTextMessage(msg.from, "⚠️ Something went wrong while placing your order. Please try again or contact us directly. 🙏");
  }
}
