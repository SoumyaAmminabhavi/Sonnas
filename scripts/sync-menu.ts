
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
      await tx.cake.create({
        data: {
          name: product.name,
          description: product.description,
          image: product.image,
          category: product.category,
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
