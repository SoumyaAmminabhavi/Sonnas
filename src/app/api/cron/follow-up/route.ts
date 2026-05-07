/**
 * Post-Delivery Follow-up Cron
 * Sends a warm thank-you and feedback request to customers 24h after delivery.
 */
import { type NextRequest, NextResponse } from "next/server";
import { db } from "~/server/db";
import { sendTextMessage } from "~/server/whatsapp";

const FOLLOWUP_DELAY_MS = 24 * 60 * 60 * 1000; // 24 hours
const CRON_SECRET = process.env.CRON_SECRET;

export async function GET(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  if (CRON_SECRET && authHeader !== `Bearer ${CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const cutoff = new Date(Date.now() - FOLLOWUP_DELAY_MS);

    const deliveredOrders = await db.whatsAppOrder.findMany({
      where: {
        status: "DELIVERED",
        followUpSent: false,
        updatedAt: { lt: cutoff },
      },
      select: {
        id: true,
        orderNumber: true,
        phone: true,
        customerName: true,
        items: { select: { cakeName: true }, take: 1 },
      },
      take: 20,
    });

    if (deliveredOrders.length === 0) {
      return NextResponse.json({ sent: 0, message: "No follow-ups needed" });
    }

    let sentCount = 0;
    for (const order of deliveredOrders) {
      const name = order.customerName ?? "there";
      const cakeName = order.items[0]?.cakeName ?? "sweet treat";

      const message =
        `Hi ${name}! \ud83c\udf38\n\n` +
        `We hope you enjoyed your *${cakeName}*! It was an absolute pleasure crafting it for you at Sonna's Patisserie. \u2728\n\n` +
        `How was the experience? We'd love to hear your feedback or see a photo of your celebration! \ud83d\udcf8\n\n` +
        `Looking forward to delighting you again soon. \ud83c\udf80`;

      try {
        await sendTextMessage(order.phone, message);
        await db.whatsAppOrder.update({
          where: { id: order.id },
          data: { followUpSent: true },
        });
        sentCount++;
      } catch (err) {
        console.error(`[Follow-up] Failed for order ${order.orderNumber}:`, err);
      }
    }

    return NextResponse.json({ sent: sentCount, message: `Sent ${sentCount} follow-ups` });
  } catch (error) {
    console.error("[Follow-up] Cron error:", error);
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
