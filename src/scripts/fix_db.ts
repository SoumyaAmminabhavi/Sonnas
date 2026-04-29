
import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    console.log('Adding columns to WhatsAppConversation...');
    await prisma.$executeRawUnsafe(`ALTER TABLE "WhatsAppConversation" ADD COLUMN IF NOT EXISTS "customImageUrl" TEXT;`);
    await prisma.$executeRawUnsafe(`ALTER TABLE "WhatsAppConversation" ADD COLUMN IF NOT EXISTS "selectedQuantity" INTEGER DEFAULT 1;`);
    
    console.log('Adding columns to WhatsAppOrder...');
    await prisma.$executeRawUnsafe(`ALTER TABLE "WhatsAppOrder" ADD COLUMN IF NOT EXISTS "isCustom" BOOLEAN DEFAULT false;`);
    await prisma.$executeRawUnsafe(`ALTER TABLE "WhatsAppOrder" ADD COLUMN IF NOT EXISTS "customImageUrl" TEXT;`);
    
    console.log('Database updated successfully!');
  } catch (e) {
    console.error('Error updating database:', e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
