import { PrismaClient } from "../../../generated/prisma";
const db = new PrismaClient();

async function main() {
  console.log("Reverting images to use Supabase storage bucket...");
  
  const cakes = await db.cake.findMany();
  
  for (const cake of cakes) {
    const newImage = `https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/${cake.slug}.png`;
    await db.cake.update({
      where: { id: cake.id },
      data: { image: newImage },
    });
  }
  
  console.log(`Successfully updated ${cakes.length} cakes to use Supabase images.`);
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await db.$disconnect();
  });
