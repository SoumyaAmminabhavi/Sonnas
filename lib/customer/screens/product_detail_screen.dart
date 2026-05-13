import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String title;
  final String price;
  final String imageUrl;
  final List<dynamic> options;

  const ProductDetailScreen({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
    this.options = const [],
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String selectedSize = "";
  double currentPriceValue = 0.0;
  String currentPriceDisplay = "";
  int quantity = 1;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.options.isNotEmpty) {
      selectedSize = widget.options[0]['size']?.toString() ?? "";
      currentPriceValue = _parsePrice(widget.options[0]['price']);
      _updatePriceDisplay();
    }
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    String priceStr = price.toString().replaceAll('₹', '').replaceAll('INR', '').replaceAll(',', '').trim();
    return (double.tryParse(priceStr) ?? 0.0) / 100.0;
  }

  void _updatePriceDisplay() {
    currentPriceDisplay = "₹${(currentPriceValue * quantity).toStringAsFixed(2)}";
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
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Badge
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.brown.withValues(alpha: 0.3)),
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
                              _buildActionBtn(Icons.bookmark_outline),
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
                            final size = opt['size']?.toString() ?? "";
                            final price = opt['price']?.toString() ?? "0";
                            final isSelected = selectedSize == size;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSize = size;
                                  currentPriceValue = _parsePrice(price);
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
                                        size,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                          color: isSelected ? Colors.black : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      "₹${((double.tryParse(price.toString()) ?? 0.0) / 100.0).toStringAsFixed(2)}",
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
                          _buildHeaderRow("Add a custom message (optional)", Icons.info_outline),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F2F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _messageController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: "e.g. Happy Birthday Soumya!",
                                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text("100", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...["Happy Birthday", "Eggless", "Less Sugar", "Extra Cream"].map((tag) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: Colors.grey.shade200),
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Row(
                      children: [
                        // Qty
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(color: accentRed.withValues(alpha: 0.2)),
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
                              final String id = "${widget.title}_${selectedSize}_${_messageController.text}";
                              for (int i = 0; i < quantity; i++) {
                                context.read<CartProvider>().addItem(id, "${widget.title} ($selectedSize)", currentPriceValue * 100, widget.imageUrl);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${widget.title} added to bag"), backgroundColor: accentRed, behavior: SnackBarBehavior.floating));
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

  Widget _buildActionBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: Colors.grey.shade600),
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
