import { PrismaClient } from '../../generated/prisma';
const p = new PrismaClient();
async function main() {
  await p.$executeRawUnsafe('ALTER TABLE "WhatsAppConversation" ADD COLUMN IF NOT EXISTS "selectedDeliveryDate" TEXT;');
  console.log('✅ selectedDeliveryDate column added!');
}
void main().finally(() => p.$disconnect());
