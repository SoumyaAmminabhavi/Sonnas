import { PrismaClient } from '../generated/prisma';
import { products } from '../src/data/products';


const prisma = new PrismaClient();

function slugify(text: string) {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^\w-]+/g, '')
    .replace(/--+/g, '-');
}

async function main() {
  console.log('Seeding Database with Landing static data...');

  // Clear existing items in dev
  await prisma.cake.deleteMany();
  await prisma.cakeOption.deleteMany();

  for (let i = 0; i < products.length; i++) {
    const product = products[i]!;
    const createdCake = await prisma.cake.create({
      data: {
        name: product.name,
        slug: slugify(product.name),
        description: product.description ?? "",
        category: product.category,
        image: product.image,
        isAvailable: product.isAvailable ?? true,
        sortOrder: product.sortOrder ?? i,
        options: {
          create: product.options?.map(opt => ({
            size: opt.size,
            serves: opt.serves,
            price: opt.price
          })) || []
        }
      }
    });
    console.log(`Created cake: ${createdCake.name} (${createdCake.category})`);
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
