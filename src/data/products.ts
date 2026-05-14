export interface ProductOption {
  size: string;
  serves: string;
  price: number;
}

export interface Product {
  id: number;
  name: string;
  description: string;
  category: string;
  options: ProductOption[];
  image: string;
  isAvailable?: boolean;
  sortOrder?: number;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
  image: string;
}

export const products: Product[] = [

  {
    id: 1,
    name: "Sonna’s Classic Chocolate",
    description: "Chocolate cake with whipped ganache",
    category: "Chocolate Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 67500 },
      { size: "1050g", serves: "8-12", price: 125000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/classic-chocolate.png",
  },
  {
    id: 2,
    name: "Almond Brittle with Salted Caramel Ganache",
    description: "Caramel chocolate ganache + almond brittle",
    category: "Chocolate Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/almond-brittle.png",
  },
  {
    id: 3,
    name: "Orange & Chocolate",
    description: "Chocolate cake with orange ganache",
    category: "Chocolate Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/orange-chocolate.png",
  },
  {
    id: 4,
    name: "Hazelnut & Chocolate",
    description: "Chocolate cake with hazelnut ganache",
    category: "Chocolate Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/hazelnut-chocolate.png",
  },
  {
    id: 5,
    name: "Coffee & Chocolate",
    description: "Chocolate cake with coffee ganache",
    category: "Chocolate Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/coffee-chocolate.png",
  },
  {
    id: 6,
    name: "Caramalised White Chocolate with Almonds",
    description: "Vanilla cake with white chocolate ganache",
    category: "Vanilla Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/white-chocolate.png",
  },
  {
    id: 7,
    name: "Pina Colada",
    description: "Coconut & pineapple mousse cake",
    category: "Vanilla Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/pina-colada.png",
  },
  {
    id: 8,
    name: "Pineapple",
    description: "Pineapple compote vanilla cake",
    category: "Vanilla Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/pineapple.png",
  },
  {
    id: 9,
    name: "Rich Mawa",
    description: "Mawa cake with almond flour & cardamom",
    category: "Tea Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/rich-mawa.png",
  },
  {
    id: 10,
    name: "Persian Cake",
    description: "Almond + orange + mawa cake",
    category: "Tea Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/persian-cake.png",
  },
  {
    id: 11,
    name: "Butter Cake",
    description: "Classic butter cake",
    category: "Tea Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/butter-cake.png",
  },
  {
    id: 12,
    name: "Strawberry & Chocolate",
    description: "Strawberry compote + chocolate ganache",
    category: "Seasonal Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/strawberry-chocolate.png",
  },
  {
    id: 13,
    name: "Strawberry & Vanilla",
    description: "Strawberry + vanilla cake",
    category: "Seasonal Cakes",
    options: [
      { size: "600g", serves: "4-6", price: 75000 },
      { size: "1050g", serves: "8-12", price: 135000 }
    ],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/strawberry-vanilla.png",
  },
  // Mini Cheesecakes
  {
    id: 14,
    name: "Blueberry",
    description: "Creamy cheesecake with glossy blueberry compote",
    category: "Mini Cheesecakes",
    options: [{ size: "Single", serves: "1", price: 17000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/mini-cheesecake-blueberry.png",
  },
  {
    id: 15,
    name: "Nutella",
    description: "Nutella flavor with smooth hazelnut chocolate swirl",
    category: "Mini Cheesecakes",
    options: [{ size: "Single", serves: "1", price: 18000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/mini-cheesecake-nutella.png",
  },
  {
    id: 16,
    name: "Biscoff",
    description: "Lotus Biscoff flavor with speculoos cookie spread drip",
    category: "Mini Cheesecakes",
    options: [{ size: "Single", serves: "1", price: 19000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/mini-cheesecake-biscoff.png",
  },
  {
    id: 17,
    name: "Mango",
    description: "Fresh Mango flavor with vibrant yellow mango glaze",
    category: "Mini Cheesecakes",
    options: [{ size: "Single", serves: "1", price: 16000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/mini-cheesecake-mango.png",
  },
  // Slices
  {
    id: 18,
    name: "Almond Brittle with Salted Caramel Ganache",
    description: "Almond Brittle with Salted Caramel Ganache slice",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 17500 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-almond-brittle.png",
  },
  {
    id: 19,
    name: "Chocolate Mousse",
    description: "Deep dark chocolate layers with airy mousse texture",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 14500 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-chocolate-mousse.png",
  },
  {
    id: 20,
    name: "Chocolate & Orange",
    description: "Layers of chocolate and bright orange mousse",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 12000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-chocolate-orange.png",
  },
  {
    id: 21,
    name: "Lemon Mousse",
    description: "Bright yellow and white layers with tangy lemon curd",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 9500 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-lemon-mousse.png",
  },
  {
    id: 22,
    name: "Macaron",
    description: "Elegant macaron-themed cake slice",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 8000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-macaron.png",
  },
  {
    id: 23,
    name: "Coconut & Mango",
    description: "Layers of tropical coconut sponge and fresh mango mousse",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 18000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-coconut-mango.png",
},
  {
    id: 100,
    name: "Chocolate Cake Slice",
    description: "Classic chocolate cake slice",
    category: "Slices",
    options: [{ size: "Slice", serves: "1", price: 13500 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/slice-chocolate-mousse.png", // Fallback image
  },
  {
    id: 101,
    name: "Panipoori",
    description: "Crispy puris filled with spicy tangy water and potato mash",
    category: "Chaat",
    options: [{ size: "Plate", serves: "1", price: 10000 }],
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cake_1778742803857.jpg",
  },
];

export const categories: Category[] = [

  {
    id: "chocolate",
    name: "Chocolate Cakes",
    slug: "chocolate-cakes",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cat-chocolate.png",
  },
  {
    id: "vanilla",
    name: "Vanilla Cakes",
    slug: "vanilla-cakes",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cat-vanilla.png",
  },
  {
    id: "tea",
    name: "Tea Cakes",
    slug: "tea-cakes",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cat-tea.png",
  },
  {
    id: "seasonal",
    name: "Seasonal Cakes",
    slug: "seasonal-cakes",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cat-seasonal.png",
  },
  {
    id: "cheesecakes",
    name: "Mini Cheesecakes",
    slug: "mini-cheesecakes",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cat-mini-cheesecakes.png",
  },
  {
    id: "slices",
    name: "Slices",
    slug: "slices",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cat-slices.png",
  },
  {
    id: "chaat",
    name: "Chaat",
    slug: "chaat",
    image: "https://qwqsarpzcwwpgyimhxzn.supabase.co/storage/v1/object/public/cakes/cake_1778742803857.jpg",
  },
];
