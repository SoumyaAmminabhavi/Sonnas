/**
 * Payment Reminder Cron
 * Sends gentle WhatsApp reminders to customers with pending payments.
 * 
 * Trigger: Call via cron service (e.g., Vercel Cron, cron-job.org)
 * Schedule: Every 30 minutes
 * 
 * Query: Orders with paymentStatus=PENDING, created > 30 min ago, 
 *         paymentReminderSent=false, and not cancelled.
 */
import { type NextRequest, NextResponse } from "next/server";
import { db } from "~/server/db";
import { sendTextMessage } from "~/server/whatsapp";

const REMINDER_DELAY_MS = 30 * 60 * 1000; // 30 minutes
export async function GET(request: NextRequest) {
  try {
    const cutoff = new Date(Date.now() - REMINDER_DELAY_MS);

    // Find orders that need a payment reminder
    const pendingOrders = await db.whatsAppOrder.findMany({
      where: {
        paymentStatus: "PENDING",
        status: { not: "CANCELLED" },
        paymentReminderSent: false,
        paymentLink: { not: "" },
        createdAt: { lt: cutoff },
      },
      select: {
        id: true,
        orderNumber: true,
        phone: true,
        customerName: true,
        totalPrice: true,
        paymentLink: true,
        items: {
          select: { cakeName: true },
          take: 1,
        },
      },
      take: 20, // Process max 20 per run to avoid timeouts
    });

    if (pendingOrders.length === 0) {
      return NextResponse.json({ sent: 0, message: "No pending reminders" });
    }

    let sentCount = 0;

    for (const order of pendingOrders) {
      const name = order.customerName ?? "there";
      const cakeName = order.items[0]?.cakeName ?? "cake";

      const message =
        `Hi ${name}! ✨\n\n` +
        `Just a gentle reminder — your *${cakeName}* order *#${order.orderNumber}* is waiting for payment.\n\n` +
        `💳 Complete payment of *${order.totalPrice}* here:\n${order.paymentLink}\n\n` +
        `_Your order will be confirmed instantly once paid._ ✅\n\n` +
        `Need help? Just reply here! 💬`;

      try {
        await sendTextMessage(order.phone, message);
        await db.whatsAppOrder.update({
          where: { id: order.id },
          data: { paymentReminderSent: true },
        });
        sentCount++;
      } catch (err) {
        console.error(`[Payment Reminder] Failed for order ${order.orderNumber}:`, err);
      }
    }

    console.log(`[Payment Reminder] Sent ${sentCount}/${pendingOrders.length} reminders.`);

    return NextResponse.json({
      sent: sentCount,
      total: pendingOrders.length,
      message: `Sent ${sentCount} payment reminders`,
    });
  } catch (error) {
    console.error("[Payment Reminder] Cron error:", error);
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
