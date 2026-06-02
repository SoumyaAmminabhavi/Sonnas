import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js_interop';

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
// import 'services/cart_provider.dart' as service_cart;
// import 'customer/checkout_page.dart';
import 'customer/screens/auth_callback_screen.dart';
import 'customer/screens/order_success_screen.dart';

@JS('getOrderConfirmedNumber')
external JSString getOrderConfirmedNumber();

@JS('getOrderConfirmedAmount')
external JSString getOrderConfirmedAmount();

@JS('clearOrderConfirmedNumber')
external void clearOrderConfirmedNumber();

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

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

    // Disable dynamic HTTP font fetching to ensure local assets are used
    GoogleFonts.config.allowRuntimeFetching = false;
    if (!kReleaseMode) {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint(
          '⚠️ .env file not found — using --dart-define values for production build',
        );
      }
    }

    await SupabaseService.initialize();

    unawaited(
      AuthService.prewarmOwnerAuth().catchError((Object e) {
        debugPrint('⚠️ Prewarm Owner Auth failed: $e');
      }),
    );

    try {
      final savedTheme = await ThemeService.getThemeMode();
      _initialThemeMode = savedTheme;
    } catch (e) {
      debugPrint('Theme Loading Error: $e');
      _initialThemeMode = ThemeMode.light;
    }

    runApp(const ProviderScope(child: PatisserieApp()));
  } catch (e, stackTrace) {
    debugPrint('Critical Initialization Error: $e\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Initialization failed:\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
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
      title: "Sonnas",
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        textTheme: _textTheme(const Color(0xFFFFF0F6)),
      ),
      routes: {
        '/home': (context) => const CustomerMainScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/auth-callback': (context) => const AuthCallbackScreen(),
      },
      home: const AppNavigation(),
    );
  }

  TextTheme _textTheme(Color color) {
    return TextTheme(
      displayLarge: GoogleFonts.notoSerif(
        color: color,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: GoogleFonts.notoSerif(
        color: color,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(color: color),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPaymentCallback();
    });
  }

  void _checkPaymentCallback() async {
    if (!kIsWeb) return;
    try {
      final jsOrderNumber = getOrderConfirmedNumber();
      final orderNumber = jsOrderNumber.toDart;
      if (orderNumber.isNotEmpty) {
        final jsAmount = getOrderConfirmedAmount();
        final amountStr = jsAmount.toDart;
        final amount = double.tryParse(amountStr) ?? 0.0;

        // Clear the global JS variable immediately so we don't pop this screen repeatedly
        clearOrderConfirmedNumber();

        if (mounted) {
          unawaited(Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderSuccessScreen(
                orderNumber: orderNumber,
                totalAmount: amount,
                status: 'CONFIRMED',
              ),
            ),
          ));
        }
      }
    } catch (e) {
      debugPrint("Error loading redirected order: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const NetworkImage(
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDByacWHy0qBkvb3ebrlLczBbsGfLJBx9g4Vj3Hf4Rf569lIXYKgH5nlnkTzU9zV4vEdhwPTtSpJbUM35KeRyEkvcU8cANByCauDlJo-EbylTpSvlTVI4mi8vLC2KjT5unMk_UwxMzUa_iRFQpAWBRVM-cIwySNaEJKYvDZAga_G0__V0h0mKmn7WZfPBUWETga8cpX86pb2zsU5fiMipshkb08cFRwG1zuIO7psicDnlPSrRJrC1Wva6_OgBNVKJ0I64vcZYWy7-KE',
      ),
      context,
    );
  }

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
      extendBodyBehindAppBar: _currentIndex == 0,
      drawer: const ModernDrawer(),
      appBar:
          _currentIndex == 0
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: IconThemeData(color: cs.primary),
                title: const Text(" "),
                actions: const [],
              )
              : AppBar(
                backgroundColor: cs.surface.withValues(alpha: 0.9),
                elevation: 0,
                scrolledUnderElevation: 0,
                iconTheme: IconThemeData(color: cs.primary),
                title: Text(
                  _currentIndex == 1
                      ? "MENU"
                      : _currentIndex == 2
                      ? "ORDERS"
                      : "PROFILE",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    letterSpacing: 2,
                  ),
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
      bottomNavigationBar:
          _currentIndex == 0
              ? null
              : GlassBottomNav(
                currentIndex: _currentIndex,
                onTap: _onTabSelected,
              ),
    );
  }
}
