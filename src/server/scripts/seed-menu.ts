import { PrismaClient } from "../../../generated/prisma";
const db = new PrismaClient();

async function main() {
  console.log("Starting menu seed...");

  const menu = [
    {
      name: "Chocolate Cakes",
      cakes: [
        { name: "Sonna’s Classic Chocolate", options: [{ size: "600g", serves: "4-6", price: 67500 }, { size: "1kg", serves: "8-10", price: 125000 }] },
        { name: "Almond Brittle with Salted Caramel Ganache", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Orange & Chocolate", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Hazelnut & Chocolate", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Coffee & Chocolate", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
      ]
    },
    {
      name: "Vanilla Cakes",
      cakes: [
        { name: "Caramalised White Chocolate with Almonds", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Pina Colada", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Pineapple", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
      ]
    },
    {
      name: "Tea Time Cakes",
      cakes: [
        { name: "Rich Mawa", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Persian Cake", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Butter Cake", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
      ]
    },
    {
      name: "Seasonal Cakes",
      cakes: [
        { name: "Strawberry & Chocolate", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
        { name: "Strawberry & Vanilla", options: [{ size: "600g", serves: "4-6", price: 75000 }, { size: "1kg", serves: "8-10", price: 135000 }] },
      ]
    },
    {
      name: "Mini Cheesecakes",
      cakes: [
        { name: "Blueberry", options: [{ size: "Mini", serves: "1", price: 17000 }] },
        { name: "Nutella", options: [{ size: "Mini", serves: "1", price: 18000 }] },
        { name: "Biscoff", options: [{ size: "Mini", serves: "1", price: 19000 }] },
        { name: "Mango", options: [{ size: "Mini", serves: "1", price: 16000 }] },
      ]
    },
    {
      name: "Slices",
      cakes: [
        { name: "Chocolate Cake Slice", options: [{ size: "Slice", serves: "1", price: 13500 }] },
        { name: "Almond Brittle Slice", options: [{ size: "Slice", serves: "1", price: 17500 }] },
        { name: "Chocolate Mousse", options: [{ size: "Slice", serves: "1", price: 14500 }] },
        { name: "Chocolate & Orange Slice", options: [{ size: "Slice", serves: "1", price: 12000 }] },
        { name: "Lemon Mousse", options: [{ size: "Slice", serves: "1", price: 9500 }] },
        { name: "Macaron", options: [{ size: "Piece", serves: "1", price: 8000 }] },
        { name: "Coconut & Mango Slice", options: [{ size: "Slice", serves: "1", price: 18000 }] },
      ]
    }
  ];

  for (let i = 0; i < menu.length; i++) {
    const catData = menu[i]!;
    console.log(`Processing category: ${catData.name}...`);

    const category = await db.category.upsert({
      where: { name: catData.name },
      update: { sortOrder: i },
      create: {
        name: catData.name,
        slug: catData.name.toLowerCase().replace(/\s+/g, "-"),
        sortOrder: i,
      },
    });

    for (const cakeData of catData.cakes) {
      const slug = cakeData.name.toLowerCase().replace(/\s+/g, "-").replace(/[^\w-]+/g, "");

      console.log(`  - Adding cake: ${cakeData.name}...`);
      await db.cake.upsert({
        where: { slug },
        update: {
          categoryId: category.id,
          image: [
            "chocolate--orange-slice",
            "caramalised-white-chocolate-with-almonds",
            "lemon-mousse",
            "blueberry",
            "nutella",
            "macaron",
            "almond-brittle-slice",
            "strawberry-vanilla",
            "strawberry--vanilla",
            "panipuri"
          ].includes(slug)
            ? `/cakes/${slug}.webp`
            : `https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/${slug}.webp`,
        },
        create: {
          name: cakeData.name,
          slug,
          description: `Handcrafted ${cakeData.name}`,
          image: [
            "chocolate--orange-slice",
            "caramalised-white-chocolate-with-almonds",
            "lemon-mousse",
            "blueberry",
            "nutella",
            "macaron",
            "almond-brittle-slice",
            "strawberry-vanilla",
            "strawberry--vanilla",
            "panipuri"
          ].includes(slug)
            ? `/cakes/${slug}.webp`
            : `https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/${slug}.webp`,
          categoryId: category.id,
          options: {
            create: cakeData.options,
          },
        },
      });
    }
  }

  console.log("Menu seed completed successfully!");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await db.$disconnect();
  });
