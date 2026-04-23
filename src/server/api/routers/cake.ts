import { z } from "zod";

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
      return ctx.db.cake.create({
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
    }),

  delete: publicProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ ctx, input }) => {
      return ctx.db.cake.delete({
        where: { id: input.id },
      });
    }),
});
