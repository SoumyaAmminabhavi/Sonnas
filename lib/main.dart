import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customer/providers/cart_provider.dart';
import 'customer/main.dart';
import 'customer/screens/welcome_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load. Falling back to dart-define.");
  }

  final String supabaseUrl = dotenv.get('SUPABASE_URL', fallback: const String.fromEnvironment('SUPABASE_URL'));
  final String supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: const String.fromEnvironment('SUPABASE_ANON_KEY'));

  if (supabaseUrl.isEmpty || supabaseUrl == 'your_url_here') {
    debugPrint("CRITICAL ERROR: Supabase URL is missing. Authentication will fail with 404.");
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const PatisserieApp(),
    ),
  );
}

class PatisserieApp extends StatelessWidget {
  const PatisserieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sonna's Patisserie",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF4D8D), // Vibrant Pink
          secondary: Color(0xFF701235), // Deep Berry
          surface: Color(0xFFFFF0F6), // Pale Pink Background
          onSurface: Color(0xFF701235),
          onSurfaceVariant: Color(0xFF964261),
          primaryContainer: Color(0xFFFFB6D3), // Pastel Pink
          onPrimaryContainer: Color(0xFF701235),
          surfaceContainer: Color(0xFFFFFFFF), // Pure White for Cards
          surfaceContainerLow: Color(0xFFFFF5F9),
          outlineVariant: Color(0xFFFFB6D3),
        ),
        textTheme: _textTheme(const Color(0xFF701235)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4D8D), // Vibrant Pink
          secondary: Color(0xFFFFB6D3), // Pastel Pink
          surface: Color(0xFF1A0F14), // Deep Midnight Berry
          onSurface: Color(0xFFFFF0F6), // Pale Pink text
          onSurfaceVariant: Color(0xFFFFB6D3),
          primaryContainer: Color(0xFF701235), // Deep Berry
          onPrimaryContainer: Color(0xFFFFB6D3),
          surfaceContainer: Color(0xFF2D1B22), // Slightly lighter for cards
          surfaceContainerLow: Color(0xFF25161C),
          outlineVariant: Color(0xFF701235),
        ),
        textTheme: _textTheme(const Color(0xFFFFF0F6)),
      ),
      home: Supabase.instance.client.auth.currentSession != null 
          ? const CustomerMainScreen() 
          : const WelcomeScreen(),
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
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: color,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.bold,
        letterSpacing: 2.0,
      ),
    );
  }
}
