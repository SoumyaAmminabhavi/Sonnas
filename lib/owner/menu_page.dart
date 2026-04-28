import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          color: _secondaryColor.withValues(alpha: 0.3),
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
                      children: const [
                        Expanded(
                          child: _InputField(
                            label: "Category",
                            hint: "e.g. Chocolate Based",
                            icon: Icons.category,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Category Subtitle",
                            hint: "e.g. Indulgent artisan chocolate",
                            icon: Icons.subtitles,
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    _InputField(
                      label: "Category",
                      hint: "e.g. Chocolate Based",
                      icon: Icons.category,
                    ),
                    SizedBox(height: 16),
                    _InputField(
                      label: "Category Subtitle",
                      hint: "e.g. Indulgent artisan chocolate",
                      icon: Icons.subtitles,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _InputField(
                    label: "Item Name",
                    hint: "e.g. SONNA'S CLASSIC CHOCOLATE",
                    icon: Icons.cake,
                  ),
                  const SizedBox(height: 24),
                  if (isTwoCol)
                    Row(
                      children: const [
                        Expanded(
                          child: _InputField(
                            label: "Item Flavors",
                            hint: "e.g. Chocolate cake",
                            icon: Icons.auto_awesome,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Price",
                            hint: "e.g. 675/-",
                            icon: Icons.currency_rupee,
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    _InputField(
                      label: "Item Flavors",
                      hint: "e.g. Chocolate cake",
                      icon: Icons.auto_awesome,
                    ),
                    SizedBox(height: 24),
                    _InputField(
                      label: "Price",
                      hint: "e.g. 675/-",
                      icon: Icons.currency_rupee,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _InputField(
                    label: "Item Description",
                    hint: "e.g. Chocolate Whipped Ganache",
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 48),
                  
                  const _SectionHeader("Portions & Servings"),
                  const SizedBox(height: 16),
                  if (isTwoCol)
                    Row(
                      children: const [
                        Expanded(
                          child: _InputField(
                            label: "Weight",
                            hint: "e.g. 600 grams",
                            icon: Icons.scale,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _InputField(
                            label: "Serves",
                            hint: "e.g. Serves 4-6",
                            icon: Icons.people,
                          ),
                        ),
                      ],
                    )
                  else ...const [
                    _InputField(
                      label: "Weight",
                      hint: "e.g. 600 grams",
                      icon: Icons.scale,
                    ),
                    SizedBox(height: 16),
                    _InputField(
                      label: "Serves",
                      hint: "e.g. Serves 4-6",
                      icon: Icons.people,
                    ),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Product added successfully!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
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

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
               color: _secondaryColor.withValues(alpha: 0.3),
            ),
            prefixIcon: maxLines == 1 ? Icon(icon, color: _primaryColor.withValues(alpha: 0.6)) : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _secondaryColor.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _secondaryColor.withValues(alpha: 0.1)),
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
