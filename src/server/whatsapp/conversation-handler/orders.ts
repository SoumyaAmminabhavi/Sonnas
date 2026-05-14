import { db } from "./prisma";
import { IncomingMessage, WhatsAppConversation } from "./types";
import { convoCache } from "./cache";
import { getCartTotal, clearCart } from "./cart";
import { formatPrice } from "~/lib/format";
import { 
  sendTextMessage, 
  sendInteractiveButtons, 
  sendCTAUrlButton 
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
  const random = Math.random().toString(36).substring(2, 7).toUpperCase();
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

export async function sendOrderStatus(to: string) {
  const orders = await db.order.findMany({
    where: { OR: [{ whatsappPhone: to }, { customerPhone: to }] },
    orderBy: { createdAt: "desc" },
    include: { items: true },
    take: 3,
  });

  if (orders.length === 0) {
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
    successMessage += `📅 *${dateStr}* | 🕒 *${freshConvo.selectedDeliverySlot ?? "Anytime"}*\n`;
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
