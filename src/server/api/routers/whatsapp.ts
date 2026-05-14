/**
 * WhatsApp Admin tRPC Router
 * Endpoints for managing orders, viewing conversations, and sending messages
 */
import { z } from "zod";
import { createTRPCRouter, protectedProcedure } from "~/server/api/trpc";
import { sendTextMessage } from "~/server/whatsapp";
import { env } from "~/env";
import { OrderStatus, PaymentStatus, OrderSource } from "../../../generated/prisma";

export const whatsappRouter = createTRPCRouter({
  // ─── Orders ────────────────────────────────────────────────────────────

  getOrders: protectedProcedure
    .input(
      z.object({
        status: z.nativeEnum(OrderStatus).optional(),
        customOnly: z.boolean().optional(),
        limit: z.number().min(1).max(100).default(50),
        cursor: z.string().optional(),
        source: z.nativeEnum(OrderSource).optional(),
      })
    )
    .query(async ({ ctx, input }) => {
      const where: any = {};
      if (input.status) where.status = input.status;
      if (input.customOnly) where.isCustom = true;
      if (input.source) where.source = input.source;

      const orders = await ctx.db.order.findMany({
        where,
        orderBy: { createdAt: "desc" },
        include: { 
          items: true
        },
        take: input.limit + 1,
        cursor: input.cursor ? { id: input.cursor } : undefined,
        skip: input.cursor ? 1 : 0,
      });

      // Fetch all cakes to map images (don't let this fail the whole query)
      let cakeImageMap = new Map<string, string>();
      try {
        const cakes = await ctx.db.cake.findMany({
          select: { name: true, image: true }
        });
        cakeImageMap = new Map(cakes.map(c => [c.name, c.image ?? ""]));
      } catch (e) {
        console.error("[Admin] Failed to fetch cakes for images:", e);
      }

      const ordersWithImages = orders.map(order => ({
        ...order,
        items: (order.items ?? []).map(item => ({
          ...item,
          image: cakeImageMap.get(item.cakeName) ?? null
        }))
      }));

      let nextCursor: string | undefined;
      if (ordersWithImages.length > input.limit) {
        const last = ordersWithImages.pop();
        nextCursor = last?.id;
      }

      return { orders: ordersWithImages, nextCursor };
    }),

  getOrder: protectedProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      const order = await ctx.db.order.findUnique({
        where: { id: input.id },
        include: { 
          items: true
        },
      });
      if (!order) return null;

      // Fetch cake images
      const cakes = await ctx.db.cake.findMany({
        where: { name: { in: order.items.map(i => i.cakeName) } },
        select: { name: true, image: true }
      });
      const cakeImageMap = new Map(cakes.map(c => [c.name, c.image]));

      return {
        ...order,
        items: order.items.map(item => ({
          ...item,
          image: cakeImageMap.get(item.cakeName)
        }))
      };
    }),

  updateOrderStatus: protectedProcedure
    .input(
      z.object({
        id: z.string(),
        status: z.nativeEnum(OrderStatus),
        notifyCustomer: z.boolean().default(true),
      })
    )
    .query(async ({ ctx, input }) => {
      const order = await ctx.db.order.update({
        where: { id: input.id },
        data: { status: input.status },
        include: { 
          items: true
        },
      });

      // Notify the customer via WhatsApp (only if it's a WhatsApp order)
      if (input.notifyCustomer && (order.whatsappPhone || order.source === OrderSource.WHATSAPP)) {
        const phone = order.whatsappPhone ?? order.customerPhone;
        const firstItem = order.items[0];
        const cakeName = firstItem?.cakeName ?? "Cake";
        const size = firstItem?.size ?? "Standard";
        const itemsList = order.items.length > 1 
          ? `*${cakeName}* and ${order.items.length - 1} more items`
          : `*${cakeName}* (${size})`;

        const statusMessages: Record<string, string> = {
          CONFIRMED: `✅ *Order Confirmed!*\n\n🧾 #${order.orderNumber}\n🎂 ${itemsList}\n\nWe'll start preparing your order soon!`,
          OUT_FOR_DELIVERY: `👩‍🍳 *Out for Delivery!*\n\n🧾 #${order.orderNumber}\n🎂 ${itemsList}\n\nOur delivery partner is on the way! 🚀`,
          DELIVERED: `🎉 *Order Delivered!*\n\n🧾 #${order.orderNumber}\n\nEnjoy your cake! We'd love to hear your feedback 💕\n\nReply *Menu* to order again!`,
          CANCELLED: `❌ *Order Cancelled*\n\n🧾 #${order.orderNumber}\n\nYour order has been cancelled. If you have any questions, please call us at ${env.NEXT_PUBLIC_WHATSAPP_NUMBER_FORMATTED}.`,
        };

        const message = statusMessages[input.status];
        if (message) {
          void sendTextMessage(phone, message);
        }
      }

      return order;
    }),

  // ─── Conversations ────────────────────────────────────────────────────

  getConversations: protectedProcedure
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

  getStats: protectedProcedure.query(async ({ ctx }) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    // 1. Basic counts and Revenue aggregation
    const [
      totalOrders,
      pendingOrders,
      todaysOrders,
      totalConversations,
      revenueData,
    ] = await Promise.all([
      ctx.db.order.count(),
      ctx.db.order.count({ where: { status: OrderStatus.PENDING } }),
      ctx.db.order.count({ where: { createdAt: { gte: today } } }),
      ctx.db.whatsAppConversation.count(),
      ctx.db.order.aggregate({
        where: { paymentStatus: PaymentStatus.PAID },
        _sum: { totalPrice: true },
      }),
    ]);

    // 2. Revenue Trend (Last 7 days) - Efficient GroupBy
    const dailyRevenue = await ctx.db.order.groupBy({
      by: ['createdAt'],
      where: {
        createdAt: { gte: sevenDaysAgo },
        paymentStatus: PaymentStatus.PAID
      },
      _sum: { totalPrice: true },
    });

    // Post-process the groupBy results to fill missing days and format for the chart
    const revenueTrend = Array.from({ length: 7 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - (6 - i));
      d.setHours(0, 0, 0, 0);
      
      const dayTotal = dailyRevenue
        .filter(r => new Date(r.createdAt).toDateString() === d.toDateString())
        .reduce((sum, r) => sum + (r._sum.totalPrice ?? 0), 0);

      return {
        date: d.toLocaleDateString("en-IN", { weekday: 'short', day: 'numeric' }),
        revenue: dayTotal,
      };
    });

    // 3. Find Most Popular Cake using GroupBy on items
    const popularCakeData = await ctx.db.orderItem.groupBy({
      by: ['cakeName'],
      _count: { cakeName: true },
      orderBy: { _count: { cakeName: 'desc' } },
      take: 1,
    });

    return {
      totalOrders,
      pendingOrders,
      todaysOrders,
      totalConversations,
      totalRevenue: revenueData._sum.totalPrice ?? 0,
      popularCake: popularCakeData[0]?.cakeName ?? "N/A",
      revenueTrend,
    };
  }),

  // ─── Settings ──────────────────────────────────────────────────────────

  getSettings: protectedProcedure.query(async ({ ctx }) => {
    const settings = await ctx.db.whatsAppSetting.findMany();
    return settings.reduce((acc, s) => ({ ...acc, [s.key]: s.value }), {} as Record<string, string>);
  }),

  updateSetting: protectedProcedure
    .input(z.object({ key: z.string(), value: z.string() }))
    .mutation(async ({ ctx, input }) => {
      return ctx.db.whatsAppSetting.upsert({
        where: { key: input.key },
        update: { value: input.value },
        create: { key: input.key, value: input.value },
      });
    }),

  // ─── Send message from admin ──────────────────────────────────────────

  sendMessage: protectedProcedure
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
