import { z } from "zod";
import { clearMenuCache } from "~/server/whatsapp/conversation-handler";

import {
  createTRPCRouter,
  publicProcedure,
  protectedProcedure,
} from "~/server/api/trpc";

export const cakeRouter = createTRPCRouter({
  getAll: publicProcedure.query(async ({ ctx }) => {
    const cakes = await ctx.db.cake.findMany({
      include: { options: true, category: true },
      orderBy: { sortOrder: "asc" },
    });
    return cakes;
  }),

  getAllCategories: publicProcedure.query(async ({ ctx }) => {
    return ctx.db.category.findMany({
      orderBy: { sortOrder: "asc" },
    });
  }),

  getById: publicProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      const cake = await ctx.db.cake.findUnique({
        where: { id: input.id },
        include: { options: true },
      });
      return cake;
    }),

  create: protectedProcedure
    .input(
      z.object({
        name: z.string().min(1, "Cake name is required"),
        slug: z.string().optional(),
        description: z.string().optional(),
        category: z.string().optional(),
        categoryId: z.string().optional(),
        image: z.string().min(1, "Image is required"),
        isAvailable: z.boolean().default(true),
        sortOrder: z.number().default(0),
        options: z.array(
          z.object({
            size: z.string().min(1),
            serves: z.string().min(1),
            price: z.number().min(1),
          })
        ).min(1, "At least one size option is required"),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const slug = (input.slug && input.slug.length > 0) ? input.slug : input.name.toLowerCase().replace(/\s+/g, "-").replace(/[^\w-]+/g, "");
      
      const result = await ctx.db.cake.create({
        data: {
          name: input.name,
          slug,
          description: input.description ?? "",
          categoryId: input.categoryId,
          image: input.image,
          isAvailable: input.isAvailable,
          sortOrder: input.sortOrder,
          options: {
            create: input.options,
          },
        },
        include: { options: true, category: true },
      });

      // Clear WhatsApp bot cache
      clearMenuCache();

      return result;
    }),

  update: protectedProcedure
    .input(
      z.object({
        id: z.string(),
        name: z.string().min(1),
        slug: z.string().optional(),
        description: z.string().optional(),
        category: z.string().optional(),
        categoryId: z.string().optional(),
        image: z.string().min(1),
        isAvailable: z.boolean().optional(),
        sortOrder: z.number().optional(),
        options: z.array(
          z.object({
            id: z.string().optional(),
            size: z.string().min(1),
            serves: z.string().min(1),
            price: z.number().min(1),
          })
        ).min(1, "At least one size option is required"),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const result = await ctx.db.$transaction(async (tx) => {
        // For simplicity, we'll delete and recreate options to avoid complex nested updates
        await tx.cakeOption.deleteMany({
          where: { cakeId: input.id },
        });

        const slug = (input.slug && input.slug.length > 0) ? input.slug : input.name.toLowerCase().replace(/\s+/g, "-").replace(/[^\w-]+/g, "");

        return tx.cake.update({
          where: { id: input.id },
          data: {
            name: input.name,
            slug,
            description: input.description ?? "",
            categoryId: input.categoryId,
            image: input.image,
            isAvailable: input.isAvailable,
            sortOrder: input.sortOrder,
            options: {
              create: input.options.map(opt => ({
                size: opt.size,
                serves: opt.serves,
                price: opt.price
              })),
            },
          },
          include: { options: true, category: true },
        });
      });


      // Clear WhatsApp bot cache
      clearMenuCache();

      return result;
    }),

  delete: protectedProcedure

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
