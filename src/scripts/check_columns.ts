
import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    const tableInfo = await prisma.$queryRaw`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'WhatsAppConversation';
    `;
    console.log('Columns in WhatsAppConversation:', JSON.stringify(tableInfo, null, 2));
    
    const orderInfo = await prisma.$queryRaw`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'WhatsAppOrder';
    `;
    console.log('Columns in WhatsAppOrder:', JSON.stringify(orderInfo, null, 2));
  } catch (e) {
    console.error('Error fetching table info:', e);
  } finally {
    await prisma.$disconnect();
  }
}

void main();
