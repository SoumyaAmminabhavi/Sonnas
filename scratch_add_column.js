
import { PrismaClient } from './generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    console.log('Attempting to add column manually...');
    await prisma.$executeRawUnsafe('ALTER TABLE "WhatsAppConversation" ADD COLUMN IF NOT EXISTS "selectedNotes" TEXT;');
    console.log('Successfully added column selectedNotes');
    
    // Also check WhatsAppOrder notes field
    await prisma.$executeRawUnsafe('ALTER TABLE "WhatsAppOrder" ADD COLUMN IF NOT EXISTS "notes" TEXT;');
    console.log('Ensured WhatsAppOrder has notes column');

  } catch (error) {
    console.error('Error executing SQL:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
