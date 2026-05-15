import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';

class ProductOption {
  final String size;
  final int price;

  ProductOption({required this.size, required this.price});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      size: json['size']?.toString() ?? '',
      price: int.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  final String? cakeId;
  final String title;
  final String price;
  final String imageUrl;
  final List<ProductOption> options;

  ProductDetailScreen({
    super.key,
    this.cakeId,
    required this.title,
    required this.price,
    required this.imageUrl,
    List<dynamic> rawOptions = const [],
  }) : options = rawOptions
            .where((o) => o is Map<String, dynamic>)
            .map((o) => ProductOption.fromJson(o as Map<String, dynamic>))
            .toList();

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = "";
  double currentPriceValue = 0.0;
  String currentPriceDisplay = "";
  int quantity = 1;
  final TextEditingController _messageController = TextEditingController();
  
  // Customizer State
  String selectedDietary = "Standard";
  final Map<String, bool> selectedAddons = {
    "Sparkling Candles": false,
    "Custom Topper": false,
    "Gift Card": false,
  };
  final Map<String, int> addonPrices = {
    "Sparkling Candles": 5000, // in paise
    "Custom Topper": 10000,
    "Gift Card": 3000,
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.options.isNotEmpty) {
      selectedSize = widget.options[0].size;
      currentPriceValue = widget.options[0].price / 100.0;
    } else {
      // Fallback: parse price string like "₹ 650.00"
      final cleanPrice = widget.price.replaceAll('₹', '').replaceAll(',', '').trim();
      currentPriceValue = double.tryParse(cleanPrice) ?? 0.0;
      selectedSize = "Standard";
    }
    _updatePriceDisplay();
  }


  void _updatePriceDisplay() {
    double basePrice = currentPriceValue;
    double addonsTotal = 0.0;
    
    selectedAddons.forEach((name, isSelected) {
      if (isSelected) {
        addonsTotal += (addonPrices[name] ?? 0) / 100.0;
      }
    });

    currentPriceDisplay = "₹${((basePrice + addonsTotal) * quantity).toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color accentRed = Color(0xFFEF4F5F);

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          // Close area
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          
          // Close button
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF333333),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),

          // Modal Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600), // Neat alignment on web
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Container - Ensuring whole cake is visible
                          Container(
                            width: double.infinity,
                            height: 320,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                widget.imageUrl,
                                fit: BoxFit.contain, // Show whole image
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 320,
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.cake, color: primaryColor, size: 64),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Badge
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.brown.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.stop_circle_outlined, color: Colors.brown.shade800, size: 12),
                          ),
                          const SizedBox(height: 8),
                          
                          // Title Section
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                               Consumer<FavoritesProvider>(
                                builder: (context, favorites, _) {
                                  final isFav = favorites.isFavorite(null, widget.title);
                                  return GestureDetector(
                                    onTap: () => favorites.toggleFavorite({
                                      'id': null,
                                      'title': widget.title,
                                      'price': widget.price,
                                      'image': widget.imageUrl,
                                    }),
                                    child: _buildActionBtn(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      iconColor: isFav ? primaryColor : Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildActionBtn(Icons.reply_outlined),
                            ],
                          ),
                          
                          // Reordered Status
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B8D43),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Highly reordered",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Portion Selector
                          _buildTitle("CHOOSE YOUR PORTION"),
                          const SizedBox(height: 8),
                          ...widget.options.map((opt) {
                            final isSelected = selectedSize == opt.size;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSize = opt.size;
                                  currentPriceValue = opt.price / 100.0;
                                  _updatePriceDisplay();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opt.size,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                          color: isSelected ? Colors.black : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "₹${(opt.price / 100.0).toStringAsFixed(2)}",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: isSelected ? accentRed : Colors.grey.shade300,
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 24),
                          
                          // Custom Message
                          _buildHeaderRow("Message on Cake (Optional)", Icons.cake_outlined),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryColor.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _messageController,
                                  maxLines: 2,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "Handwritten message on cake...",
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 14, 
                                      color: Colors.grey.shade400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Dietary Preferences
                          _buildTitle("DIETARY PREFERENCE"),
                          const SizedBox(height: 12),
                          Row(
                            children: ["Standard", "Eggless", "Less Sugar"].map((diet) {
                              final isSel = selectedDietary == diet;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(diet, style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? Colors.white : Colors.black87,
                                  )),
                                  selected: isSel,
                                  selectedColor: primaryColor,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: isSel ? primaryColor : Colors.grey.shade300),
                                  onSelected: (val) {
                                    if (val) setState(() => selectedDietary = diet);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Add-ons
                          _buildTitle("CELEBRATION ADD-ONS"),
                          const SizedBox(height: 8),
                          ...selectedAddons.keys.map((addon) {
                            final isSel = selectedAddons[addon]!;
                            return CheckboxListTile(
                              value: isSel,
                              title: Text(addon, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                              subtitle: Text("+ ₹${(addonPrices[addon]! / 100).toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              activeColor: primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                setState(() {
                                  selectedAddons[addon] = val ?? false;
                                  _updatePriceDisplay();
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...["Happy Birthday", "Happy Anniversary", "Congratulations", "Best Wishes",].map((tag) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(tag, style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: primaryColor.withOpacity(0.8),
                                    )),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    side: BorderSide(color: primaryColor.withOpacity(0.1)),
                                    onPressed: () => _messageController.text = tag,
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  
                  // Sticky Bottom Bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Row(
                      children: [
                        // Qty
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: accentRed.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              _buildQtyIcon(Icons.remove, () {
                                if (quantity > 1) setState(() { quantity--; _updatePriceDisplay(); });
                              }),
                              SizedBox(width: 32, child: Center(child: Text("$quantity", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: accentRed)))),
                              _buildQtyIcon(Icons.add, () {
                                setState(() { quantity++; _updatePriceDisplay(); });
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add item
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final String message = _messageController.text.trim();
                              String addonsText = selectedAddons.entries
                                  .where((e) => e.value)
                                  .map((e) => e.key)
                                  .join(", ");
                              
                              String fullDescription = "${widget.title} ($selectedSize)";
                              if (selectedDietary != "Standard") {
                                fullDescription += " - $selectedDietary";
                              }
                              if (message.isNotEmpty) {
                                fullDescription += "\nMessage: $message";
                              }
                              if (addonsText.isNotEmpty) {
                                fullDescription += "\nAdd-ons: $addonsText";
                              }

                              double addonsTotal = selectedAddons.entries
                                  .where((e) => e.value)
                                  .fold(0.0, (prev, e) => prev + (addonPrices[e.key]! / 100.0));

                              context.read<CartProvider>().addItem(
                                "${widget.title}_${DateTime.now().millisecondsSinceEpoch}", 
                                fullDescription, 
                                (currentPriceValue + addonsTotal) * 100, 
                                widget.imageUrl,
                                quantity: quantity,
                                cakeId: widget.cakeId,
                              );
                              
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("${widget.title} added with customizations!"), 
                                backgroundColor: accentRed, 
                                behavior: SnackBarBehavior.floating
                              ));
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(color: accentRed, borderRadius: BorderRadius.circular(8)),
                              child: Center(
                                child: Text("Add item $currentPriceDisplay", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, {Color? iconColor}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: iconColor ?? Colors.grey.shade600),
    );
  }

  Widget _buildTitle(String title) {
    return Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800));
  }

  Widget _buildHeaderRow(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
        Icon(icon, size: 18, color: Colors.grey.shade400),
      ],
    );
  }

  Widget _buildQtyIcon(IconData icon, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(icon, size: 18, color: const Color(0xFFEF4F5F))));
  }
}
