import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Brand Colors - Sweet Pink Bakery Theme
const Color _primaryColor = Color(0xFFFF4D8D);
const Color _secondaryColor = Color(0xFF701235);

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return _AddMenuContent(isDesktop: isDesktop);
      },
    );
  }
}

class _AddMenuContent extends StatefulWidget {
  final bool isDesktop;

  const _AddMenuContent({required this.isDesktop});

  @override
  State<_AddMenuContent> createState() => _AddMenuContentState();
}

class _AddMenuContentState extends State<_AddMenuContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _categoryController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _nameController = TextEditingController();
  final _flavorsController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _servesController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _subtitleController.dispose();
    _nameController.dispose();
    _flavorsController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _servesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      final rawPrice = _priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final priceInRupees = double.tryParse(rawPrice) ?? 0.0;
      
      if (priceInRupees <= 0) {
        throw Exception("Please enter a valid price greater than zero.");
      }

      final priceInPaise = (priceInRupees * 100).toInt();
      
      // 1. Insert the main Cake entry
      final cakeResponse = await supabase.from('Cake').insert({
        'name': _nameController.text.trim(),
        'slug': _nameController.text.trim().toLowerCase().replaceAll(' ', '-'),
        'description': _descriptionController.text.trim(),
        'image': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587', 
        'category': _categoryController.text.trim(),
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }).select().single();

      final cakeId = cakeResponse['id'];

      // 2. Insert the CakeOption (Price/Size)
      await supabase.from('CakeOption').insert({
        'cakeId': cakeId,
        'size': 'Standard',
        'price': priceInPaise,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cake added successfully to Boutique Menu!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _categoryController.clear();
        _subtitleController.clear();
        _nameController.clear();
        _flavorsController.clear();
        _priceController.clear();
        _descriptionController.clear();
        _weightController.clear();
        _servesController.clear();
      }
    } catch (e) {
      debugPrint("Error adding cake: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error adding product to menu. Please try again later."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 48.0 : 16.0,
        vertical: 24.0,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MENU ITEM",
                  style: GoogleFonts.plusJakartaSans(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Add New Cake",
                  style: GoogleFonts.notoSerif(
                    color: _secondaryColor,
                    fontSize: widget.isDesktop ? 48 : 32,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 1,
          color: _secondaryColor.withOpacity(0.3),
        ),
        const SizedBox(height: 48),

        Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth > 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader("Pâtisserie Details"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: "Category",
                            hint: "e.g. Chocolate Based",
                            icon: Icons.category,
                            controller: _categoryController,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Category Subtitle",
                            hint: "e.g. Indulgent artisan chocolate",
                            icon: Icons.subtitles,
                            controller: _subtitleController,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _InputField(
                      label: "Category",
                      hint: "e.g. Chocolate Based",
                      icon: Icons.category,
                      controller: _categoryController,
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: "Category Subtitle",
                      hint: "e.g. Indulgent artisan chocolate",
                      icon: Icons.subtitles,
                      controller: _subtitleController,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _InputField(
                    label: "Item Name",
                    hint: "e.g. SONNA'S CLASSIC CHOCOLATE",
                    icon: Icons.cake,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 24),
                  if (isTwoCol)
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: "Item Flavors",
                            hint: "e.g. Chocolate cake",
                            icon: Icons.auto_awesome,
                            controller: _flavorsController,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Price",
                            hint: "e.g. 675/-",
                            icon: Icons.currency_rupee,
                            controller: _priceController,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _InputField(
                      label: "Item Flavors",
                      hint: "e.g. Chocolate cake",
                      icon: Icons.auto_awesome,
                      controller: _flavorsController,
                    ),
                    const SizedBox(height: 24),
                    _InputField(
                      label: "Price",
                      hint: "e.g. 675/-",
                      icon: Icons.currency_rupee,
                      controller: _priceController,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _InputField(
                    label: "Item Description",
                    hint: "e.g. Chocolate Whipped Ganache",
                    icon: Icons.description,
                    maxLines: 3,
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 48),
                  
                  const _SectionHeader("Portions & Servings"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: "Weight",
                            hint: "e.g. 600 grams",
                            icon: Icons.scale,
                            controller: _weightController,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Serves",
                            hint: "e.g. Serves 4-6",
                            icon: Icons.people,
                            controller: _servesController,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _InputField(
                      label: "Weight",
                      hint: "e.g. 600 grams",
                      icon: Icons.scale,
                      controller: _weightController,
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      label: "Serves",
                      hint: "e.g. Serves 4-6",
                      icon: Icons.people,
                      controller: _servesController,
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text(
                            "ADD PRODUCT TO MENU",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.notoSerif(
        color: _primaryColor,
        fontSize: 20,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextEditingController? controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "Required";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
               color: _secondaryColor.withOpacity(0.3),
            ),
            prefixIcon: maxLines == 1 ? Icon(icon, color: _primaryColor.withOpacity(0.6)) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _secondaryColor.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _secondaryColor.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
