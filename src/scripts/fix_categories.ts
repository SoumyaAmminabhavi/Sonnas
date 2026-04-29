import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

// Map cake names to their correct categories (from landing.ts)
const categoryMap: Record<string, string> = {
  "Sonna's Classic Chocolate": "Chocolate Cakes",
  "Almond Brittle Salted Caramel": "Chocolate Cakes",
  "Orange & Chocolate": "Chocolate Cakes",
  "Hazelnut & Chocolate": "Chocolate Cakes",
  "Coffee & Chocolate": "Chocolate Cakes",
  "Caramelised White Chocolate": "Vanilla Cakes",
  "Pina Colada": "Vanilla Cakes",
  "Pineapple": "Vanilla Cakes",
  "Rich Mawa": "Tea Cakes",
  "Persian Cake": "Tea Cakes",
  "Butter Cake": "Tea Cakes",
  "Strawberry & Chocolate": "Seasonal Cakes",
  "Strawberry & Vanilla": "Seasonal Cakes",
};

async function main() {
  const cakes = await prisma.cake.findMany();
  console.log(`Found ${cakes.length} cakes to update...`);

  for (const cake of cakes) {
    const newCategory = categoryMap[cake.name];
    if (newCategory && cake.category !== newCategory) {
      await prisma.cake.update({
        where: { id: cake.id },
        data: { category: newCategory },
      });
      console.log(`✅ ${cake.name}: "${cake.category}" → "${newCategory}"`);
    } else if (!newCategory) {
      console.log(`⚠️ ${cake.name}: no mapping found, keeping "${cake.category}"`);
    } else {
      console.log(`✔️ ${cake.name}: already correct ("${cake.category}")`);
    }
  }

  console.log('\nDone! Verifying...');
  const updated = await prisma.cake.findMany({ select: { name: true, category: true } });
  console.log(JSON.stringify(updated, null, 2));
}

void main().finally(() => prisma.$disconnect());
