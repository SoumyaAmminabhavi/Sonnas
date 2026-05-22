import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'customer/main.dart';
import 'customer/providers/cart_provider.dart' as customer_cart;
import 'customer/providers/favorites_provider.dart' as customer_fav;

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _initialThemeMode;
  void setTheme(ThemeMode mode) => state = mode;
}

void main() async {
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
      _initialThemeMode = ThemeMode.system;
    }

    runApp(
      const ProviderScope(
        child: PatisserieApp(),
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
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => customer_cart.CartProvider()),
          ChangeNotifierProvider(create: (_) => customer_fav.FavoritesProvider()),
        ],
        child: const CustomerMainScreen(),
      ),
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
