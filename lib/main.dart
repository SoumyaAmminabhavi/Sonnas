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
import 'services/cart_provider.dart';
import 'customer/checkout_page.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _initialThemeMode ?? ThemeMode.light;
  void setTheme(ThemeMode mode) => state = mode;
}


void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables from .env file (development only)
    // Production builds should use --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('⚠️ .env file not found — using --dart-define values for production build');
    }
    
    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Pre-warm owner authentication (fetches PIN hash early for instant login)
    AuthService.prewarmOwnerAuth().catchError((e) {
      debugPrint('⚠️ Prewarm Owner Auth failed: $e');
    });
    
    // Load saved theme
    try {
      final savedTheme = await ThemeService.getThemeMode();
      // Will be set via themeProvider after app starts
      _initialThemeMode = savedTheme;
    } catch (e) {
      debugPrint('Theme Loading Error: $e');
      _initialThemeMode = ThemeMode.system;
    }
    
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

ThemeMode _initialThemeMode = ThemeMode.light;

class PatisserieApp extends ConsumerStatefulWidget {
  const PatisserieApp({super.key});

  @override
  ConsumerState<PatisserieApp> createState() => _PatisserieAppState();
}

class _PatisserieAppState extends ConsumerState<PatisserieApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Sonna\'s Patisserie & Cafe',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
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

class AppNavigation extends ConsumerStatefulWidget {
  const AppNavigation({super.key});

  @override
  ConsumerState<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends ConsumerState<AppNavigation> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openCheckout() {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerCheckoutPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = ref.watch(cartProvider);
    
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: _openCheckout,
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      cart.itemCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
