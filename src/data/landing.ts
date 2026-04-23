export const navLinks = [
  { name: "Home", href: "#home" },
  { name: "Cakes", href: "#cakes" },
  { name: "Custom Orders", href: "#highlight" },
  { name: "About", href: "#about" },
  { name: "Contact", href: "#footer" },
];

export const products = [
  {
    id: 1,
    name: "Sonna's Classic Chocolate",
    description: "Classic chocolate cake layered with silky chocolate whipped ganache. A timeless favourite.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Classic+Chocolate",
  },
  {
    id: 2,
    name: "Almond Brittle with Salted Caramel Ganache",
    description: "A Sonna's original: In house caramel almond brittle with caramel chocolate ganache and chocolate whipped ganache.",
    options: [
      { size: "600g", serves: "4-6", price: "₹675" },
      { size: "1050g", serves: "8-12", price: "₹1,250" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Almond+Brittle",
  },
  {
    id: 3,
    name: "Orange & Chocolate",
    description: "Classic chocolate cake infused with orange, layered with chocolate whipped ganache.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Orange+Chocolate",
  },
  {
    id: 4,
    name: "Hazelnut & Chocolate",
    description: "Rich chocolate cake generously layered with hazelnut ganache.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Hazelnut+Chocolate",
  },
  {
    id: 5,
    name: "Coffee & Chocolate",
    description: "Chocolate cake layered with rich coffee chocolate whipped ganache.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Coffee+Chocolate",
  },
  {
    id: 6,
    name: "Caramelised White Chocolate with Almonds",
    description: "Vanilla cake layered with caramelised white chocolate ganache. Almonds are optional.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=White+Choc+Almond",
  },
  {
    id: 7,
    name: "Pina Colada",
    description: "Vanilla cake layered with coconut & pineapple mousse, topped with fresh pineapple.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Pina+Colada",
  },
  {
    id: 8,
    name: "Pineapple",
    description: "Vanilla cake layered with pineapple compote whipped ganache and fresh pineapple.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Pineapple",
  },
  {
    id: 9,
    name: "Rich Mawa",
    description: "Indian inspired mawa cake made with almond flour, all purpose flour, cardamom & butter.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Rich+Mawa",
  },
  {
    id: 10,
    name: "Persian Cake",
    description: "A rich aromatic cake made with almond flour, orange juice, cardamom & butter.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Persian+Cake",
  },
  {
    id: 11,
    name: "Butter Cake",
    description: "Classic butter cake baked with butter, butter and lots of love.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Butter+Cake",
  },
  {
    id: 12,
    name: "Strawberry & Vanilla",
    description: "Vanilla cake layered with strawberry whipped ganache and fresh strawberries.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Strawberry+Vanilla",
  },
  {
    id: 13,
    name: "Strawberry & Chocolate",
    description: "Chocolate cake layered with strawberry compote, chocolate ganache and fresh strawberries.",
    options: [
      { size: "600g", serves: "4-6", price: "₹750" },
      { size: "1050g", serves: "8-12", price: "₹1,350" }
    ],
    image: "https://placehold.co/800x800/FAF6F0/54433A?text=Strawberry+Chocolate",
  },
];

export const categories = [
  {
    id: "bday",
    name: "Birthday Celebrations",
    slug: "birthday-cakes",
    image: "/images/cat-bday.png",
  },
  {
    id: "wedding",
    name: "Royal Weddings",
    slug: "wedding-cakes",
    image: "/images/cat-wedding.png",
  },
  {
    id: "pastries",
    name: "Indian Fusion Pastries",
    slug: "pastries",
    image: "/images/cat-pastries.png",
  },
];
