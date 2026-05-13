import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'owner/menu_page.dart';
import 'services/supabase_service.dart';
import 'widgets/landing_page.dart';
import 'widgets/modern_drawer.dart';
import 'widgets/glass_bottom_nav.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';


void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Pre-warm owner authentication (fetches PIN hash early for instant login)
    unawaited(AuthService.prewarmOwnerAuth());
    
    // Load saved theme
    final savedTheme = await ThemeService.getThemeMode();
    themeController.value = savedTheme;
    
    runApp(
      const ProviderScope(
        child: PatisserieApp(),
      ),
    );
  } catch (e) {
    debugPrint('Critical Initialization Error: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Initialization Error: $e')),
      ),
    ));
  }
}

// Global theme notifier
final themeController = ValueNotifier<ThemeMode>(ThemeMode.light);

class PatisserieApp extends ConsumerStatefulWidget {
  const PatisserieApp({super.key});

  @override
  ConsumerState<PatisserieApp> createState() => _PatisserieAppState();
}

class _PatisserieAppState extends ConsumerState<PatisserieApp> {
  late final VoidCallback _themeListener;

  @override
  void initState() {
    super.initState();
    _themeListener = () {
      if (mounted) setState(() {});
    };
    themeController.addListener(_themeListener);
  }

  @override
  void dispose() {
    themeController.removeListener(_themeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sonna\'s Patisserie & Cafe',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.value,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF4D8D),
          secondary: Color(0xFF701235),
          surface: Color(0xFFFFF0F6),
          onSurface: Color(0xFF701235),
          onSurfaceVariant: Color(0xFF964261),
          primaryContainer: Color(0xFFFFB6D3),
          onPrimaryContainer: Color(0xFF701235),
          surfaceContainer: Color(0xFFFFFFFF),
          surfaceContainerLow: Color(0xFFFFF5F9),
          outlineVariant: Color(0xFFFFB6D3),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF701235),
          contentTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        textTheme: _textTheme(const Color(0xFF701235)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4D8D),
          secondary: Color(0xFFFFB6D3),
          surface: Color(0xFF1A0F14),
          onSurface: Color(0xFFFFF0F6),
          onSurfaceVariant: Color(0xFFFFB6D3),
          primaryContainer: Color(0xFF701235),
          onPrimaryContainer: Color(0xFFFFB6D3),
          surfaceContainer: Color(0xFF2D1B22),
          surfaceContainerLow: Color(0xFF25161C),
          outlineVariant: Color(0xFF701235),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFF4D8D),
          contentTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        textTheme: _textTheme(const Color(0xFFFFF0F6)),
      ),
      home: const AppNavigation(),
    );
  }

  TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSerif(color: color, fontWeight: FontWeight.w400),
      headlineLarge: GoogleFonts.notoSerif(color: color, fontWeight: FontWeight.w400),
      bodyLarge: GoogleFonts.plusJakartaSans(color: color),
      labelSmall: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 2.0),
    );
  }
}

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      extendBody: true,
      drawer: const ModernDrawer(),
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: cs.primary),
        title: const Text(" "),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ) : AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: cs.primary),
        title: Text(
          _currentIndex == 1 ? "MENU" : _currentIndex == 2 ? "ORDERS" : "PROFILE",
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 2),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LandingPage(onViewMenu: () => _onTabSelected(1)),
          const MenuPage(),
          const Placeholder(), // Orders
          const Placeholder(), // Profile
        ],
      ),
      bottomNavigationBar: _currentIndex == 0 
          ? null 
          : GlassBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
            ),
    );
  }
}
