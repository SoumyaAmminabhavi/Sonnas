import { PrismaClient } from '../../generated/prisma';
const p = new PrismaClient();
async function main() {
  const r = await p.cake.updateMany({ where: { category: 'General' }, data: { category: 'Chocolate Cakes' } });
  console.log('Updated remaining General cakes:', r);
}
void main().finally(() => p.$disconnect());
