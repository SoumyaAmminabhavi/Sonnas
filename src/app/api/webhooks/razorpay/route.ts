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

    // Verify signature — reject ALL webhooks if secret is not configured
    const secret = env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) {
      console.error("[Razorpay Webhook] RAZORPAY_WEBHOOK_SECRET not configured — rejecting webhook for safety.");
      return new NextResponse("Server misconfigured", { status: 500 });
    }

    const expectedSignature = crypto
      .createHmac("sha256", secret)
      .update(body)
      .digest("hex");

    if (expectedSignature !== signature) {
      console.warn("[Razorpay Webhook] Invalid signature — possible tampering attempt.");
      return new NextResponse("Invalid signature", { status: 400 });
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

      // 1. Update Order in DB (Include items for the bill)
      let order;
      try {
        order = await db.order.update({
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
      } catch (dbError) {
        console.error(`[Razorpay Webhook] Database update failed:`, dbError);
        // Throw to the outer catch to return 500 so Razorpay retries
        throw dbError;
      }

      // 2. Generate Premium Bill and Notify Customer via WhatsApp (Non-fatal)
      try {
        if (order) {
          const targetPhone = order.whatsappPhone ?? order.customerPhone;
          console.log(`[Razorpay Webhook] Sending Premium WhatsApp bill to ${targetPhone}...`);

          const dateStr = new Date(order.createdAt).toLocaleDateString("en-IN", {
            day: "numeric",
            month: "short",
            year: "numeric",
          });

          let bill = `✧ *SONNA’S PATISSERIE* ✧\n`;
          bill += `_Luxurious Handcrafted Desserts_\n\n`;

          bill += `✅ *Payment Successful*\n`;
          bill += `Order ID: *#${order.orderNumber}*\n`;
          bill += `Date: ${dateStr}\n\n`;

          bill += `━━━━━━━━━━━━━━━━━━━━\n\n`;
          bill += `*Order Summary*\n\n`;

          const { formatPrice } = await import("~/lib/format");

          order.items.forEach((item) => {
            const qtyStr = item.quantity > 1 ? ` (${item.quantity} units)` : "";
            bill += `*${item.cakeName}*${qtyStr}\n`;
            bill += `${item.size} • ${formatPrice(item.price)}\n\n`;
          });

          bill += `━━━━━━━━━━━━━━━━━━━━\n`;
          bill += `*Total Paid: ${formatPrice(order.totalPrice ?? 0)}*\n`;
          bill += `━━━━━━━━━━━━━━━━━━━━\n\n`;

          // Clean up address: remove coords, GPS labels, and raw URLs
          const cleanAddress = order.address
            ?.replace(/🔗 https:\/\/.*$/m, "")
            .replace(/📍 Coords:.*?\n/g, "")
            .replace(/📍 GPS Location:.*?\n/g, "")
            .trim();

          bill += `*Delivery Details*\n`;
          bill += `📍 ${cleanAddress ?? "_Address not provided_"}\n`;
          bill += `📅 ${order.deliveryDate ?? "Today"}\n`;
          bill += `🕒 ${order.deliverySlot ?? "Anytime"}\n\n`;

          if (order.notes) {
            bill += `📝 *Custom Message*\n`;
            bill += `“${order.notes}”\n\n`;
          }

          bill += `━━━━━━━━━━━━━━━━━━━━\n\n`;
          bill += `_Your dessert is being handcrafted with care. We'll notify you once it's ready._ 👩‍🍳\n\n`;
          bill += `*Thank you for choosing Sonna’s.* 💕`;

          await sendTextMessage(targetPhone, bill);
          console.log(`[Razorpay Webhook] Premium WhatsApp bill sent!`);
        }
      } catch (wsError) {
        // WhatsApp failures are non-fatal for the webhook
        console.error(`[Razorpay Webhook] WhatsApp notification failed (non-fatal):`, wsError);
      }
    }


    return new NextResponse("OK", { status: 200 });
  } catch (err) {
    console.error("[Razorpay Webhook] Error:", err);
    return new NextResponse("Internal Server Error", { status: 500 });
  }
}
