/**
 * WhatsApp Admin tRPC Router
 * Endpoints for managing orders, viewing conversations, and sending messages
 */
import { z } from "zod";
import { createTRPCRouter, publicProcedure } from "~/server/api/trpc";
import { sendTextMessage } from "~/server/whatsapp";
import { env } from "~/env";

export const whatsappRouter = createTRPCRouter({
  // ─── Orders ────────────────────────────────────────────────────────────

  getOrders: publicProcedure
    .input(
      z.object({
        status: z.string().optional(),
        customOnly: z.boolean().optional(),
        limit: z.number().min(1).max(100).default(50),
        cursor: z.string().optional(),
      })
    )
    .query(async ({ ctx, input }) => {
      const where: any = {};
      if (input.status) where.status = input.status;
      if (input.customOnly) where.isCustom = true;

      const orders = await ctx.db.whatsAppOrder.findMany({
        where,
        orderBy: { createdAt: "desc" },
        include: { items: true },
        take: input.limit + 1,
        cursor: input.cursor ? { id: input.cursor } : undefined,
      });

      let nextCursor: string | undefined;
      if (orders.length > input.limit) {
        const last = orders.pop();
        nextCursor = last?.id;
      }

      return { orders, nextCursor };
    }),

  getOrder: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      return ctx.db.whatsAppOrder.findUnique({
        where: { id: input.id },
        include: { items: true },
      });
    }),

  updateOrderStatus: publicProcedure
    .input(
      z.object({
        id: z.string(),
        status: z.enum([
          "PENDING",
          "CONFIRMED",
          "PREPARING",
          "READY",
          "DELIVERED",
          "CANCELLED",
        ]),
        notifyCustomer: z.boolean().default(true),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const order = await ctx.db.whatsAppOrder.update({
        where: { id: input.id },
        data: { status: input.status },
        include: { items: true },
      });

      // Notify the customer via WhatsApp
      if (input.notifyCustomer) {
        const firstItem = order.items[0];
        const cakeName = firstItem?.cakeName ?? "Cake";
        const size = firstItem?.size ?? "Standard";
        const itemsList = order.items.length > 1 
          ? `*${cakeName}* and ${order.items.length - 1} more items`
          : `*${cakeName}* (${size})`;

        const statusMessages: Record<string, string> = {
          CONFIRMED: `✅ *Order Confirmed!*\n\n🧾 #${order.orderNumber}\n🎂 ${itemsList}\n\nWe'll start preparing your order soon!`,
          PREPARING: `👩‍🍳 *Now Preparing!*\n\n🧾 #${order.orderNumber}\n🎂 ${itemsList}\n\nOur bakers are working their magic! ✨`,
          READY: `📦 *Order Ready!*\n\n🧾 #${order.orderNumber}\n🎂 ${itemsList}\n\nYour cake is ready for pickup/delivery! 🎉`,
          DELIVERED: `🎉 *Order Delivered!*\n\n🧾 #${order.orderNumber}\n\nEnjoy your cake! We'd love to hear your feedback 💕\n\nReply *Menu* to order again!`,
          CANCELLED: `❌ *Order Cancelled*\n\n🧾 #${order.orderNumber}\n\nYour order has been cancelled. If you have any questions, please call us at ${env.NEXT_PUBLIC_WHATSAPP_NUMBER_FORMATTED}.`,
        };

        const message = statusMessages[input.status];
        if (message) {
          void sendTextMessage(order.phone, message);
        }
      }

      return order;
    }),

  // ─── Conversations ────────────────────────────────────────────────────

  getConversations: publicProcedure
    .input(
      z.object({
        limit: z.number().min(1).max(100).default(50),
      })
    )
    .query(async ({ ctx, input }) => {
      return ctx.db.whatsAppConversation.findMany({
        orderBy: { lastMessageAt: "desc" },
        take: input.limit,
        include: {
          orders: {
            orderBy: { createdAt: "desc" },
            take: 1,
          },
        },
      });
    }),

  // ─── Stats ────────────────────────────────────────────────────────────

  getStats: publicProcedure.query(async ({ ctx }) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalOrders,
      pendingOrders,
      todaysOrders,
      totalConversations,
      allOrders,
    ] = await Promise.all([
      ctx.db.whatsAppOrder.count(),
      ctx.db.whatsAppOrder.count({ where: { status: "PENDING" } }),
      ctx.db.whatsAppOrder.count({
        where: { createdAt: { gte: today } },
      }),
      ctx.db.whatsAppConversation.count(),
      ctx.db.whatsAppOrder.findMany({
        select: { totalPrice: true, items: true },
      }),
    ]);

    // Calculate revenue (parse ₹ prices)
    const totalRevenue = allOrders.reduce((sum, o) => {
      const amount = parseInt((o.totalPrice ?? "0").replace(/[^\d]/g, ""), 10);
      return sum + (isNaN(amount) ? 0 : amount);
    }, 0);

    // Find most popular cake
    const cakeCounts: Record<string, number> = {};
    allOrders.forEach((o) => {
      o.items.forEach(item => {
        cakeCounts[item.cakeName] = (cakeCounts[item.cakeName] ?? 0) + 1;
      });
    });
    const popularCake =
      Object.entries(cakeCounts).sort(([, a], [, b]) => b - a)[0]?.[0] ??
      "N/A";

    return {
      totalOrders,
      pendingOrders,
      todaysOrders,
      totalConversations,
      totalRevenue,
      popularCake,
    };
  }),

  // ─── Send message from admin ──────────────────────────────────────────

  sendMessage: publicProcedure
    .input(
      z.object({
        phone: z.string(),
        message: z.string().min(1),
      })
    )
    .mutation(async ({ input }) => {
      await sendTextMessage(input.phone, input.message);
      return { success: true };
    }),
});
