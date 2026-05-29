import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'customer/providers/cart_provider.dart' show CartProvider;
import 'customer/providers/favorites_provider.dart' show FavoritesProvider;
import 'customer/main.dart';
import 'customer/screens/welcome_screen.dart';

import 'owner/menu_page.dart';
import 'services/supabase_service.dart';
import 'widgets/landing_page.dart';
import 'widgets/modern_drawer.dart';
import 'widgets/glass_bottom_nav.dart';
import 'widgets/connectivity_banner.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/cart_provider.dart' as service_cart;
import 'customer/checkout_page.dart';

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _initialThemeMode;
  void setTheme(ThemeMode mode) => state = mode;
}

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
  };
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('❌ Unhandled Error: $error\n$stack');
    return true;
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('⚠️ .env file not found — using --dart-define values for production build');
    }
    
    await SupabaseService.initialize();
    
    unawaited(AuthService.prewarmOwnerAuth().catchError((Object e) {
      debugPrint('⚠️ Prewarm Owner Auth failed: $e');
    }));
    
    try {
      final savedTheme = await ThemeService.getThemeMode();
      _initialThemeMode = savedTheme;
    } catch (e) {
      debugPrint('Theme Loading Error: $e');
      _initialThemeMode = ThemeMode.light;
    }
    
    runApp(
      ProviderScope(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => FavoritesProvider()),
          ],
          child: const PatisserieApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Critical Initialization Error: $e\n$stackTrace');
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Initialization failed. Please restart the app.')),
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
      title: "Sonna's Patisserie & Cafe",
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      builder: (context, child) => ConnectivityBanner(child: child!),
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
      routes: {
        '/home': (context) => const CustomerMainScreen(),
        '/welcome': (context) => const WelcomeScreen(),
      },
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
    final cart = ref.read(service_cart.cartProvider);
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }
    Navigator.push<void>(context, MaterialPageRoute<void>(builder: (_) => const CustomerCheckoutPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cart = ref.watch(service_cart.cartProvider);
    
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: _currentIndex == 0,
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
          const Placeholder(), 
          const Placeholder(), 
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
