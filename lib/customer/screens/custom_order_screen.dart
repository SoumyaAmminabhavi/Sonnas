import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CustomOrderScreen extends StatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  String? selectedSize = "Petit (4-6 guests)";
  String? selectedFlavor = "Valrhona Dark Chocolate";
  final _narrativeController = TextEditingController();
  final _nameController = TextEditingController();
  final _flavorController = TextEditingController();
  final _designController = TextEditingController();
  String? selectedOccasion;

  bool _isSubmitting = false;

  Future<void> _submitQuoteRequest() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a pick-up date for your creation"),
          backgroundColor: Color(0xFFFF4D8D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_narrativeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please share some details about your vision"),
          backgroundColor: Color(0xFFFF4D8D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      final phone = currentUser?.userMetadata?['phone']?.toString() ?? '';

      await supabase.from('CustomOrderQuote').insert({
        'customerName': currentUser?.userMetadata?['name'] ?? 'Bespoke Patron',
        'phone': phone,
        'occasion': selectedOccasion ?? 'Artisan Creation',
        'expectedDate': selectedDate?.toIso8601String(),
        'cakeSize': selectedSize,
        'flavorPreference': selectedFlavor ?? 'Chef\'s Choice',
        'designNotes': _narrativeController.text.trim(),
        'status': 'PENDING',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Quote Requested", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
            content: Text(
              "Your vision has been shared with our master artisans. We will review your request and provide a curated quote within 24 hours.",
              style: GoogleFonts.plusJakartaSans(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to home/menu
                },
                child: const Text("EXQUISITE", style: TextStyle(color: Color(0xFFFF4D8D))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Custom Order Error: $e");
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit quote request. Please try again later."),
            backgroundColor: Color(0xFFFF4D8D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _narrativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFFF4D8D);
    const Color primaryContainerColor = Color(0xFFFFB6D3);
    const Color surfaceColor = Color(0xFFFFF0F6);
    const Color onSurfaceColor = Color(0xFF701235);
    const Color secondaryColor = Color(0xFF701235);
    const Color outlineVariantColor = Color(0xFFD8C1C6);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        slivers: [
          // Top App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: surfaceColor.withValues(alpha: 0.9),
            surfaceTintColor: Colors.transparent,
            leading: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.bakery_dining, color: primaryColor),
            ),
            centerTitle: true,
            title: Text(
              "Sonna’s Patisserie",
              style: GoogleFonts.notoSerif(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.account_circle_outlined, color: primaryColor),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BESPOKE CREATIONS",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your Vision,\nOur Craft.",
                      style: GoogleFonts.notoSerif(
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Design a masterpiece for your special occasion. Share your inspiration and let our pastry chefs bring it to life with artisan precision.",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: secondaryColor,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Visual Inspiration
                _buildSectionHeader("Visual Inspiration", "REFERENCE IMAGES"),
                const SizedBox(height: 16),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E9).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: outlineVariantColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFFFF4D8D)),
                      const SizedBox(height: 16),
                      Text(
                        "Drop your references here",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Supported: JPG, PNG, HEIC",
                        style: GoogleFonts.notoSerif(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: secondaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // The Narrative
                _buildSectionHeader("The Narrative", "DETAILS & SPECIAL REQUESTS"),
                const SizedBox(height: 16),
                TextField(
                  controller: _narrativeController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Describe your cake (colors, theme, flavor nuances...)",
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: secondaryColor.withValues(alpha: 0.4),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: outlineVariantColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 48),

                // Bento Selectors
                Column(
                  children: [
                    _buildSelectorTile(
                      icon: Icons.calendar_today_outlined,
                      label: "Pick-up Date",
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: Text(
                        selectedDate == null ? "mm/dd/yyyy" : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selectedDate == null ? secondaryColor.withValues(alpha: 0.4) : secondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectorTile(
                      icon: Icons.groups_outlined,
                      label: "Serving Size",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSize,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: secondaryColor),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: secondaryColor, fontWeight: FontWeight.w500),
                          items: ["Petit (4-6 guests)", "Moyen (8-12 guests)", "Grand (15-20 guests)", "Royal (25+ guests)"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => selectedSize = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectorTile(
                      icon: Icons.restaurant_menu_outlined,
                      label: "Flavor Base",
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Valrhona Dark Chocolate",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: secondaryColor,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 20, color: secondaryColor),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Price Estimate & CTA
                Container(
                  padding: const EdgeInsets.only(top: 32),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: outlineVariantColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryContainerColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info_outline, color: primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Awaiting curation",
                                  style: GoogleFonts.notoSerif(
                                    fontSize: 18,
                                    fontStyle: FontStyle.italic,
                                    color: secondaryColor,
                                  ),
                                ),
                                Text(
                                  "Quote will be provided within 24 hours",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: secondaryColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitQuoteRequest,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSubmitting 
                                ? [Colors.grey, Colors.grey.shade400]
                                : [primaryColor, primaryContainerColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSubmitting 
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  "REQUEST QUOTE",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 64),

                // Editorial Imagery
                SizedBox(
                  height: 400,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            "https://lh3.googleusercontent.com/aida-public/AB6AXuBbqzXmEiwTneHs-kyzl1RNKu84YHE6NsD362qIOyZY1IkQgJgWC6S1l3I_SCm0uH94rxjhDeRxo_QRhZAup_Iv9_6FDnzHjM3hy45kWdFeUPfHa4giQmfFKIn-b9ccC4ZW8Y0QU5EifpbpvCTmBBMTO7XNIxYC97BbYdzBeNTt50lJLRZc_0PSWmFVucB0Xqt-aBm_jjLK4w_HYKnNLh5eGPoAhjlHEEjoZ3gv2QvoWD9dt4Xd0-CwNLOU01G-A0rMB5R15LQJ8GjN",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  "https://lh3.googleusercontent.com/aida-public/AB6AXuApeefJ_i0ql7-wm6I6la5Oz8IaLv22WgugzMNaKLQeeCnvmjC95LquVwnebNS6yljiChY0-kTjTpIG3KiUaIPfEc5TCH_KANJEeN63AW9ykC2v3pjTedV_aoZaVI5Uw9SmHju4CJH9vhhPtrSFXQ6onqRwC4teSk5eKh7_GS7JNolz5Et3jwh-yGmYMinMdoQX8dVNqyWXBlFFPBhsl6HQpo10n6ZsqIkywJI8A7DMzRiove7DWkzWVFNAizvhI6fbz7bS7Ody83iw",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEADD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "\"Pâtisserie is an art where flavor meets architecture.\"",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 18,
                                        fontStyle: FontStyle.italic,
                                        color: primaryColor,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "— Chef de Cuisine",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                        color: secondaryColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 64),
              ]),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFFFF1E9),
              padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFooterLink("THE MENU"),
                      const SizedBox(width: 24),
                      _buildFooterLink("OUR STORY"),
                      const SizedBox(width: 24),
                      _buildFooterLink("CONTACT"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "© 2024 Sonna's Patisserie. Crafted for Sensory Delight.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                      color: primaryColor,
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

  Widget _buildSectionHeader(String title, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSerif(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF701235),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: const Color(0xFF701235).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorTile({required IconData icon, required String label, required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFF4D8D)),
            const SizedBox(height: 12),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: const Color(0xFF701235).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFD8C1C6).withValues(alpha: 0.3)),
                ),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: const Color(0xFF701235),
      ),
    );
  }
}
