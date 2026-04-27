
import { PrismaClient } from './generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    const convo = await prisma.whatsAppConversation.findFirst();
    console.log('Successfully queried WhatsAppConversation');
    console.log('Sample record:', convo);
  } catch (error) {
    console.error('Error querying WhatsAppConversation:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
