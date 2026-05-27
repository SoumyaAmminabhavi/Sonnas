import { PrismaClient } from '../generated/prisma';
import { products, categories } from '../src/data/products';


const prisma = new PrismaClient();

function slugify(text: string) {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^\w-]+/g, '')
    .replace(/--+/g, '-');
}

async function main() {
  console.log('Seeding Database with Landing static data...');

  // Clear existing items in dev
  await prisma.cake.deleteMany();
  await prisma.cakeOption.deleteMany();
  await prisma.category.deleteMany();

  // 1. Seed categories first to ensure correct image mappings from products.ts
  for (let i = 0; i < categories.length; i++) {
    const cat = categories[i]!;
    await prisma.category.create({
      data: {
        name: cat.name,
        slug: cat.slug,
        image: cat.image,
        sortOrder: i,
      },
    });
    console.log(`Seeded category: ${cat.name}`);
  }

  const createdSlugs = new Set<string>();

  for (let i = 0; i < products.length; i++) {
    const product = products[i]!;
    let slug = slugify(product.name);

    if (createdSlugs.has(slug)) {
      slug = slugify(`${product.name}-${product.category}`);
    }
    createdSlugs.add(slug);

    const createdCake = await prisma.cake.create({
      data: {
        name: product.name,
        slug: slug,
        description: product.description ?? "",
        category: product.category
          ? {
              connect: { name: product.category }
            }
          : undefined,
        image: product.image,
        isAvailable: product.isAvailable ?? true,
        sortOrder: product.sortOrder ?? i,
        options: {
          create: product.options?.map(opt => ({
            size: opt.size,
            serves: opt.serves,
            price: opt.price
          })) || []
        }
      }
    });
    console.log(`Created cake: ${createdCake.name} (${product.category})`);
  }

  // ==========================================
  // Seeding Dynamic WhatsApp Templates
  // ==========================================
  console.log("Seeding Dynamic WhatsApp Templates...");

  // Clean old configurations to avoid unique/foreign key conflicts in local seed runs
  await prisma.whatsAppListRow.deleteMany();
  await prisma.whatsAppListSection.deleteMany();
  await prisma.whatsAppButton.deleteMany();
  await prisma.whatsAppTemplateVersion.deleteMany();
  await prisma.whatsAppTemplate.deleteMany();

  // 1. Welcome Message Greeting Template
  const welcomeTemplate = await prisma.whatsAppTemplate.upsert({
    where: { code_language: { code: "WELCOME_MESSAGE", language: "en" } },
    update: { isActive: true },
    create: {
      code: "WELCOME_MESSAGE",
      language: "en",
      description: "Initial greeting and category selection template.",
      category: "GREETING",
      isActive: true,
    },
  });

  const welcomeVersion = await prisma.whatsAppTemplateVersion.create({
    data: {
      templateId: welcomeTemplate.id,
      versionNumber: 1,
      headerText: "Sonna's Patisserie",
      bodyText: "Hi {{customer_name}}! ✨\n\nWelcome to *Sonna's Patisserie*\n_Where every dessert is a handcrafted masterpiece._\n\nHow can we delight you today? 🌸\n\n💡 *Quick Tips:*\n• Send *Menu* to browse all categories and items\n• Send *Status* to see order history\n• Send *Cancel* or *Restart* to clear your cart",
      mediaUrl: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/menu_compressed.pdf",
      mediaType: "DOCUMENT",
      footerText: "Our Menu",
      interactiveType: "LIST",
      listButtonTitle: "View Menu",
      listTitle: "Explore Patisserie",
      changeLog: "Initial seeding of dynamic welcome layout",
      createdBy: "System Migration",
    },
  });

  await prisma.whatsAppTemplate.update({
    where: { id: welcomeTemplate.id },
    data: { activeVersionId: welcomeVersion.id },
  });

  // Welcome Dropdown list sections
  const secFavorites = await prisma.whatsAppListSection.create({
    data: {
      versionId: welcomeVersion.id,
      sortOrder: 1,
      title: "🔥 Top Sellers",
      dataSource: "TOP_FAVORITES",
    },
  });

  const secCategories = await prisma.whatsAppListSection.create({
    data: {
      versionId: welcomeVersion.id,
      sortOrder: 2,
      title: "📋 Browse by Category",
      dataSource: "CATEGORIES",
    },
  });

  const secServices = await prisma.whatsAppListSection.create({
    data: {
      versionId: welcomeVersion.id,
      sortOrder: 3,
      title: "✨ Other Services",
      dataSource: "STATIC",
    },
  });

  // Welcome static service shortcut rows
  await prisma.whatsAppListRow.createMany({
    data: [
      {
        sectionId: secServices.id,
        sortOrder: 1,
        rowId: "btn_custom",
        title: "🎨 Custom Creation",
        description: "Design your own cake",
      },
      {
        sectionId: secServices.id,
        sortOrder: 2,
        rowId: "btn_status",
        title: "📦 Track My Order",
        description: "Check your history",
      },
    ],
  });

  // 2. Unpaid Checkout Confirmation Template
  const unpaidTemplate = await prisma.whatsAppTemplate.upsert({
    where: { code_language: { code: "ORDER_CONFIRMED_UNPAID", language: "en" } },
    update: { isActive: true },
    create: {
      code: "ORDER_CONFIRMED_UNPAID",
      language: "en",
      description: "Checkout completion payment invoice screen.",
      category: "PAYMENT",
      isActive: true,
    },
  });

  const unpaidVersion = await prisma.whatsAppTemplateVersion.create({
    data: {
      templateId: unpaidTemplate.id,
      versionNumber: 1,
      bodyText: "🎉 *Order #{{order_id}} Placed!*\n\n📅 *{{delivery_date}}* | 🕒 *{{delivery_slot}}*\n📍 {{delivery_address}}\n\n💳 Pay *{{total_amount}}* to confirm your order. ✅",
      interactiveType: "CTA_URL",
      ctaButtonTitle: "💳 Pay Now",
      ctaButtonUrl: "{{payment_link}}",
      changeLog: "Initial payment checkout layout",
      createdBy: "System Migration",
    },
  });

  await prisma.whatsAppTemplate.update({
    where: { id: unpaidTemplate.id },
    data: { activeVersionId: unpaidVersion.id },
  });

  console.log("Seeding Dynamic WhatsApp Templates finished successfully!");
  console.log('Seeding finished.');
}


main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
