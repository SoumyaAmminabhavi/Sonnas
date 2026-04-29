
import { PrismaClient } from '../../generated/prisma';

const prisma = new PrismaClient();

async function main() {
  try {
    console.log('Adding "category" column to Cake table...');
    await prisma.$executeRawUnsafe(`ALTER TABLE "Cake" ADD COLUMN IF NOT EXISTS "category" TEXT DEFAULT 'General';`);
    
    console.log('Database updated successfully!');
  } catch (e) {
    console.error('Error updating database:', e);
  } finally {
    await prisma.$disconnect();
  }
}

void main();
