
import { PrismaClient } from '../generated/prisma';

const prisma = new PrismaClient();

import { products } from '../src/data/products';


async function main() {
  console.log('🔄 Syncing menu atomically...');

  await prisma.$transaction(async (tx) => {
    console.log('  🗑️ Cleaning existing menu...');
    await tx.cakeOption.deleteMany();
    await tx.cake.deleteMany();

    console.log('  ✨ Seeding new menu...');
    for (const product of products) {
      // Generate a simple slug from the name
      const slug = product.name
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/(^-|-$)/g, '');

      await tx.cake.create({
        data: {
          name: product.name,
          slug: slug,
          description: product.description,
          image: product.image,
          category: product.category,
          isAvailable: product.isAvailable ?? true,
          sortOrder: product.sortOrder ?? 0,
          options: {
            create: product.options.map(opt => ({
              size: opt.size,
              serves: opt.serves,
              price: opt.price
            })),
          },
        },
      });
    }
  }, {
    timeout: 30000,
  });


  console.log('✅ Menu sync complete!');
}


main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
