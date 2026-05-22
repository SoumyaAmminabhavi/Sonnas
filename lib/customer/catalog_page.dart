import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerCatalogPage extends StatelessWidget {
  const CustomerCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Catalogue",
          style: GoogleFonts.notoSerif(color: const Color(0xFFFF4D8D)),
        ),
      ),
      body: const Center(
        child: Text("Catalogue coming soon"),
      ),
    );
  }
}
