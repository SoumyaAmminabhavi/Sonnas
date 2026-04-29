
import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    const count = await prisma.cake.count();
    console.log('Cake count:', count);
    
    const cakes = await prisma.cake.findMany({
      select: { name: true, category: true }
    });
    console.log('All Cakes:', JSON.stringify(cakes, null, 2));
  } catch (e) {
    console.error('Error fetching cakes:', e);
  } finally {
    await prisma.$disconnect();
  }
}

void main();
