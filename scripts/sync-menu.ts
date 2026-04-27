
import { PrismaClient } from '../generated/prisma';

const prisma = new PrismaClient();

const products = [
  {
    name: "Sonna’s Classic Chocolate",
    description: "Chocolate cake with whipped ganache",
    options: [
      { size: "600g", serves: "4-6", price: "₹675" },
      { size: "1050g", serves: "8-12", price: "₹1250" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Classic+Chocolate",
  },
  {
    name: "Almond Brittle Salted Caramel",
    description: "Caramel chocolate ganache + almond brittle",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Almond+Brittle",
  },
  {
    name: "Orange & Chocolate",
    description: "Chocolate cake with orange ganache",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Orange+Chocolate",
  },
  {
    name: "Hazelnut & Chocolate",
    description: "Chocolate cake with hazelnut ganache",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Hazelnut+Chocolate",
  },
  {
    name: "Coffee & Chocolate",
    description: "Chocolate cake with coffee ganache",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Coffee+Chocolate",
  },
  {
    name: "Caramelised White Chocolate",
    description: "Vanilla cake with white chocolate ganache",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=White+Chocolate",
  },
  {
    name: "Pina Colada",
    description: "Coconut & pineapple mousse cake",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Pina+Colada",
  },
  {
    name: "Pineapple",
    description: "Pineapple compote vanilla cake",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Pineapple",
  },
  {
    name: "Rich Mawa",
    description: "Mawa cake with almond flour & cardamom",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Rich+Mawa",
  },
  {
    name: "Persian Cake",
    description: "Almond + orange + mawa cake",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Persian+Cake",
  },
  {
    name: "Butter Cake",
    description: "Classic butter cake",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Butter+Cake",
  },
  {
    name: "Strawberry & Chocolate",
    description: "Strawberry compote + chocolate ganache",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Strawberry+Chocolate",
  },
  {
    name: "Strawberry & Vanilla",
    description: "Strawberry + vanilla cake",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Strawberry+Vanilla",
  },
];

async function main() {
  console.log('🔄 Cleaning existing menu...');
  await prisma.cakeOption.deleteMany();
  await prisma.cake.deleteMany();

  console.log('✨ Seeding new menu...');
  for (const product of products) {
    await prisma.cake.create({
      data: {
        name: product.name,
        description: product.description,
        image: product.image,
        options: {
          create: product.options,
        },
      },
    });
  }

  console.log('✅ Menu sync complete!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
