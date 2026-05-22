class Product {
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String tag;
  final double price;

  Product({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.tag,
    required this.price,
  });

  static List<Product> samples = [
    Product(
      name: "Belgian Chocolate",
      description: "Rich cocoa sponge with silky ganache layers.",
      imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=1000&auto=format&fit=crop",
      category: "Mini Cakes",
      tag: "Bestseller",
      price: 180.0,
    ),
    Product(
      name: "Wildberry Sensation",
      description: "Vanilla bean cake topped with hand-picked berries.",
      imageUrl: "https://images.unsplash.com/photo-1535141192574-5d4897c12636?q=80&w=1000&auto=format&fit=crop",
      category: "Artisan Slices",
      tag: "New",
      price: 170.0,
    ),
    Product(
      name: "Nutella Swirl",
      description: "Hazelnut goodness with a buttery biscuit base.",
      imageUrl: "https://images.unsplash.com/photo-1551024506-0bccd828d307?q=80&w=1000&auto=format&fit=crop",
      category: "Mini Cakes",
      tag: "Limited",
      price: 190.0,
    ),
    Product(
      name: "Salted Caramel",
      description: "Sweet and salty perfection in every bite.",
      imageUrl: "https://images.unsplash.com/photo-1559620192-032c4bc4674e?q=80&w=1000&auto=format&fit=crop",
      category: "Macarons",
      tag: "Classic",
      price: 85.0,
    ),
    Product(
      name: "Matcha Zen",
      description: "Earthy matcha mousse with a light sponge.",
      imageUrl: "https://images.unsplash.com/photo-1517433670267-08bbd4be890f?q=80&w=1080&auto=format&fit=crop",
      category: "Mousses",
      tag: "Aesthetic",
      price: 210.0,
    ),
    Product(
      name: "Rose Petal Slice",
      description: "Infused with organic rose water and edible petals.",
      imageUrl: "https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=1000&auto=format&fit=crop",
      category: "Artisan Slices",
      tag: "Signature",
      price: 165.0,
    ),
    Product(
      name: "Pistachio Dream",
      description: "Crunchy pistachio bits and creamy white chocolate.",
      imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=1000&auto=format&fit=crop",
      category: "Mini Cakes",
      tag: "Chef's Choice",
      price: 220.0,
    ),
    Product(
      name: "Lemon Drizzle",
      description: "Zesty lemon glaze over a soft citrus sponge.",
      imageUrl: "https://images.unsplash.com/photo-1535141192574-5d4897c12636?q=80&w=1000&auto=format&fit=crop",
      category: "Artisan Slices",
      tag: "Refreshing",
      price: 155.0,
    ),
  ];
}
