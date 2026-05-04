import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFFF4D8D);
    const Color background = Color(0xFFFFF0F6);
    const Color onSurface = Color(0xFF2B1606);
    const Color secondary = Color(0xFF701235);
    const Color primaryContainer = Color(0xFFFFB6D3);
    const Color surfaceContainerLow = Color(0xFFFFF1E9);
    const Color surfaceContainerHighest = Color(0xFFFFDCC5);

    return Scaffold(
      backgroundColor: background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "Contact Us",
          style: GoogleFonts.notoSerif(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: primary,
          ),
        ),
        actions: const [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Stack(
              children: [
                Container(
                  height: 400,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/storefront.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          background.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "THE SENSORY PATISSERIE",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Find Sonna's Patisserie",
                    style: GoogleFonts.notoSerif(
                      fontSize: 48,
                      color: onSurface,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Experience the art of French pastry in the heart of the city. Whether you're inquiring about an event or simply want to say hello, we'd love to hear from you.",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      height: 1.6,
                      color: secondary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Contact Form
                  Text(
                    "Send a Note",
                    style: GoogleFonts.notoSerif(
                      fontSize: 24,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildTextField("FULL NAME", primary, secondary),
                  const SizedBox(height: 40),
                  _buildTextField("EMAIL ADDRESS", primary, secondary),
                  const SizedBox(height: 40),
                  _buildTextField("YOUR MESSAGE", primary, secondary, maxLines: 4),
                  const SizedBox(height: 64),
                  
                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [primary, primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "SUBMIT INQUIRY",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),

                  // Details Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection("VISIT US", "75 Avenue des Champs-Élysées\nParis, 75008 France", primary, onSurface, secondary),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildDetailSection("HOURS", "Mon – Sun\n09:00 AM – 09:00 PM", primary, onSurface, secondary)),
                            Expanded(child: _buildDetailSection("CONTACT", "+91 98765 43210\nhello@sonnas.com", primary, onSurface, secondary)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Text(
                              "Get Directions",
                              style: GoogleFonts.notoSerif(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: primary,
                                decoration: TextDecoration.underline,
                                decorationColor: primaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18, color: primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),

                  // Map Placeholder
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuC2yJCd0hnVLIfdizhrhIzJA6MjRetv5nuLScyQDcbloZi6HhOkw3_TBJYXBDsjIiPtd_Pa_KeUBFJCauhNEyf-JWA1eSlFojcerLiAbHpbbpIejuTQscuX5ZjLEn3SaTczsA1ETSgHebYWGEkzr0xzGnl2TzTQ9qpXnZbCR6NRM7MVTkFI3BEO1d7QS7kzVieaIVFZDMPp1d46y4K5LY5HcheR1oY_ukehDD-aGmR03NPjO_6J3k33VAc-_J7b1saXmVLp83252HuE"),
                        fit: BoxFit.cover,
                        opacity: 0.8,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(Icons.location_on, size: 48, color: primary.withOpacity(0.3)),
                        ),
                        Positioned(
                          bottom: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  "SONNA'S PARIS",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),

                  // Footer Info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Bespoke Inquiries",
                          style: GoogleFonts.notoSerif(
                            fontSize: 32,
                            fontStyle: FontStyle.italic,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Planning a wedding or private event? Our pastry chefs craft custom menus that tell your unique story. Mention 'Sonna's Event' in your message.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.6,
                            color: secondary.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "PRIVATE CATERING DETAILS",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Color primary, Color secondary, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: secondary.withOpacity(0.4),
          ),
        ),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: secondary.withOpacity(0.1)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String label, String value, Color primary, Color onSurface, Color secondary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            height: 1.5,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}
