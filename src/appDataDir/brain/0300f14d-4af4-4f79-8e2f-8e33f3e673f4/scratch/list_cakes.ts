
import { PrismaClient } from '../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  const cakes = await prisma.cake.findMany({
    select: {
      id: true,
      name: true,
      slug: true,
      image: true,
    }
  });

  console.log(JSON.stringify(cakes, null, 2));
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
