
import { PrismaClient } from './generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    console.log('Adding columns manually...');
    await prisma.$executeRawUnsafe('ALTER TABLE "WhatsAppConversation" ADD COLUMN IF NOT EXISTS "selectedAddress" TEXT;');
    await prisma.$executeRawUnsafe('ALTER TABLE "WhatsAppOrder" ADD COLUMN IF NOT EXISTS "address" TEXT;');
    console.log('Successfully added columns: selectedAddress, address');
  } catch (error) {
    console.error('Error executing SQL:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
