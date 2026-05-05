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

    const payload = JSON.parse(body);
    const event = payload.event;

    console.log(`[Razorpay Webhook] Received event: ${event}`);

    // We specifically listen for payment_link.paid
    if (event === "payment_link.paid") {
      const paymentLink = payload.payload.payment_link.entity;
      const payment = payload.payload.payment.entity;
      const orderNumber = paymentLink.reference_id;
      const rzpPaymentLinkId = paymentLink.id;

      console.log(`[Razorpay Webhook] Order ${orderNumber} paid!`);

      // 1. Update Order in DB
      const order = await db.whatsAppOrder.update({
        where: { orderNumber },
        data: {
          status: "CONFIRMED",
          paymentStatus: "PAID",
          paymentId: payment.id,
        },
      });

      // 2. Notify Customer via WhatsApp
      if (order) {
        const message = `✅ *Payment Received!*\n\n🧾 Order *#${order.orderNumber}* has been confirmed.\n\nWe've started preparing your delicious cakes! 👩‍🍳 We'll notify you once they are ready for delivery. ✨\n\nThank you for choosing Sonna's Patisserie! 💕`;
        void sendTextMessage(order.phone, message);
      }
    }

    return new NextResponse("OK", { status: 200 });
  } catch (err) {
    console.error("[Razorpay Webhook] Error:", err);
    return new NextResponse("Internal Server Error", { status: 500 });
  }
}
