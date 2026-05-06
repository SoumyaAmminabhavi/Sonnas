/* eslint-disable */
import { NextResponse } from "next/server";
import crypto from "crypto";
import { db } from "~/server/db";
import { sendTextMessage } from "~/server/whatsapp";
import { env } from "~/env";

export async function POST(req: Request) {
  try {
    const body = await req.text();
    const signature = req.headers.get("x-razorpay-signature");

    if (!signature) {
      console.warn("[Razorpay Webhook] Missing signature");
      return new NextResponse("Missing signature", { status: 400 });
    }

    // Verify signature
    const secret = env.RAZORPAY_WEBHOOK_SECRET;
    if (secret) {
      const expectedSignature = crypto
        .createHmac("sha256", secret)
        .update(body)
        .digest("hex");

      if (expectedSignature !== signature) {
        console.warn("[Razorpay Webhook] Invalid signature");
        return new NextResponse("Invalid signature", { status: 400 });
      }
    }


    const payload = JSON.parse(body) as any;
    const event = payload.event;

    console.log(`[Razorpay Webhook] Received event: ${event}`);

    // We specifically listen for payment_link.paid
    if (event === "payment_link.paid") {
      const paymentLink = payload.payload.payment_link.entity;
      const payment = payload.payload.payment.entity;
      const orderNumber = paymentLink.reference_id;

      console.log(`[Razorpay Webhook] Processing payment for Order: ${orderNumber}`);

      try {
        // 1. Update Order in DB (Include items for the bill)
        const order = await db.whatsAppOrder.update({
          where: { orderNumber: orderNumber as string },
          data: {
            status: "CONFIRMED",
            paymentStatus: "PAID",
            paymentId: payment.id as string,
          },
          include: {
            items: true,
          },
        });

        console.log(`[Razorpay Webhook] DB updated successfully for ${orderNumber}`);

        // 2. Generate Premium Bill and Notify Customer via WhatsApp
        if (order) {
          console.log(`[Razorpay Webhook] Sending Premium WhatsApp bill to ${order.phone}...`);

          const dateStr = new Date(order.createdAt).toLocaleDateString("en-IN", {
            day: "numeric",
            month: "short",
            year: "numeric",
          });

          let bill = `✧ *SONNA’S PATISSERIE* ✧\n`;
          bill += `_Luxurious Handcrafted Desserts_\n`;
          bill += `━━━━━━━━━━━━━━━━━━━━\n`;
          bill += `✅ *PAYMENT SUCCESSFUL*\n`;
          bill += `Order: *#${order.orderNumber}*\n`;
          bill += `Date:  *${dateStr}*\n`;
          bill += `━━━━━━━━━━━━━━━━━━━━\n\n`;
          
          bill += `✨ *YOUR ORDER DETAILS*\n\n`;

          order.items.forEach((item, idx) => {
            const qtyStr = item.quantity > 1 ? ` x${item.quantity}` : "";
            bill += `${idx + 1}. *${item.cakeName}*\n    (${item.size})${qtyStr} — ${item.price}\n\n`;
          });

          bill += `━━━━━━━━━━━━━━━━━━━━\n`;
          bill += `*TOTAL AMOUNT PAID: ${order.totalPrice}*\n`;
          bill += `━━━━━━━━━━━━━━━━━━━━\n\n`;

          bill += `🚚 *DELIVERY INFORMATION*\n\n`;
          bill += `📍 *Address:*\n${order.address ?? "_Address not provided_"}\n\n`;
          bill += `📅 *Scheduled:* ${order.deliveryDate ?? "Today"}\n`;
          bill += `🕒 *Time Slot:* ${order.deliveryTime ?? "Anytime"}\n\n`;

          if (order.notes) {
            bill += `📝 *SPECIAL NOTES:*\n_${order.notes}_\n\n`;
          }

          bill += `━━━━━━━━━━━━━━━━━━━━\n`;
          bill += `_Your order is being handcrafted with love. We'll notify you once it's ready for delivery!_ 👩‍🍳\n\n`;
          bill += `*Thank you for choosing luxury.*\n`;
          bill += `*Thank you for choosing Sonna’s.* 💕\n`;
          bill += `━━━━━━━━━━━━━━━━━━━━`;

          await sendTextMessage(order.phone, bill);
          console.log(`[Razorpay Webhook] Premium WhatsApp bill sent!`);
        }
      } catch (dbError) {
        console.error(`[Razorpay Webhook] DB or WhatsApp error:`, dbError);
      }
    }


    return new NextResponse("OK", { status: 200 });
  } catch (err) {
    console.error("[Razorpay Webhook] Error:", err);
    return new NextResponse("Internal Server Error", { status: 500 });
  }
}
