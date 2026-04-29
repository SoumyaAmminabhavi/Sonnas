
import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  const order = await prisma.whatsAppOrder.findUnique({
    where: { orderNumber: 'SPC-1Z0ML2Z' }
  });
  
  console.log('Order Details:', JSON.stringify(order, null, 2));
}

main().finally(() => prisma.$disconnect());
