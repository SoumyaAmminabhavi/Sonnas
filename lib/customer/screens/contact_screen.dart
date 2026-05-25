import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  
  // Brand Colors
  Color get primaryColor => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get secondaryColor => Theme.of(context).colorScheme.onSurface;
  Color get backgroundColor => Theme.of(context).colorScheme.surface;

  List<Map<String, dynamic>> _realCakes = [];
  bool _isFetchingCakes = true;
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchRealCakes();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _feedbackController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealCakes() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        setState(() => _isFetchingCakes = false);
        return;
      }

      // Fetch actual past items from user's most recent order
      final userPhone = currentUser.userMetadata?['phone']?.toString() ?? currentUser.phone ?? '';
      final orderResponse = await supabase
          .from('WhatsAppOrder')
          .select('items:WhatsAppOrderItem(*)')
          .eq('phone', userPhone)
          .order('createdAt', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted && orderResponse != null) {
        final items = orderResponse['items'] as List? ?? [];
        setState(() {
          _realCakes = items.take(2).map((item) {
            return {
              'name': (item['cakeName'] as String?) ?? 'Exquisite Creation',
              'price': double.tryParse(item['price'].toString()) ?? 0.0,
              'image': '', // Historical items don't have images in the schema
            };
          }).toList();
          _isFetchingCakes = false;
        });
      } else if (mounted) {
        setState(() => _isFetchingCakes = false);
      }
    } catch (e) {
      debugPrint("Error fetching cakes for support: $e");
      if (mounted) setState(() => _isFetchingCakes = false);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!['tel', 'https', 'mailto'].contains(uri.scheme)) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) debugPrint('Could not launch $url');
  }

  void _handleOrderAgain() {
    if (_realCakes.isEmpty) return;
    
    for (var item in _realCakes) {
      final String name = item['name']?.toString() ?? 'Exquisite Creation';
      final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final String image = item['image']?.toString() ?? '';
      
      ref.read(customerCartProvider.notifier).addItem(
        "reorder_$name", 
        name, 
        price, 
        image,
        quantity: 1, // Past items are added one by one from this list
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Re-added ${_realCakes.length} items to your bag!"),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.push(
        context, 
        MaterialPageRoute<void>(builder: (context) => const CartScreen())
      );
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        
        final user = supabase.auth.currentUser;
        final String phone = user?.userMetadata?['phone']?.toString() ?? user?.phone ?? '';
        
        await supabase.from('SupportReport').insert({
          'title': _subjectController.text,
          'message': _messageController.text,
          'user_phone': phone,
          'status': 'PENDING',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });

        if (!mounted) return;
        
        unawaited(showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Report Submitted", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold)),
            content: Text("We've received your report. Our support team will review it and get back to you within 24 hours.", 
              style: GoogleFonts.plusJakartaSans()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _orderIdController.clear();
                  _messageController.clear();
                  _subjectController.clear();
                },
                child: Text("OK", style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        ));
      } catch (e) {
        debugPrint("Report submission error: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Problem submitting report. Please try again later."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleFeedback(double rating) async {
    try {
      final supabase = Supabase.instance.client;
      
      final user = supabase.auth.currentUser;
      final String phone = user?.userMetadata?['phone']?.toString() ?? user?.phone ?? '';

      await supabase.from('Feedback').insert({
        'rating': rating,
        'message': _feedbackController.text,
        'user_phone': phone,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _userRating = rating);
      
      unawaited(showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Thank You!", style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold, color: secondaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite, color: primaryColor, size: 48),
              const SizedBox(height: 16),
              Text("We appreciate your $rating-star rating! Your feedback helps us bake better moments for you.", 
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _userRating = 0);
              },
              child: Text("CLOSE", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ));
    } catch (e) {
      debugPrint("Feedback submission error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit feedback. Please try again later."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Support & Quick Reorder",
          style: GoogleFonts.notoSerif(color: secondaryColor, fontSize: 18, fontStyle: FontStyle.italic),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isFetchingCakes && _realCakes.isNotEmpty) _buildOrderAgainSection(),
            const SizedBox(height: 40),
            _buildSearchBar(),
            const SizedBox(height: 40),
            _buildSectionHeader("Common Questions"),
            const SizedBox(height: 16),
            _buildFaqItem("How do I track my order?", "Go to 'My Orders' in your profile and tap on the active order to see real-time updates."),
            _buildFaqItem("Can I cancel my order?", "Cancellations are accepted up to 2 hours after placing the order for standard items."),
            _buildFaqItem("Refund Timeline?", "Refunds usually take 5-7 business days to reflect in your original payment method."),
            const SizedBox(height: 40),
            _buildSectionHeader("Contact Us"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildContactBtn(Icons.phone_outlined, "Call", () => _launch("tel:+919113231424"))),
                const SizedBox(width: 12),
                Expanded(child: _buildContactBtn(Icons.chat_bubble_outline, "WhatsApp", () => _launch("https://wa.me/919113231424"))),
              ],
            ),
            const SizedBox(height: 40),
            _buildComplaintForm(),
            const SizedBox(height: 40),
            _buildVisitSection(),
            const SizedBox(height: 40),
            _buildFeedbackSection(),
            const SizedBox(height: 60),
            Center(
              child: Text(
                "Sonna's Patisserie Support\nAvailable 9 AM - 9 PM",
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: secondaryColor.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderAgainSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: secondaryColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RECOMMENDED FOR YOU", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Icon(Icons.star, color: primaryColor, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Text("Quickly add your favorites back to your bag.", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _handleOrderAgain,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text("ADD FAVORITES TO BAG", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: secondaryColor.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search for help...",
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.notoSerif(fontSize: 20, fontWeight: FontWeight.bold, color: secondaryColor),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(q, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: secondaryColor)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(a, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: secondaryColor.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: secondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Report an Issue", style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryColor)),
            const SizedBox(height: 20),
            _buildSimpleField("Subject", controller: _subjectController),
            const SizedBox(height: 12),
            _buildSimpleField("Describe the issue...", controller: _messageController, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("SUBMIT REPORT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Visit Us", style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text("4.8 (690)", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[800])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Sonna's Patisserie and Cafe", style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: secondaryColor)),
          Text("Bakery and Cake Shop • ₹200–400 per person", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: secondaryColor.withValues(alpha: 0.5))),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.location_on_outlined, "4TH Phase, Shop No. 5,6,7 Ground Floor, \"Aum Shree\" Apartment, Akshay Colony, Unkal, Hubballi, Karnataka 580021"),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time, "Mon, Wed-Sat: 2:00 PM – 10:00 PM\nSun: 2:00 PM – 10:30 PM\nTue: Closed"),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSocialIcon(Icons.camera_alt_outlined, "https://instagram.com/sonnas__"),
              const SizedBox(width: 16),
              _buildSocialIcon(Icons.map_outlined, "https://maps.google.com/?q=Sonna's+Patisserie+and+Cafe+Akshay+Colony"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: secondaryColor.withValues(alpha: 0.7)))),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launch(url),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
        child: Icon(icon, color: secondaryColor, size: 20),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor.withValues(alpha: 0.1), Colors.white]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Your feedback matters!", style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.bold, color: secondaryColor)),
          const SizedBox(height: 8),
          Text("How was your experience today?", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: secondaryColor.withValues(alpha: 0.5))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final ratingValue = i + 1.0;
              return IconButton(
                onPressed: () => _handleFeedback(ratingValue),
                icon: Icon(
                  i < _userRating ? Icons.star : Icons.star_border,
                  color: primaryColor,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          _buildSimpleField("Share your experience...", controller: _feedbackController, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildSimpleField(String hint, {required TextEditingController controller, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter $hint";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: backgroundColor.withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
