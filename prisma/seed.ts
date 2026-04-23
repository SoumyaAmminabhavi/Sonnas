import { PrismaClient } from '../generated/prisma';
import { products } from '../src/data/landing';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Database with Landing static data...');

  // Clear existing items in dev
  await prisma.cake.deleteMany();
  await prisma.cakeOption.deleteMany();

  for (const product of products) {
    const createdCake = await prisma.cake.create({
      data: {
        name: product.name,
        description: product.description ?? "",
        image: product.image,
        options: {
          create: product.options?.map(opt => ({
            size: opt.size,
            serves: opt.serves,
            price: opt.price
          })) || []
        }
      }
    });
    console.log(`Created cake: ${createdCake.name}`);
  }

  console.log('Seeding finished.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
