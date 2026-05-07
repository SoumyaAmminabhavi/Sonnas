
import { PrismaClient } from "../generated/prisma/index.js";

const prisma = new PrismaClient();

async function main() {
  console.log("--- DATABASE CONTENT CHECK ---");
  
  try {
    const orders = await prisma.whatsAppOrder.findMany({
      orderBy: { createdAt: 'desc' },
      take: 5
    });
    
    console.log(`Found ${orders.length} orders in the database.`);
    
    orders.forEach(o => {
      console.log(`- Order #${o.orderNumber} | Phone: ${o.phone} | Status: ${o.status} | Created: ${o.createdAt}`);
    });

    const stats = await prisma.whatsAppOrder.count();
    console.log(`Total Orders in DB: ${stats}`);
  } catch (err) {
    console.error("Database Connection Failed:", err);
  }
  
  console.log("------------------------------");
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
