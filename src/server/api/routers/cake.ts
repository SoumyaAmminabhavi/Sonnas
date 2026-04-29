import { z } from "zod";
import { clearMenuCache } from "~/server/whatsapp/conversation-handler";

import {
  createTRPCRouter,
  publicProcedure,
} from "~/server/api/trpc";

export const cakeRouter = createTRPCRouter({
  getAll: publicProcedure.query(async ({ ctx }) => {
    const cakes = await ctx.db.cake.findMany({
      include: { options: true },
      orderBy: { createdAt: "asc" },
    });
    return cakes;
  }),

  getById: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      return ctx.db.cake.findUnique({
        where: { id: input.id },
        include: { options: true },
      });
    }),

  create: publicProcedure
    .input(
      z.object({
        name: z.string().min(1, "Cake name is required"),
        description: z.string().optional(),
        image: z.string().min(1, "Image is required"),
        options: z.array(
          z.object({
            size: z.string().min(1),
            serves: z.string().min(1),
            price: z.string().min(1),
          })
        ).min(1, "At least one size option is required"),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const result = await ctx.db.cake.create({
        data: {
          name: input.name,
          description: input.description ?? "",
          image: input.image,
          options: {
            create: input.options,
          },
        },
        include: { options: true },
      });

      // Clear WhatsApp bot cache
      clearMenuCache();

      return result;
    }),

  update: publicProcedure
    .input(
      z.object({
        id: z.string(),
        name: z.string().min(1),
        description: z.string().optional(),
        image: z.string().min(1),
        options: z.array(
          z.object({
            id: z.string().optional(),
            size: z.string().min(1),
            serves: z.string().min(1),
            price: z.string().min(1),
          })
        ),
      })
    )
    .mutation(async ({ ctx, input }) => {
      // For simplicity, we'll delete and recreate options to avoid complex nested updates
      await ctx.db.cakeOption.deleteMany({
        where: { cakeId: input.id },
      });

      const result = await ctx.db.cake.update({
        where: { id: input.id },
        data: {
          name: input.name,
          description: input.description ?? "",
          image: input.image,
          options: {
            create: input.options.map(opt => ({
              size: opt.size,
              serves: opt.serves,
              price: opt.price
            })),
          },
        },
        include: { options: true },
      });

      // Clear WhatsApp bot cache
      clearMenuCache();

      return result;
    }),

  delete: publicProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const result = await ctx.db.cake.delete({
        where: { id: input.id },
      });
      
      // Clear WhatsApp bot cache
      clearMenuCache();
      
      return result;
    }),
});
