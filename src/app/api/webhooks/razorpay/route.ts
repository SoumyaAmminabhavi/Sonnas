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
        // 1. Update Order in DB
        const order = await db.whatsAppOrder.update({
          where: { orderNumber: orderNumber as string },
          data: {
            status: "CONFIRMED",
            paymentStatus: "PAID",
            paymentId: payment.id as string,
          },
        });

        console.log(`[Razorpay Webhook] DB updated successfully for ${orderNumber}`);

        // 2. Notify Customer via WhatsApp
        if (order) {
          console.log(`[Razorpay Webhook] Sending WhatsApp confirmation to ${order.phone}...`);
          const message = `✅ *Payment Received!*\n\n🧾 Order *#${order.orderNumber}* has been confirmed.\n\nWe've started preparing your delicious cakes! 👩‍🍳 We'll notify you once they are ready for delivery. ✨\n\nThank you for choosing Sonna's Patisserie! 💕`;
          await sendTextMessage(order.phone, message);
          console.log(`[Razorpay Webhook] WhatsApp message sent!`);
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
