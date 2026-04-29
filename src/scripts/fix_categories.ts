
import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    const result = await prisma.cake.updateMany({
      where: { 
        OR: [
          { name: 'chocolate raj' },
          { category: 'General' }
        ]
      },
      data: { category: 'Chocolate Cakes' }
    });
    console.log('Successfully updated', result.count, 'cakes to Chocolate Cakes');
  } catch (e) {
    console.error('Error updating cakes:', e);
  } finally {
    await prisma.$disconnect();
  }
}

void main();
